--[[
-- STRUCTURE --
* whenever data is received from LTN events, data_processor() is called
* data_processor registers for on_tick and deals with a chunk of the available data on each tick
* the amount of data handled per tick is set in ltnt/const.lua
* any additional updates from LTN are ignored while this happens
  (I would expect data handling to be faster than LTN's once-per-second updates, but it might not be for a very large base)
* when processing is finished:
    - all data is pushed to the global.data table
    - data_processor() unregisters from on_tick
    - on_data_updated is raised to let the UI know that new data is available

-- GLOBAL OVERVIEW --
global.raw   >> contains data currently being processed, not ready for display yet
global.data  >> contains processed data and can be used by UI
global.proc  >> stores the current state of processing

--> UI should never access global.raw
--> global.data has to be complete at all times, otherwise UI accessing data will cause errors


--tables stored in global.raw: -----------------------------------------------------------------------------------

-- LTN DATA
.stops  >> table as received from on_stops_updated, modified during processing
  key = stop_id,     value = table with all available data for each non-error stop
  [stop_id] = {
    entity: LuaEntity,
    input: LuaEntity,
    output: LuaEntity,
    lampControl: LuaEntity,
    isDepot: bool,
    network_id: int,
    trainLimit: int,
    activeDeliveries: table,
    errorCode: int,
    parkedTrain: LuaTrain,
    parkedTrainID: int,
   -- up to here as received from LTN, following entries created during processing
    name: string,
    provided: table,
    requested: table,
    incoming: table,
    outgoing: table,
    signals: table,
  }
.dispatch >> table as received from on_dispatcher_updated

-- LOOKUP TABLES --
.name2id        >> key = stop_name,   value = stop_id (if multiple stops share a name: one of their IDs)
.item2stop      >> key = item,        value = table with stop IDs providing/requesting the item
.item2delivery  >> key = item,        value = table with delivery IDs currently transporting that item

-- DATA TABLES --
.depots         >> key = depot_name,  value = table with stopsdata for each depot stop
.provided       >> keys= network_id>item,  value = total amount provided of item in network_id
.deliveries     >> key = train_id,    value = table listing delviery data
.trains_error   >> key = train_id,    value = table with trains ins error state
.requested      >> same as above, but for requested items
.in_transit     >> key = item,        value = amount of item currently transported by trains

after processing finishes, all global.raw tables are moved to global.data, with the exception of global.raw.dispatch
------------------------------------------------------------------------------------------------------------------

-- additional tables in global.data --
.delivery_hist  >> lists finished deliveries, received from LTN's on_delivery_completed event
]]

-- local references to globals
local raw = {}
local proc = {
  state = "idle",
  underload_is_alert = util.get_setting(defs.settings.disable_underload),
  state_data = {
    update_depots = {},
    update_deliveries = {},
    update_stats = {
      last_update = 0
    },
  }
}
local data = {
  stops = {},
  depots = {},
  trains_error = {},
  train_error_count = 1,
  provided = {},
  requested = {},
  in_transit = {},
  deliveries = {},
  delivery_hist ={},
  newest_history_index = 1,
  name2id = {},
  item2stop = {},
  item2delivery = {},
  history_limit = util.get_setting(defs.settings.history_limit),
}

------------------------------------------------------------------------------------
-- processing LTN data
------------------------------------------------------------------------------------
local data_processor

-- on_dispatcher_updated is always triggered right after on_stops_updated
local function on_stops_updated(event)
  raw.stops = event.logistic_train_stops
end
local function on_dispatcher_updated(event)
  raw.deliveries = event.deliveries
  raw.available_trains =  event.available_trains
  raw.requests_by_stop = event.requests_by_stop
  raw.provided_by_stop = event.provided_by_stop
  data_processor()
end

local state_handlers = require(defs.pathes.modules.state_handlers)
function state_handlers.idle(raw)
    script.on_event(defines.events.on_tick, data_processor)
    -- suspend LTN interface during data processing
    script.on_event(defines.events.on_stops_updated, nil)
    script.on_event(defines.events.on_dispatcher_updated, nil)

    -- reset raw data
    raw.depots = {}
    raw.provided = {}
    raw.requested = {}
    raw.in_transit = {}
    raw.name2id = {}
    raw.item2stop = {}
    raw.item2delivery = {}
    -- reset state data
    proc.state_data.update_depots = {}
    proc.state_data.update_deliveries = {}
    return true
end
function state_handlers.finish(raw, state_data)
    -- update globals
    data.stops =  raw.stops
    data.depots = raw.depots
    data.provided =  raw.provided
    data.requested = raw.requested
    data.in_transit = raw.in_transit
    data.deliveries = raw.deliveries
    data.name2id =  raw.name2id
    data.item2stop =  raw.item2stop
    data.item2delivery = raw.item2delivery
    data.provided_by_stop = raw.provided_by_stop
    data.requested_by_stop = raw.requests_by_stop

    -- stop on_tick updates, start listening for LTN interface
    script.on_event(defines.events.on_stops_updated, on_stops_updated)
    script.on_event(defines.events.on_dispatcher_updated, on_dispatcher_updated)
    script.on_event(defines.events.on_tick, nil)
    script.raise_event(defines.events.on_data_updated, {})
    return true
end
local next_state = {
  idle = "update_stops",
  update_stops = "find_removed_stops",
  find_removed_stops = "update_depots",
  update_depots = "update_provided",
  update_provided = "update_requested",
  update_requested = "update_deliveries",
  update_deliveries = "update_stats",
  update_stats = "finish",
  finish = "idle",
}

function data_processor(event)
  log2(event, proc)
  local finished = state_handlers[proc.state](raw, proc.state_data[proc.state])
  if proc.state == "update_depots" then
  end
  if finished then
    proc.state = next_state[proc.state]
  end
end

------------------------------------------------------------------------------------
-- LTN event handlers
------------------------------------------------------------------------------------
local get_main_loco = util.train.get_main_locomotive
local ticks_to_timestring = util.misc.ticks_to_timestring
local function item_match(strg)
  return string.match(strg, "%w+,([%w_%-]+)")
end

local function store_history(history)
  if debug_mode then
    log2("New history record:\n", history)
  end
  history.finished = game.tick
  history.runtime = history.finished - history.started
  history.networkID = history.networkID and history.networkID > 2147483648 and history.networkID - 4294967296 or history.networkID -- convert from uint32 to int32
  data.delivery_hist[data.newest_history_index] = history
  data.newest_history_index = (data.newest_history_index % data.history_limit) + 1
end

local function raise_alert(delivery, train, alert_type, actual_cargo)
  local loco = get_main_loco(train)
  delivery.to_id = delivery.to_id or data.name2id[delivery.to] or 0
  delivery.from_id = delivery.from_id or data.name2id[delivery.from] or 0
  data.trains_error[data.train_error_count] = {
    type = alert_type,
    loco = loco,
    delivery = delivery,
    cargo = actual_cargo,
    time = ticks_to_timestring(),
  }
  if debug_mode then
    log2("Train error state detected:\n", data.trains_error[data.train_error_count])
  end
  script.raise_event(defines.events.on_train_alert, data.trains_error[data.train_error_count])
  data.train_error_count = data.train_error_count + 1
end

local function on_pickup_completed(event)
  -- compare train content to planned shipment
  local delivery = event.delivery
  local train = delivery.train
  local item_cargo = train.get_contents() -- does return empty table when train is empty, not nil
  local fluid_cargo = train.get_fluid_contents()
  local old_delivery = data.deliveries[train.id]
  local actual_cargo = {}
  if debug_mode then
    log2("Pickup complete event received.\nEvent data:\n", event, "\nItem cargo:", item_cargo, "\nFluid cargo:", fluid_cargo, "\nOld delivery:\n", old_delivery)
  end
  local keys = {}
  local alert = false
  if old_delivery and global.proc.underload_is_alert then
    for item, new_amount in pairs(delivery.shipment) do
      local old_amount = old_delivery.shipment[item]
      if new_amount < old_amount  then
        alert = true
      end
      actual_cargo[item] = new_amount
      keys[item_match(item) or ""] = true
    end
  else
    for item, new_amount in pairs(delivery.shipment) do
      keys[item_match(item) or ""] = true
    end
    actual_cargo = delivery.shipment
  end
  for item_name, amount in pairs(item_cargo) do
    if not keys[item_name] then
      actual_cargo["item,"..item_name] = amount
      alert = true
    end
  end
  for fluid_name, amount in pairs(fluid_cargo) do
    if not keys[fluid_name] then
      actual_cargo["fluid,"..fluid_name] = amount
      alert = true
    end
  end

  if alert then
    if old_delivery then
      old_delivery.depot = train.schedule and train.schedule.records[1] and train.schedule.records[1].station or "unknown"
      raise_alert(old_delivery, train, "incorrect_cargo", actual_cargo)
    else
      delivery.depot = train.schedule and train.schedule.records[1] and train.schedule.records[1].station or "unknown"
      raise_alert(delivery, train, "incorrect_cargo", actual_cargo)
    end
  end
end

local function on_delivery_completed(event)
  if debug_mode then
    log2("Delivery complete event received.\nEvent data:\n", event)
  end
  -- check train for residual content
  -- if a train has fluid and items, only item residue is logged
  local delivery = event.delivery
  local train = delivery.train
  delivery.depot = train.schedule and train.schedule.records[1] and train.schedule.records[1].station or "unknown"
  local res = train.get_contents() -- does return empty table when train is empty, not nil
  local fres = train.get_fluid_contents()
  local residuals_found, residuals = false, {}
  for name, amount in pairs(res) do
    residuals["item," .. name] = amount
    residuals_found = true
  end
  for name, amount in pairs(fres) do
    residuals["fluid," .. name] = amount
    residuals_found = true
  end
  if residuals_found then
    raise_alert(delivery, train, "residuals", residuals)
    delivery.residuals = residuals
  end
  store_history(delivery)
end

local function on_delivery_failed(event)
  if debug_mode then
    log2("Delivery failed event received.\nEvent data:\n", event)
  end
  local delivery = event.delivery
  local train = delivery.train
  if train.valid then
    -- train still valid -> delivery timed out
    delivery.timed_out = true
    delivery.depot = train.schedule and train.schedule.records[1] and train.schedule.records[1].station
    raise_alert(delivery, train,
        delivery.pickupDone and "timeout_post" or "timeout_pre"
    )
  else
    -- train became invalid during delivery
    raise_alert(delivery, train, "train_invalid")
  end
  store_history(delivery)
end

------------------------------------------------------------------------------------
-- initialization
------------------------------------------------------------------------------------
local function register_events()
  local get_ltn_event = function(event_name)
    return remote.call(defs.remote.ltn, defs.remote[event_name])
  end
  defines.events.on_stops_updated = get_ltn_event("ltn_stop_update")
  defines.events.on_dispatcher_updated = get_ltn_event("ltn_dispatcher_update")
  defines.events.on_delivery_completed = get_ltn_event("ltn_delivery_completed")
  defines.events.on_delivery_failed = get_ltn_event("ltn_delivery_failed")
  defines.events.on_pickup_completed = get_ltn_event("ltn_pickup_complete")

  script.on_event(defines.events.on_pickup_completed, on_pickup_completed)
  script.on_event(defines.events.on_delivery_completed, on_delivery_completed)
    script.on_event(defines.events.on_delivery_failed, on_delivery_failed)
  if proc.state == "idle" then
    script.on_event(defines.events.on_stops_updated, on_stops_updated)
    script.on_event(defines.events.on_dispatcher_updated, on_dispatcher_updated)
  else
    script.on_event(defines.events.on_tick, data_processor)
  end
end

local function on_settings_changed(event)
  local setting = event and event.setting
  if not(setting and setting:sub(1, 4) == defs.mod_prefix) then return end
  if setting == defs.settings.history_limit then
    data.history_limit = util.get_setting[setting]
    data.newest_history_index = 1
    data.delivery_hist = {}
  end
  if setting == defs.settings.disable_underload then
    proc.underload_is_alert = not util.get_setting(setting)
  end
end

local events = {
    [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
  }

local data_processing = {}

function data_processing.on_init()
  global.raw = raw
  global.data = data
  global.proc = proc
  register_events()
end

function data_processing.get_events()
  return events
end

function data_processing.on_load()
  raw = global.raw
  data = global.data
  proc = global.proc
  register_events()
end

function data_processing.on_configuration_changed(event)
  if event.mod_changes[defs.names.mod_name] and event.mod_changes[defs.names.mod_name].old_version then
    local old_version = util.format_version(event.mod_changes[defs.names.mod_name].old_version)
    if old_version <= "00.01.06" then
      global.proc.underload_is_alert = not util.get_setting(defs.settings.disable_underload)
    end
  end
end

return data_processing