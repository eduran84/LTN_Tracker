local defs = defs
local tab_names = defs.names.tabs
local egm = egm
local C = C
local gui_data = {windows = {}}
gui = {}

require(defs.pathes.modules.action_definitions)
local mod_gui = require("mod-gui")

local build_funcs, update_funcs = {}, {}
build_funcs[tab_names.station], update_funcs[tab_names.station] = unpack(require(defs.pathes.modules.station_tab))
build_funcs[tab_names.history], update_funcs[tab_names.history] = unpack(require(defs.pathes.modules.history_tab))
build_funcs[tab_names.alert], update_funcs[tab_names.alert] = unpack(require(defs.pathes.modules.alert_tab))

local function build(pind)
  local player = game.players[pind]
  local frame_flow = mod_gui.get_frame_flow(player)
  local window_height = settings.get_player_settings(game.players[pind])[defs.names.settings.window_height].value
  local window = egm.window.build(frame_flow, {
    caption = {"ltnt.mod-name"},
    height = window_height,
    width = C.window.width,
    direction = "vertical",
  })
  window.root.visible = false
  egm.window.add_button(window, {
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = defs.names.sprites.refresh,
    tooltip = {"ltnt.refresh-bt"},
  },
  {action = defs.names.actions.refresh_button})

  local pane = egm.tabs.build(window.content, {direction = "vertical"})
  window.pane = pane
  egm.tabs.add_tab(pane, 1, {caption = {"ltnt.tab1-caption"}})
  egm.tabs.add_tab(pane, 3, {caption = {"ltnt.tab3-caption"}})

  window.tabs = {}
  window.tabs[tab_names.station] = build_funcs[tab_names.station](window)
  window.tabs[tab_names.history] =  build_funcs[tab_names.history](window)
  window.tabs[tab_names.alert] =  build_funcs[tab_names.alert](window)
  gui_data.windows[pind] = window
  return window
end

local function get(pind)
  local window = gui_data.windows[pind]
  if window then
    if window.content and window.content.valid then
      return window
    else
      egm.window.destroy(window)
      egm.manager.delete_player_data(pind)
    end
  end
  return build(pind)
end

local events = {}



gui.build = build
gui.get = get

function gui.update_tab(event, tab_index)
  local pind = event.player_index
  local window = get(pind)
  tab_index = tab_index or window.root.visible and window.pane.active_tab
  log2("update tab:", event, tab_index, update_funcs)
  if update_funcs[tab_index] then
    update_funcs[tab_index](window.tabs[tab_index], global.data)
  end
end

function gui.on_init()
  global.gui_data = global.gui_data or gui_data
  egm.manager.on_init()
end

function gui.on_load()
  gui_data = global.gui_data
  egm.manager.on_load()
end

function gui.get_events()
  return events
end

function gui.on_configuration_changed(data)
end

script.on_event({
    defines.events.on_tab_changed,
    defines.events.on_textbox_valid_value_changed,
  },
  gui.update_tab
)

egm.manager.define_action(defs.names.actions.refresh_button, gui.update_tab)

script.on_event({
    defines.events.on_gui_click,
    defines.events.on_gui_text_changed,
  },
  egm.manager.on_gui_input
)

return gui