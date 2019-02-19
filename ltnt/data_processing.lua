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
.stops_error    >> key = stop_id,     value = stopdata, as for stops
.depots         >> key = depot_name,  value = table with stopsdata for each depot stop
.provided       >> keys= network_id>item,  value = total amount provided of item in network_id
.deliveries     >> key = train_id,    value = table listing delviery data
.trains_error   >> key = train_id,    value = table with trains ins error state
.requested      >> same as above, but for requested items
.in_transit     >> key = item,        value = amount of item currently transported by trains

after processing finishes, all global.raw tables are moved to global.data, with the exception of global.raw.dispatch
------------------------------------------------------------------------------------------------------------------

-- additional tables in global.data --
.delivery_hist  >> lsits finished deliveries, received from LTN's on_delivery_completed event

--]]

-- local references to globals, set during on_load
local raw
local data
local events -- custom event ids

-- constants
--local HISTORY_LIMIT = require("ltnt.const").proc.history_limit
local STOPS_PER_TICK = require("ltnt.const").proc.stops_per_tick
local DELIVERIES_PER_TICK = require("ltnt.const").proc.deliveries_per_tick
local TRAINS_PER_TICK = require("ltnt.const").proc.trains_per_tick
local ITEMS_PER_TICK = require("ltnt.const").proc.items_per_tick
local LTN_CONSTANTS = require("ltnt.const").ltn
local HISTORY_LIMIT = settings.global["ltnt-history-limit"].value
local FILENAME = "data.log"

local out = out
---------------------
-- DATA PROCESSING --
---------------------
-- functions here are called from data_processor, defined below

local ctrl_signal_var_name_bool = require("ltnt.const").ltn.ctrl_signal_var_name_bool
local ctrl_signal_var_name_num = require("ltnt.const").ltn.ctrl_signal_var_name_num
local function get_lamp_color(stop) -- helper functions for state 1
  --local color_signal = stop.lampControl.get_control_behavior().get_signal(1)
  --return color_signal and color_signal.signal.name
  return stop.lampControl.get_control_behavior().get_signal(1).signal.name
end
local function get_control_signals(stop)
  local color_signal = stop.lampControl.get_control_behavior().get_signal(1)
  --local status = color_signal and {color_signal.signal.name,  color_signal.count}
  local signals = {}
  for sig_name,v in pairs(ctrl_signal_var_name_bool) do
     signals[sig_name] = stop[v] and 1 or nil
  end
  for sig_name,v in pairs(ctrl_signal_var_name_num) do
     signals[sig_name] = stop[v] > 0 and stop[v] or nil
  end
  return {{color_signal.signal.name,  color_signal.count}, signals}
end

