--[[
-- STRUCTURE --
* whenever data is received from LTN events, data_processor() is called
* data_processor registers for on_tick and deals with a chunk of the available data on each tick
* the amount of data handled per tick is set in ltnc/const.lua
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
--local HISTORY_LIMIT = require("ltnc.const").proc.history_limit
local STOPS_PER_TICK = require("ltnc.const").proc.stops_per_tick
local DELIVERIES_PER_TICK = require("ltnc.const").proc.deliveries_per_tick
local TRAINS_PER_TICK = require("ltnc.const").proc.trains_per_tick
local ITEMS_PER_TICK = require("ltnc.const").proc.items_per_tick
local LTN_CONSTANTS = require("ltnc.const").ltn
local HISTORY_LIMIT = settings.global["ltnc-history-limit"].value
local FILENAME = "data.log"

local out = out -- <DEBUG>
---------------------
-- DATA PROCESSING --
---------------------
-- functions here are called from data_processor, defined below

local ctrl_signal_var_name = require("ltnc.const").ltn.ctrl_signal_var_name
local function get_control_signals(stop) -- helper function for state 1
  local color_signal = stop.lampControl.get_control_behavior().get_signal(1)
  local status = {
    name = color_signal and "virtual-signal/" .. color_signal.signal.name,
    count = color_signal and color_signal.count,
  }
  local signals = {}
  local i = 1
  for k,v in pairs(ctrl_signal_var_name) do
    local count = stop[v]
    if type(count) =="number" and count > 0 then
      signals[i] = {name = k, count = count}
      i = i+1
    elseif count == true then
      signals[i] = {name = k, count = 1}
      i = i+1
    end
  end
  return {status, signals}
end

local function update_stops(raw, stop_id) -- state 1
  local req_by_stop = raw.dispatch.Requests_by_Stop
  local stops = raw.stops
  local counter = 0
  while counter < STOPS_PER_TICK do -- process only a limited amount of stops per tick
    counter = counter + 1
    local stop
    stop_id, stop = next(stops, stop_id)
    if stop_id then
      -- list in name lookup table
      local name = stop.entity.backer_name
      raw.name2id[name] = stop_id
      if stop.errorCode ~= 0 or not stop.entity.valid then
        -- move to table with error stops
        stop.name = name
        stop.signals = {
          name = "virtual-signal/" .. LTN_CONSTANTS.error_color_lookup[stop.errorCode],
          count = 1,
        }
        raw.stops_error[stop_id] = stop
        --raw.stops[stop_id] = nil
      elseif stop.isDepot then
        if raw.depots[name] then
          -- add stop to depot
          table.insert(raw.depots[name].stops, stop)
        else
          --create new depot
          raw.depots[name] = {
            stops = {stop},
            parked_trains = {},
            all_trains = stop.entity.get_train_stop_trains(),
            n_parked = 0,
            n_all_trains = 0,
            cap = 0,
            fcap = 0,
            at = {},
          }
          -- counts as two stop updates, due to get_train_stop_trains call
          counter = counter + 1
        end
        --raw.stops[stop_id] = nil
      else
        -- add extra fields to normal stops
        stop.name = name
        stop.requested = req_by_stop[stop_id]
        stop.signals = get_control_signals(stop)
        stop.provided = {}
        stop.incoming = {}
        stop.outgoing = {}
      end -- if stop.errorCode ~= 0
    else
      return nil -- all stops done
    end --if stop_id then
  end
  return stop_id
end

local function prune_train_errors(raw)
  for train_id, error_data in pairs(data.trains_error) do
    if error_data.type == "generic" then
      data.trains_error[train_id] = nil
    end
  end
end

local get_main_loco = require("ltnc.util").get_main_loco
local is_train_error_state = require("ltnc.const").is_train_error_state
local function update_depots(raw, depot_name, train_index) -- state 3
  local av_trains = raw.dispatch.availableTrains
  local counter = 0
  while counter < TRAINS_PER_TICK do
    local next_depot_name, depot = next(raw.depots, depot_name)
    if depot then
      while counter < TRAINS_PER_TICK do
        counter = counter + 1
        local train
        train_index, train = next(depot.all_trains, train_index) -- train_index ~= train_id
        if train then
          if train.valid then
            depot.n_all_trains = depot.n_all_trains + 1
            local train_id = train.id
            if is_train_error_state[train.state] then
              local loco = get_main_loco(train)
              data.trains_error[train_id] = {
                type = "generic",
                loco = loco,
                route = {next_depot_name},
                state = train.state,
              }
            elseif av_trains[train_id] then
              depot.parked_trains[train_id] = av_trains[train_id]
              depot.n_parked = depot.n_parked + 1
              depot.cap = depot.cap + av_trains[train_id].capacity
              depot.fcap = depot.fcap + av_trains[train_id].fluid_capacity
            end
          end
        else
          depot_name = next_depot_name
          train_index = nil -- this should hopefully fix the elusive "next" error
          break
        end -- if train
      end  -- inner while
    else
      return nil
    end -- if depot
  end -- outer while
  return depot_name, train_index
end

local function update_provided(raw, item) -- state 4
  -- sort provided items by network id
  local i2s = raw.item2stop
  local provided = raw.dispatch.Provided
  local counter = 0
  while counter < ITEMS_PER_TICK do
    local stops
    item, stops = next(provided, item)
    if stops then
      for stop_id, count in pairs(stops) do
        local stop = raw.stops[stop_id]
        if stop then
          -- store provided amount for individual stops
          stop.provided[item] = (stop.provided[item] or 0) + count
          -- list stop as provider for item
          i2s[item] = i2s[item] or {}
          i2s[item][#i2s[item]+1] = stop_id
          local networkID = stop.network_id
          if networkID then
            -- store provided amount for each network id and item
            raw.provided[networkID] = raw.provided[networkID] or {}
            raw.provided[networkID][item] = (raw.provided[networkID][item] or 0) + count
          end
        end
        counter = counter + 1
      end
    else
      return nil
    end
  end
  return item
end

local function update_requested(raw, rq_idx) -- state 5
    -- sort requested items by network id
  local i2s = raw.item2stop
  local requests= raw.dispatch.Requests
  local counter = 0
  while counter < ITEMS_PER_TICK do
    local request
    rq_idx, request = next(requests, rq_idx)
    if request then
      if raw.stops[request.stopID] then
        local item = request.item
        -- list stop as requester for item
        i2s[item] = i2s[item] or {}
        i2s[item][#i2s[item]+1] = request.stopID
        local networkID = raw.stops[request.stopID].network_id
        if networkID then
          -- store requested amount for each network id and item
          raw.requested[networkID] = raw.requested[networkID] or {}
          raw.requested[networkID][item] = (raw.requested[networkID][item] or 0) - request.count
        end
        counter = counter + 2
      end
    else
      return nil
    end
  end
  return rq_idx
end

local function update_in_transit(delivery_id, delivery, raw) -- helper function for state 7
  if raw.stops[delivery.to_id] and raw.stops[delivery.from_id] then
    local inc = raw.stops[delivery.to_id] and raw.stops[delivery.to_id].incoming or {}
    -- only add to outgoing if pickup is not done yet
    local og = not delivery.pickup_done and raw.stops[delivery.from_id] and raw.stops[delivery.from_id].outgoing
    for item, amount in pairs(delivery.shipment) do
      raw.in_transit[item] = (raw.in_transit[item] or 0) + amount
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
  if debug_level >= 2 then
    out.info("data_processor", "Processing data on tick:", game.tick, "\nCurrent processor state:", proc)
    --[[if debug_level > 2 then
      out.info("data_processor", "Raw data follows:\n", global.raw)
    end  --]]
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

    -- reset state
    -- could be condensed down to just one variable, but it's more readable this way
    proc.next_stop_id = nil
    proc.next_train_id = nil
    proc.next_delivery_id = nil
    proc.next_item = nil
    proc.next_req = nil
    proc.next_depot_name = nil

    proc.state = 1 -- set next state
    if debug_level >= 3 then
      out.info("data_processor", "Raw data follows:\n", global.raw)
    end

  -- processing functions for each state can take multiple ticks to complete
  -- if those functions return a value, they will be called again next tick, with that value as input
  -- the returned value should allow the function to continue from where it stopped
  -- they must return nil when their job is done, in which case proc.state is incremented

  ---- state 6 currently unused ------
  elseif proc.state == 1 then
  -- processing stops first, information gathered here is required for other steps
    local stop_id = update_stops(raw, proc.next_stop_id)
    if stop_id then
      proc.next_stop_id = stop_id -- store last processed id, so we know where to continue next tick
    else
      proc.state = 2 -- go to next state
    end

  elseif proc.state == 2 then
    -- check trains on error list and remove if needed
    prune_train_errors(raw)
    proc.state = 3

  elseif proc.state == 3 then
    -- sorting available trains by depot
    local depot_name, train_id = update_depots(raw, proc.next_depot_name, proc.next_train_id)
    if depot_name then
      proc.next_depot_name = depot_name
      proc.next_train_id = train_id
    else
      proc.state = 4
    end

  elseif proc.state == 4 then
    -- sorting provided items by network id and stop
    local next_item = update_provided(raw, proc.next_item)
    if next_item then
      proc.next_item = next_item
    else
      proc.state = 5
    end

  elseif proc.state == 5 then
    -- sorting requested items by network id and stop
    local next_req = update_requested(raw, proc.next_req)
    if next_req then
      proc.next_req = next_req
    else
      proc.state = 7
    end

  elseif proc.state == 7 then
    -- add new deliveries and update items in transit
    local next_delivery_id = add_new_deliveries(raw, proc.next_delivery_id)
    if next_delivery_id then
      proc.next_delivery_id = next_delivery_id
    else
    proc.state = 100
    end

  elseif proc.state == 100 then -- update finished
    -- update globals and raise event
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
    --script.raise_event(events.on_data_updated, {}) -- currently unused, UI only updates on user interaction

    -- stop on_tick updates, start listening for LTN interface
    script.on_event(events.on_stops_updated_event, on_stops_updated)
    script.on_event(events.on_dispatcher_updated_event, on_dispatcher_updated)
    script.on_event(defines.events.on_tick, nil)

    proc.state = 0
    if debug_level >= 3 then
      out.info("data_processor", "Processed data follows:\n", global.data)
    end
  end
end


local delivery_timeout = settings.global["ltn-dispatcher-delivery-timeout"].value
local function history_tracker(event)
  local history = event.data
  local train = history.train
  if debug_level >= 2 then
    out.info("delivery_tracker", "data received:", history, history.train)
  end
  if train.valid then -- probably not necessary, train should be valid on the tick the event is received
    history.runtime = game.tick - history.started
    history.timed_out = history.runtime >= delivery_timeout
    history.depot = train.schedule.records[1] and train.schedule.records[1].station

    if history.timed_out then
      local loco = get_main_loco(train)
      data.trains_error[train.id] = {
        type = "timeout",
        loco = loco,
        route = {history.depot, history.from, history.to},
        depot = history.depot,
        state = -101
      }
      script.raise_event(events.on_train_alert, data.trains_error[train.id])
    else
      -- check train for residual content
      -- if a train has fluid and items, only item residue is logged
      local res = train.get_contents() -- does return empty table when train is empty, not nil
      local fres = train.get_fluid_contents()
      if next(res) or next(fres) then
        if next(res) then
          history.residuals = {"item", res}
        else
          history.residuals = {"fluid", fres}
        end
        local loco = get_main_loco(train)
        data.trains_error[train.id] = {
          type = "residuals",
          loco = loco,
          route = {history.depot, history.from, history.to},
          depot = history.depot,
          cargo = history.residuals,
          state = -100
        }
        script.raise_event(events.on_train_alert, data.trains_error[train.id])
      end
    end
  else
    out.error("Tell eduran he did it wrong! Here is some info for him, so he can do better next time:\n history:", history)
  end

  -- insert history into circular array
  data.delivery_hist[data.newest_history_index] = history
  data.newest_history_index = (data.newest_history_index % HISTORY_LIMIT) + 1
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
  events.on_delivery_complete_event = remote.call("logistic-train-network", "get_on_delivery_complete_event")

  -- register for conditional events
  if global.proc.state == 0 then
    script.on_event(events.on_stops_updated_event, on_stops_updated)
    script.on_event(events.on_dispatcher_updated_event, on_dispatcher_updated)
  else
    script.on_event(defines.events.on_tick, data_processor)
  end
  script.on_event(events.on_delivery_complete_event, history_tracker)
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


  on_load(event_id)
end

local function on_settings_changed(event)
  if event.setting == "ltnc-history-limit" then
    HISTORY_LIMIT = settings.global["ltnc-history-limit"].value
    global.data.history_limit = HISTORY_LIMIT
    global.data.newest_history_index = 1
    global.data.delivery_hist = {}
  end
  delivery_timeout = settings.global["ltn-dispatcher-delivery-timeout"].value
end

return {
  on_init = on_init,
  on_load = on_load,
  on_settings_changed = on_settings_changed,
}
