local defs = defs
local egm = egm
local C = C
local gui_data = {windows = {}}

require(defs.pathes.modules.action_definitions)

local mod_gui = require("mod-gui")
local build_station_tab = require(defs.pathes.modules.station_tab)
local build_history_tab = require(defs.pathes.modules.history_tab)
local build_alert_tab = require(defs.pathes.modules.alert_tab)

local function build_gui(pind)
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
  window.tabs[defs.names.tabs.stations] = build_station_tab(window, defs.names.tabs.stations)
  window.tabs[defs.names.tabs.history] = build_history_tab(window, defs.names.tabs.history)
  window.tabs[defs.names.tabs.alert] = build_alert_tab(window, defs.names.tabs.alert)
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
  return build_gui(pind)
end

local events = {}
local gui = {
  build = build_gui,
  get = get,
}

local selection_tool = {}

function gui.on_init()
  global.gui_data = global.gui_data or gui_data
  egm.manager.on_init()
end

function gui.on_load()
  gui_data = global.gui_data
end

function gui.get_events()
  return events
end

function gui.on_configuration_changed(data)
end

return gui