local function update_stops(raw, stop_id) -- state 1
  local stops = raw.stops
  --local counter = 0
  --while counter < STOPS_PER_TICK do -- process only a limited amount of stops per tick
    --counter = counter + 1
    --local stop
  for stop_id, stop in pairs(stops) do
    --stop_id, stop = next(stops, stop_id)
    --if stop then
      if stop.entity.valid then
        -- list in name lookup table
        local name = stop.entity.backer_name
        if stop.isDepot then
          if raw.depots[name] then
            local depot = raw.depots[name]
            -- add stop to depot
            depot.network_ids[#depot.network_ids+1] = stop.network_id
            depot.signals[get_lamp_color(stop)] = (depot.signals[get_lamp_color(stop)] or 0) + 1
          else
            --create new depot
            raw.depots[name] = {
              parked_trains = {},
              signals = {[get_lamp_color(stop)] = 1},
              network_ids = {stop.network_id},
              all_trains = stop.entity.get_train_stop_trains(),
              n_parked = 0,
              n_all_trains = 0,
              cap = 0,
              fcap = 0,
            }
          end
        end
        raw.name2id[name] = stop_id
        if stop.errorCode ~= 0 then
          -- add to table with error stops
          stop.name = name
          stop.signals = {[LTN_CONSTANTS.error_color_lookup[stop.errorCode]] = 1}
          raw.stops_error[stop_id] = stop
        elseif not stop.isDepot then
          -- add extra fields to normal stops
          stop.name = name
          stop.signals = get_control_signals(stop)
          stop.incoming = {}
          stop.outgoing = {}
          raw.stop_ids[#raw.stop_ids+1] = stop_id
        end -- if stop.errorCode ~= 0
      end   -- if stop.valid
   -- else
    --  return nil -- all stops done
    --end --if stop_id then
  end
  return nil --stop_id
end

local function update_depots(raw, depot_name) -- state 3
  local av_trains = raw.dispatch.availableTrains
  local counter = 0
  while counter < TRAINS_PER_TICK do -- for depot_name, depot in pairs(raw.depots) do
    local depot
    depot_name, depot = next(raw.depots, depot_name)
    if depot then
      --while counter < TRAINS_PER_TICK do
      for train_index, train in pairs(depot.all_trains) do
        if train.valid then
          depot.n_all_trains = depot.n_all_trains + 1
          local train_id = train.id
          if av_trains[train_id] then
            depot.parked_trains[train_id] = av_trains[train_id]
            depot.n_parked = depot.n_parked + 1
            depot.cap = depot.cap + av_trains[train_id].capacity
            depot.fcap = depot.fcap + av_trains[train_id].fluid_capacity
          end
        end
      end  -- inner while
    else
      return nil
    end -- if depot
    counter = counter + depot.n_all_trains
  end -- outer while
  return depot_name
end

local function update_provided(raw) -- state 4
  -- sort provided items by network id
  local i2s = raw.item2stop
  for item, stops in pairs(raw.dispatch.Provided) do
    for stop_id, count in pairs(stops) do
      local stop = raw.stops[stop_id]
      if stop then
        -- list stop as provider for item
        i2s[item] = i2s[item] or {}
        i2s[item][#i2s[item]+1] = stop_id
        local networkID = stop.network_id
        -- store provided amount for each network id and item
        raw.provided[networkID] = raw.provided[networkID] or {}
        raw.provided[networkID][item] = (raw.provided[networkID][item] or 0) + count
      end
    end
  end
  return nil
end

local function update_requested(raw) -- state 5
    -- sort requested items by network id
  local i2s = raw.item2stop
  local requests= raw.dispatch.Requests
  for rq_idx, request in pairs(requests) do
    if raw.stops[request.stopID] then
      local item = request.item
      -- list stop as requester for item
      i2s[item] = i2s[item] or {}
      i2s[item][#i2s[item]+1] = request.stopID
      local networkID = raw.stops[request.stopID].network_id
      -- store requested amount for each network id and item
      raw.requested[networkID] = raw.requested[networkID] or {}
      raw.requested[networkID][item] = (raw.requested[networkID][item] or 0) - request.count
    end
  end
  return nil
end

local function update_in_transit(delivery_id, delivery, raw) -- helper function for state 7
  if raw.stops[delivery.to_id] and raw.stops[delivery.from_id] then
    local network_id = delivery.networkID or -1
    raw.in_transit[network_id] = raw.in_transit[network_id] or {}
    local inc = raw.stops[delivery.to_id] and raw.stops[delivery.to_id].incoming or {}
    -- only add to outgoing if pickup is not done yet
    local og = not delivery.pickup_done and raw.stops[delivery.from_id] and raw.stops[delivery.from_id].outgoing
    for item, amount in pairs(delivery.shipment) do
      raw.in_transit[network_id][item] = (raw.in_transit[network_id][item] or 0) + amount
      raw.item2delivery[item] = raw.item2delivery[item] or {}
      raw.item2delivery[item][#raw.item2delivery[item]+1] = delivery_id
      inc[item] = (inc[item] or 0) + amount
      if og then og[item] = (og[item] or 0) - amount end
    end
  end
end

local function add_new_deliveries(raw, delivery_id) -- state 7
  local counter = 0
  while counter < DELIVERIES_PER_TICK do
    counter = counter + 1
    local delivery
    delivery_id, delivery = next(raw.dispatch.Deliveries, delivery_id)
    if delivery then
      delivery.from_id = raw.name2id[delivery.from]
      delivery.to_id = raw.name2id[delivery.to]
      delivery.depot = delivery.train.valid and delivery.train.schedule.records[1] and delivery.train.schedule.records[1].station
      -- add items to in_transit list and incoming/outgoing
      update_in_transit(delivery_id, delivery, raw)
    else
      return nil
    end
  end
  return delivery_id
end

--------------------
-- EVENT HANDLERS --
--------------------
local data_processor -- defined later

-- on_dispatcher_updated is always triggered right after on_stops_updated
local function on_stops_updated(event)
  raw.stops = event.data
end
local function on_dispatcher_updated(event)
  raw.dispatch = event.data
  data_processor()
end

-- data_processor starts running on_tick when new data arrives and stops when processing is finished
data_processor = function(event)
  local proc = global.proc
  --log(proc.state)
  if debug_level >= 2 then
    out.info("data_processor", "Processing data on tick:", game.tick, "\nCurrent processor state:", proc)
  end
  if proc.state == 0 then -- new data arrived, init processing
    script.on_event(defines.events.on_tick, data_processor)
    -- suspend LTN interface during data processing
    script.on_event(events.on_stops_updated_event, nil)
    script.on_event(events.on_dispatcher_updated_event, nil)

    -- reset raw data
    raw.depots = {}
    raw.stops_error = {}
    raw.provided = {}
    raw.requested = {}
    raw.in_transit = {}
    raw.name2id = {}
    raw.item2stop = {}
    raw.item2delivery = {}
    raw.stop_ids = {}


    -- reset state
    -- could be condensed down to just one variable, but it's more readable this way
    proc.next_stop_id = nil
    --proc.next_train_id = nil
    proc.next_delivery_id = nil
    --proc.next_item = nil
    --proc.next_req = nil
    proc.next_depot_name = nil

    proc.state = 1 -- set next state

    --[[if debug_level >= 3 then
      out.info("data_processor", "Raw data follows:\n", global.raw)
    end --]]

  -- processing functions for each state can take multiple ticks to complete
  -- if those functions return a value, they will be called again next tick, with that value as input
  -- the returned value should allow the function to continue from where it stopped
  -- they must return nil when their job is done, in which case proc.state is incremented

  ---- state 3 and 6 currently unused ------
  elseif proc.state == 1 then
  -- processing stops first, information gathered here is required for other steps
    local stop_id = update_stops(raw, proc.next_stop_id)
    if stop_id then
      proc.next_stop_id = stop_id -- store last processed id, so we know where to continue next tick
    else
      proc.state = 3 -- go to next state
    end

  elseif proc.state == 3 then
    -- sorting available trains by depot
    local depot_name = update_depots(raw, proc.next_depot_name)
    if depot_name then
      proc.next_depot_name = depot_name
    else
      proc.state = 4
    end

  elseif proc.state == 4 then
    -- sorting provided items by network id and stop
    update_provided(raw)
    proc.state = 5

  elseif proc.state == 5 then
    -- sorting requested items by network id and stop
    update_requested(raw)
    proc.state = 7

  elseif proc.state == 7 then
    -- add new deliveries and update items in transit
    local next_delivery_id = add_new_deliveries(raw, proc.next_delivery_id)
    if next_delivery_id then
      proc.next_delivery_id = next_delivery_id
    else
      proc.state = 100
    end

  elseif proc.state == 8 then
    sort_stops_by_name(raw)
    proc.state = 9

  elseif proc.state == 9 then
    sort_stops_by_state(raw)
    proc.state = 100

  elseif proc.state == 100 then -- update finished
    -- update globals
    data.stops =  raw.stops
    data.depots = raw.depots
    data.stops_error =  raw.stops_error
    data.provided =  raw.provided
    data.requested = raw.requested
    data.in_transit = raw.in_transit
    data.deliveries = raw.dispatch.Deliveries
    data.name2id =  raw.name2id
    data.item2stop =  raw.item2stop
    data.item2delivery = raw.item2delivery
    data.provided_by_stop = raw.dispatch.Provided_by_Stop
    data.requested_by_stop = raw.dispatch.Requests_by_Stop
    data.stop_ids = raw.stop_ids

    -- stop on_tick updates, start listening for LTN interface
    script.on_event(events.on_stops_updated_event, on_stops_updated)
    script.on_event(events.on_dispatcher_updated_event, on_dispatcher_updated)
    script.on_event(defines.events.on_tick, nil)
    script.raise_event(events.on_data_updated, {})

    proc.state = 0
    --if debug_level >= 3 then
    --  out.info("data_processor", "Processed data follows:\n", global.data)
    --end
  end
end

-- history tracking
--local delivery_timeout = settings.global["ltn-dispatcher-delivery-timeout"].value
local get_main_loco = require("ltnt.util").get_main_loco

local function store_history(history)
  history.runtime = game.tick - history.started
  data.delivery_hist[data.newest_history_index] = history
  data.newest_history_index = (data.newest_history_index % HISTORY_LIMIT) + 1
end

local function on_delivery_completed(event_data)
  -- check train for residual content
  -- if a train has fluid and items, only item residue is logged
  local delivery = event_data.delivery
  local train = delivery.train
  delivery.depot = train.schedule.records[1] and train.schedule.records[1].station
  local res = train.get_contents() -- does return empty table when train is empty, not nil
  local fres = train.get_fluid_contents()
  if next(res) or next(fres) then
    if next(res) then
      delivery.residuals = {"item", res}
    else
      delivery.residuals = {"fluid", fres}
    end
    local loco = get_main_loco(train)
    data.trains_error[train.id] = {
      type = "residuals",
      loco = loco,
      route = {delivery.depot, delivery.from, delivery.to},
      cargo = delivery.residuals,
    }
    script.raise_event(events.on_train_alert, data.trains_error[train.id])
  end
  store_history(delivery)
end
local function on_delivery_failed(event_data)
  local delivery = event_data.delivery
  local train = delivery.train
  if train.valid then
    -- train still valid -> delivery timed out
    delivery.timed_out = true
    delivery.depot = train.schedule.records[1] and train.schedule.records[1].station
    local loco = get_main_loco(train)
    data.trains_error[train.id] = {
      type = "timeout",
      loco = loco,
      route = {delivery.depot, delivery.from, delivery.to},
    }
    script.raise_event(events.on_train_alert, data.trains_error[train.id])
  else
    -- train became invalid during delivery
    data.trains_error[event_data.trainID] = {
      type = "train_invalid",
      loco = nil,
      route = {"", delivery.from, delivery.to},
    }
    script.raise_event(events.on_train_alert, data.trains_error[train.id])
  end
  store_history(delivery)
end

----------------------
-- PUBLIC FUNCTIONS --
----------------------
local function on_load(custom_events)
  -- cache globals
  raw = global.raw
  data = global.data

  -- cache event IDs
  events = custom_events
  events.on_stops_updated_event = remote.call("logistic-train-network", "get_on_stops_updated_event")
  events.on_dispatcher_updated_event = remote.call("logistic-train-network", "get_on_dispatcher_updated_event")
  events.on_delivery_completed_event = remote.call("logistic-train-network", "get_on_delivery_completed_event")
  events.on_delivery_failed_event = remote.call("logistic-train-network", "get_on_delivery_failed_event")

  -- register for conditional events
  if global.proc.state == 0 then
    script.on_event(events.on_stops_updated_event, on_stops_updated)
    script.on_event(events.on_dispatcher_updated_event, on_dispatcher_updated)
  else
    script.on_event(defines.events.on_tick, data_processor)
  end
  script.on_event(events.on_delivery_completed_event, on_delivery_completed)
  script.on_event(events.on_delivery_failed_event, on_delivery_failed)
  if debug_level >= 1 then
    out.info("data_processing.lua", "data processor status after on_load:", global.proc)
  end
end

local function on_init(event_id)
  global.raw = global.raw or {}
  global.proc = global.proc or {state = 0}

  global.data = global.data or {} -- storage for processed data, ready to be used by UI
  global.data.stops = global.data.stops or {}
  global.data.depots = global.data.depots or {}
  global.data.stops_error = global.data.stops_error or {}
  global.data.trains_error = global.data.trains_error or {}
  global.data.provided = global.data.provided or {}
  global.data.requested = global.data.requested or {}
  global.data.in_transit = global.data.in_transit or {}
  global.data.deliveries = global.data.deliveries or {}
  global.data.delivery_hist = global.data.delivery_hist or {}
  global.data.newest_history_index = 1
  global.data.name2id = global.data.name2id or {}
  global.data.item2stop = global.data.item2stop or {}
  global.data.item2delivery = global.data.item2delivery or {}
  global.data.history_limit = HISTORY_LIMIT
  global.data.stop_ids = global.data.stop_ids or {}
  on_load(event_id)
end

local function on_settings_changed(event)
  if event.setting == "ltnt-history-limit" then
    HISTORY_LIMIT = settings.global["ltnt-history-limit"].value
    global.data.history_limit = HISTORY_LIMIT
    global.data.newest_history_index = 1
    global.data.delivery_hist = {}
  end
end

return {
  on_init = on_init,
  on_load = on_load,
  on_settings_changed = on_settings_changed,
}
