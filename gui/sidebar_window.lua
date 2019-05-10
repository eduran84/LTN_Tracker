local defs = defs
local egm = egm
local C = C

local mod_gui = require("mod-gui")
local build_item_table = util.build_item_table
local format = string.format
local format_number = util.format_number

local gui_data = {
  windows = {},
}
------------------------------------------------------------------------------------
-- sidebar functions
------------------------------------------------------------------------------------
local function build(pind)--[[ --> custom egm_window
Creates the sidebar GUI for the given player.

Parameters:
  player_index :: uint
Return value
  the sidebar window
]]
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])

  local preexisting_window = frame_flow[defs.names.sidebar]
  if preexisting_window and preexisting_window.valid then
    egm.manager.unregister(preexisting_window)
    preexisting_window.destroy()
  end
  local window = {}
  window.root = frame_flow.add{
    type = "frame",
    direction = "vertical",
    name = defs.names.sidebar
  }
  window.root.style.width = C.sidebar.width
  window.root.style.use_header_filler = false
  window.root.visible = false

  window.train = window.root.add{
    type = "flow",
    style = defs.styles.vertical_container,
    direction = "vertical"
  }
  window.train.visible = false

  window.station = window.root.add{
    type = "flow",
    style = defs.styles.vertical_container,
    direction = "vertical"
  }
  window.station.visible = false

  gui_data.windows[pind] = window
  return window
end

local function get(pind)--[[  --> custom egm_window
Returns the sidebar GUI for the given player if it exists. Creates it otherwise.

Parameters
  player_index :: uint
Return value
  the sidebar window
]]
  local window = gui_data.windows[pind]
  if window and window.root and window.root.valid then
    return window
  else
    return build(pind)
  end
end

local function show_station_information(pind, stop_id, stop_data)
  local window = get(pind)
  local flow = window.station
  flow.visible = true
  window.train.visible = false
  window.root.visible = true
  flow.clear()

  window.root.caption = "Station information"
  local label_params = {
    type = "label",
    style = "heading_2_label",
    caption = stop_data.name
  }
  local table_params = {
    parent = flow,
    provided = global.data.provided_by_stop[stop_id],
    requested = global.data.requested_by_stop[stop_id],
    columns = 6,
    enabled = false,
    max_rows = 3,
  }
  label_params.caption = defs.locale.provided_requested
  flow.add(label_params)
  build_item_table(table_params)

  label_params.caption = defs.locale.scheduled_deliveries
  table_params.provided = stop_data.incoming
  table_params.provided = stop_data.outgoing
  flow.add(label_params)
  build_item_table(table_params)

  label_params.caption = defs.locale.control_signals
  table_params.provided = nil
  table_params.provided = nil
  table_params.signals = stop_data.signals[2]
  flow.add(label_params)
  build_item_table(table_params)
end

local function show_depot_information(pind, stop_id, depot_data)
  local window = get(pind)
  local flow = window.station
  flow.visible = true
  window.train.visible = false
  window.root.visible = true
  flow.clear()

  window.root.caption = "Depot information"
  local subflow = flow.add{type = "flow"}

  local label_params = {
    type = "label",
    style = defs.styles.depot_tab.cap_left_1,
    caption = defs.locale.n_trains
  }
  subflow.add(label_params)

  label_params.style = defs.styles.depot_tab.cap_left_2
  label_params.caption = depot_data.n_parked .. "/" .. depot_data.n_all_trains
  subflow.add(label_params)

  label_params.style = defs.styles.depot_tab.cap_left_1
  label_params.caption = defs.locale.capacity
  subflow.add(label_params)

  label_params.style = defs.styles.depot_tab.cap_left_2
  label_params.caption = format("%s stacks + %s fluid", format_number(depot_data.cap),  format_number(depot_data.fcap))
  local label = subflow.add(label_params)
  label.style.width = C.depot_tab.col_width_left[5]

  subflow = flow.add{type = "flow"}
  build_item_table{
    parent = subflow,
    columns = 4,
    signals = depot_data.signals,
    enabled = false,
  }
  local elem = subflow.add{type = "frame", style = defs.styles.shared.slot_table_frame}
  elem.style.maximal_height = 44
  elem = elem.add{type = "table", column_count = 4, style = "slot_table"}
  local hash = {}
  local id_sprite = "virtual-signal/" .. C.ltn.NETWORKID
  for _, id in pairs(depot_data.network_ids) do
    if not hash[id] then
      elem.add{
        type = "sprite-button",
        sprite = id_sprite,
        number = id,
        enabled = false,
        style = defs.styles.shared.gray_button,
      }
      hash[id] = true
    end
  end

end


local function show_train_information(pind, train)
  local window = get(pind)
  local flow = window.train
  window.root.caption = "Train information"
  flow.visible = true
  window.station.visible = false
  window.root.visible = true
  flow.clear()

  local train_id = train.id
  local delivery_data = global.data.deliveries[train_id]
  local record = train.schedule.records[1]  -- LTN always assigns depot as first record
  local depot_name = record and record.station
  depot_name = global.data.depots[depot_name] and "Assigned to depot: " .. depot_name or "Not assigned to LTN depot"

  local label_params = {
    type = "label",
    --style = defs.styles.depot_tab.cap_left_1,
    caption = depot_name
  }
  flow.add(label_params)

  if delivery_data then
    -- display current delivery
    label_params.caption = "on delivery"
    flow.add(label_params)
  end

  local subflow = flow.add{type = "flow"}


end

------------------------------------------------------------------------------------
-- event handlers
------------------------------------------------------------------------------------
local function on_gui_opened(event)
  local player = game.players[event.player_index]
  if event.gui_type == defines.gui_type.entity and event.entity.valid then
    if event.entity.type == "locomotive" then
      show_train_information(event.player_index, event.entity.train)
    elseif event.entity.name == "logistic-train-stop" then
      local stop_id = event.entity.unit_number
      local stop_data = global.data.stops[stop_id]
      local name = event.entity.backer_name
      if stop_data then
        show_station_information(event.player_index, stop_id, stop_data)
      elseif global.data.depots[name] then --is depot?
        show_depot_information(event.player_index, stop_id, global.data.depots[name])
      end
    end
  end
end

local function on_gui_closed(event)
  get(event.player_index).root.visible = false
end


------------------------------------------------------------------------------------
-- initialization and configuration
------------------------------------------------------------------------------------
local function player_init(pind)--[[
Initializes global table for given player and builds sidebar GUI.

Parameters
  player_index :: uint
]]
  local player = game.players[pind]
  if debug_mode then log2("Building sidebar UI for player", player.name) end
  -- set UI state globals
  build(pind)
end

local events = {
    [defines.events.on_gui_opened] = on_gui_opened,
    [defines.events.on_gui_closed] = on_gui_closed,
    [defines.events.on_player_created] = player_init,
  }

local gui_sidebar = {}

function gui_sidebar.on_init()
  global.gui_sidebar = global.gui_sidebar or gui_data
  for pind in pairs(game.players) do
    player_init(pind)
  end
end

function gui_sidebar.on_load()
  gui_data = global.gui_sidebar
end

function gui_sidebar.get_events()
  return events
end

return gui_sidebar