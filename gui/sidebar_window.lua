local defs = defs
local egm = egm
local C = C

local mod_gui = require("mod-gui")
local build_item_table = util.gui.build_item_table
local format = string.format
local format_number = util.format_number

local gui_data = {
  windows = {},
  currently_opened = {},
  elements = {},
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
  local window = {
    root = frame_flow.add{
      type = "frame",
      direction = "vertical",
      name = defs.names.sidebar
    },
    train = {},
    station = {},
  }
  window.root.style.width = C.sidebar.width
  window.root.style.maximal_height = 600
  window.root.style.use_header_filler = false
  window.root.visible = false
  window.root.style.left_padding = 2
  window.root.style.right_padding = 2

  -- prepare train gui elements
  local flow = window.root.add(C.elements.flow_vertical_container)
  flow.visible = false
  window.train.flow = flow
  flow.add{
    type = "label",
    style = "heading_2_label",
    caption = {"sidebar.assigned_depot"},
  }
  flow.add{
    type = "label",
    style = "bold_label",
    caption = "",
  }
  local inner_flow = flow.add(C.elements.flow_vertical_container)
  inner_flow.visible = false
  window.train.delivery_flow = inner_flow
  inner_flow.add{
    type = "label",
    style = "heading_2_label",
    caption = {"sidebar.current_delivery"},
  }
  local label_flow = inner_flow.add(C.elements.flow_horizontal_container)
  label_flow.style.vertical_align = "center"
  window.train.from_label = label_flow.add{
    type = "label",
    caption = "",
    style = defs.styles.inventory_tab.del_col_1,
  }
  window.train.from_label.style.width = C.sidebar.label_width
  label_flow.add{
    type = "label",
    caption = " >> ",
    style = defs.styles.inventory_tab.del_col_2,
  }.style.width = C.sidebar.mini_width
  window.train.to_label = label_flow.add{
    type = "label",
    caption = "",
    style = defs.styles.inventory_tab.del_col_3,
  }
  window.train.to_label.style.width = C.sidebar.label_width
  inner_flow.add{type = "flow"}  --placeholder

  flow.add{
    type = "label",
    style = "heading_2_label",
    caption = {"sidebar.assign_to_depot"},
  }
  window.train.button_pane = flow.add(C.elements.no_frame_scroll_pane)
  window.train.button_pane.visible = false

  -- prepare station gui elements
  window.station = window.root.add(C.elements.flow_vertical_container)
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
  window.train.flow.visible = false
  window.root.visible = true
  flow.clear()

  window.root.caption = "Station information"
  local icon_flow = flow.add{type = "flow", direction = "horizontal"}

  icon_flow.add{
    type = "sprite-button",
    sprite = defs.signals.network_id,
    number = stop_data.network_id,
    enabled = false,
    style = defs.styles.shared.gray_button,
  }.style.width = 36
  -- third column: status
  icon_flow.add{
    type = "sprite-button",
    sprite = "virtual-signal/"..stop_data.signals[1][1],
    number = stop_data.signals[1][2],
    enabled = false,
    style = defs.styles.shared.gray_button,
    }.style.width = 50

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
  table_params.requested = stop_data.outgoing
  flow.add(label_params)
  build_item_table(table_params)

  label_params.caption = defs.locale.control_signals
  table_params.provided = nil
  table_params.requested = nil
  table_params.signals = stop_data.signals[2]
  flow.add(label_params)
  build_item_table(table_params)
end

local function show_depot_information(pind, depot_name, depot_data)
  local window = get(pind)
  local flow = window.station
  flow.visible = true
  window.train.flow.visible = false
  window.root.visible = true
  flow.clear()

  window.root.caption = {"sidebar.depot_caption", depot_name}
  local subflow = flow.add{type = "flow"}

  local label_params = {
    type = "label",
    style = defs.styles.depot_tab.cap_left_1,
    caption = defs.locale.n_trains
  }
  subflow.add(label_params).style.font_color = {r = 1, g = 1, b = 1}

  label_params.style = defs.styles.depot_tab.cap_left_2
  label_params.caption = depot_data.n_parked .. "/" .. depot_data.n_all_trains
  subflow.add(label_params)

  subflow = flow.add{type = "flow"}
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
  if not train.valid then return end

  local window = get(pind)
  local subwindow = window.train
  local flow = subwindow.flow
  window.root.caption = "Train information"
  flow.visible = true
  window.station.visible = false
  window.root.visible = true

  local delivery_data = global.data.deliveries[train.id]
  local record = train.schedule and train.schedule.records[1]  -- LTN always assigns depot as first record
  local depot_name = record and record.station
  if global.data.depots[depot_name] then
    flow.children[1].caption = {"sidebar.assigned_depot"}
    flow.children[1].style.font_color = C.colors.heading_default
    flow.children[2].caption = depot_name
  else
    flow.children[1].caption = {"sidebar.no_depot"}
    flow.children[1].style.font_color = C.colors.red
    flow.children[2].caption = ""
  end

  if delivery_data then
    subwindow.delivery_flow.visible = true
    subwindow.button_pane.visible = false
    subwindow.from_label.caption = delivery_data.from
    egm.manager.register(
      subwindow.from_label, {
        action = defs.actions.station_name_clicked,
        name = delivery_data.from,
      }
    )
    subwindow.to_label.caption = delivery_data.to
    egm.manager.register(
      subwindow.to_label, {
        action = defs.actions.station_name_clicked,
        name = delivery_data.to,
      }
    )
    subwindow.delivery_flow.children[3].destroy()
    build_item_table{
      parent = subwindow.delivery_flow,
      provided = delivery_data.shipment,
      columns = 6,
    }
  else
    subwindow.delivery_flow.visible = false
    local pane = subwindow.button_pane
    pane.visible = true
    pane.clear()
    local build_depot_button = util.gui.build_depot_button
    for depot_name, depot_data in pairs(global.data.depots) do
      egm.manager.register(
        build_depot_button(pane, depot_name, depot_data, 269), {
          action = defs.actions.send_to_depot,
          train = train,
          depot_name = depot_name,
        }
      )
    end
  end
end

------------------------------------------------------------------------------------
-- event handlers
------------------------------------------------------------------------------------
local function on_gui_opened(event)
  local pind = event.player_index
  if event.gui_type == defines.gui_type.entity and event.entity.valid then
    if event.entity.type == "locomotive" then
      show_train_information(pind, event.entity.train)
      gui_data.currently_opened[pind] = {type = "train", train = event.entity.train}
    elseif event.entity.name == "logistic-train-stop" then
      local stop_id = event.entity.unit_number
      local stop_data = global.data.stops[stop_id]
      local name = event.entity.backer_name
      if stop_data then
        show_station_information(pind, stop_id, stop_data)
        gui_data.currently_opened[pind] = {type = "stop", stop_id = stop_id}
      elseif global.data.depots[name] then  -- is depot
        show_depot_information(pind, name, global.data.depots[name])
        gui_data.currently_opened[pind] = {type = "depot", depot_name = name}
      end
    end
  end
end

local function on_gui_closed(event)
  local pind = event.player_index
  get(pind).root.visible = false
  gui_data.currently_opened[pind] = nil
end

local function on_data_updated(event)
  for pind, data in pairs(gui_data.currently_opened) do
    if data.type == "train" then
      show_train_information(pind, data.train)
      return
    elseif data.type == "stop" and global.data.stops[data.stop_id] then
      show_station_information(pind, data.stop_id, global.data.stops[data.stop_id])
      return
    elseif global.data.depots[data.depot_name] then
      show_depot_information(pind, data.depot_name, global.data.depots[data.depot_name])
      return
    end
    on_gui_closed({player_index = pind})
  end
end

------------------------------------------------------------------------------------
-- gui action definitions
------------------------------------------------------------------------------------
egm.manager.define_action(defs.actions.send_to_depot,--[[
  Triggering elements:
    depot_button @ sidebar
  Event: on_gui_click
  Data:
    depot_name :: string
    train :: LuaTrain
]]function(event, data)
    local train = data.train
    if train and train.valid then
      train.schedule = {
        current = 1,
        records = { [1] = {
          station = data.depot_name,
          wait_conditions = { [1] = {
            type = "time",
            compare_type = "and",
            ticks  = 300,
          }},
        }},
      }
      train.go_to_station(1)
      show_train_information(event.player_index, train)
    end
  end
)

------------------------------------------------------------------------------------
-- initialization and configuration
------------------------------------------------------------------------------------
local function player_init(event)--[[
Initializes global table for given player and builds sidebar GUI.

Parameters
  player_index :: uint
]]
  local pind = event.player_index
  local player = game.players[pind]
  if debug_mode then log2("Building sidebar UI for player", player.name) end
  -- set UI state globals
  build(pind)
end

local events = {
    [defines.events.on_gui_opened] = on_gui_opened,
    [defines.events.on_gui_closed] = on_gui_closed,
    [defines.events.on_player_created] = player_init,
    [defines.events.on_data_updated] = on_data_updated,
  }

local gui_sidebar = {}

function gui_sidebar.on_init()
  global.gui_sidebar = global.gui_sidebar or gui_data
  for pind in pairs(game.players) do
    player_init({player_index = pind})
  end
end

function gui_sidebar.on_load()
  gui_data = global.gui_sidebar
end

function gui_sidebar.get_events()
  return events
end

return gui_sidebar