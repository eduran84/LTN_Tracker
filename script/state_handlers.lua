local pairs, next = pairs, next

local state_handlers = {}

local ctrl_signal_var_name_bool = C.ltn.ctrl_signal_var_name_bool
local ctrl_signal_var_name_num = C.ltn.ctrl_signal_var_name_num
local function get_control_signals(stop)
  local color_signal = stop.lampControl.get_control_behavior().get_signal(1)
  local signals = {}
  for sig_name,v in pairs(ctrl_signal_var_name_bool) do
     signals[sig_name] = stop[v] and 1 or nil
  end
  for sig_name,v in pairs(ctrl_signal_var_name_num) do
     signals[sig_name] = stop[v] > 0 and stop[v] or nil
  end
  return {{color_signal.signal.name,  color_signal.count}, signals}
end
function state_handlers.update_stops(raw)
  for stop_id, stop in pairs(raw.stops) do
    if stop.entity.valid and stop.lampControl.valid then
      local name = stop.entity.backer_name
      if stop.isDepot then
        local lamp_color = stop.lampControl.get_control_behavior().get_signal(1).signal.name
        if raw.depots[name] then
          local depot = raw.depots[name]
          -- add stop to depot
          depot.network_ids[#depot.network_ids+1] = stop.network_id
          depot.signals[lamp_color] = (depot.signals[lamp_color] or 0) + 1
        else
          --create new depot
          raw.depots[name] = {
            parked_trains = {},
            signals = {[lamp_color] = 1},
            network_ids = {stop.network_id},
            all_trains = stop.entity.get_train_stop_trains(),
            n_parked = 0,
            n_all_trains = 0,
            cap = 0,
            fcap = 0,
          }
        end
        raw.stops[stop_id] = nil
      else  -- non-depot stop
        raw.name2id[name] = stop_id  -- list in name lookup table
        stop.name = name
        stop.signals = get_control_signals(stop)
        stop.incoming = {}
        stop.outgoing = {}
      end
    end
  end
  return true
end

function state_handlers.find_removed_stops(raw)--[[
  checks if stops were removed
  ]]
  for stop_id in pairs(global.data.stops) do
    if not raw.stops[stop_id] then
      gui.clear_station_filter()
      break
    end
  end
  return true
end

local trains_per_tick = C.proc.trains_per_tick
function state_handlers.update_depots(raw, state_data)
  local av_trains = raw.available_trains
  local depot_name = state_data.depot_name
  local counter = 0
  while counter < trains_per_tick do -- for depot_name, depot in pairs(raw.depots) do
    local depot
    depot_name, depot = next(raw.depots, depot_name)
    if depot then
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
      end
    else
      return true
    end -- if depot
    counter = counter + depot.n_all_trains
  end -- outer while
  state_data.depot_name = depot_name
  return false
end

function state_handlers.update_provided(raw)
  -- sort provided items by network id
  local i2s = raw.item2stop
  local tick = game.tick
  local archive = global.archive
  for stop_id, provided in pairs(raw.provided_by_stop) do
    local stop = raw.stops[stop_id]
    if stop then
      for item, count in pairs(provided) do
        -- list stop as provider for item
        i2s[item] = i2s[item] or {}
        i2s[item][#i2s[item]+1] = stop_id
        local networkID = stop.network_id
        -- store provided amount for each network id and item
        raw.provided[networkID] = raw.provided[networkID] or {}
        raw.provided[networkID][item] = (raw.provided[networkID][item] or 0) + count
        if archive[item] then
          archive[item][tick] = (archive[item][tick] or 0) + count
        end
      end
    end
  end
  return true
end

function state_handlers.update_requested(raw)
    -- sort requested items by network id
  local i2s = raw.item2stop
  local archive = global.archive
  local tick = game.tick - 1
  for stop_id, request in pairs(raw.requests_by_stop) do
    if raw.stops[stop_id] then
      local networkID = raw.stops[stop_id].network_id
      for item, count in pairs(request) do
        -- list stop as requester for item
        i2s[item] = i2s[item] or {}
        i2s[item][#i2s[item]+1] = stop_id
        -- store requested amount for each network id and item
        raw.requested[networkID] = raw.requested[networkID] or {}
        raw.requested[networkID][item] = (raw.requested[networkID][item] or 0) - count
        if archive[item] then
          archive[item][tick] = (archive[item][tick] or 0) - count
        end
      end
    end
  end
  return true
end

local function update_in_transit(delivery_id, delivery, raw)
  if raw.stops[delivery.to_id] and raw.stops[delivery.from_id] then
    local network_id = delivery.networkID or -1
    raw.in_transit[network_id] = raw.in_transit[network_id] or {}
    local inc = raw.stops[delivery.to_id] and raw.stops[delivery.to_id].incoming or {}
    -- only add to outgoing if pickup is not done yet
    local og = not delivery.pickupDone and raw.stops[delivery.from_id] and raw.stops[delivery.from_id].outgoing
    for item, amount in pairs(delivery.shipment) do
      raw.in_transit[network_id][item] = (raw.in_transit[network_id][item] or 0) + amount
      raw.item2delivery[item] = raw.item2delivery[item] or {}
      raw.item2delivery[item][#raw.item2delivery[item]+1] = delivery_id
      inc[item] = (inc[item] or 0) + amount
      if og then og[item] = (og[item] or 0) - amount end
    end
  end
end
local deliveries_per_tick = C.proc.deliveries_per_tick
function state_handlers.update_deliveries(raw, state_data)
  local delivery_id = state_data.delivery_id
  local counter = 0
  while counter < deliveries_per_tick do
    counter = counter + 1
    local delivery
    delivery_id, delivery = next(raw.deliveries, delivery_id)
    if delivery then
      delivery.from_id = raw.name2id[delivery.from]
      delivery.to_id = raw.name2id[delivery.to]
      -- add items to in_transit list and incoming/outgoing
      update_in_transit(delivery_id, delivery, raw)
    else
      return true
    end
  end
  state_data.delivery_id = delivery_id
  return false
end

return state_handlers