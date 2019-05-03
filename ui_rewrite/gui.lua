local defs = defs
local tab_names = defs.names.tabs
local egm = egm
local C = C
local gui_data = {
  windows = {},
  is_ltnc_active = false,
  is_ltnc_open = {},
  station_select_mode = {},
  last_refresh_tick = {},
  refresh_interval = {},
}
gui = {}

require(defs.pathes.modules.action_definitions)
local mod_gui = require("mod-gui")

local build_funcs, update_funcs = {}, {}
build_funcs[tab_names.depot], update_funcs[tab_names.depot] = unpack(require(defs.pathes.modules.depot_tab))
build_funcs[tab_names.station], update_funcs[tab_names.station] = unpack(require(defs.pathes.modules.station_tab))
build_funcs[tab_names.history], update_funcs[tab_names.history] = unpack(require(defs.pathes.modules.history_tab))
build_funcs[tab_names.alert], update_funcs[tab_names.alert] = unpack(require(defs.pathes.modules.alert_tab))

local function build(pind)
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])
  local preexisting_window = frame_flow[defs.names.window]
  if preexisting_window and preexisting_window.valid then
    preexisting_window.destroy()
  end
  egm.manager.delete_player_data(pind)

  local window_height = settings.get_player_settings(game.players[pind])[defs.names.settings.window_height].value
  local window = egm.window.build(frame_flow, {
    name = defs.names.window,
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

  window.tabs = {}
  window.tabs[tab_names.depot] = build_funcs[tab_names.depot](window)
  window.tabs[tab_names.station] = build_funcs[tab_names.station](window)

  egm.tabs.add_tab(pane, 3, {caption = {"ltnt.tab3-caption"}})

  window.tabs[tab_names.history] =  build_funcs[tab_names.history](window)
  window.tabs[tab_names.alert] =  build_funcs[tab_names.alert](window)
  gui_data.windows[pind] = window
  return window
end

local function get(pind)
  local window = gui_data.windows[pind]
  if window and window.content and window.content.valid then
    return window
  else
    return build(pind)
  end
end

local function update_tab(event)
  local pind = event.player_index
  local window = get(pind)
  local tab_index = window.root.visible and window.pane.active_tab
  log2("update tab:", event, tab_index)
  if update_funcs[tab_index] then
    update_funcs[tab_index](window.tabs[tab_index], global.data)
    gui_data.last_refresh_tick[pind] = game.tick
  end
end

script.on_event({
    defines.events.on_tab_changed,
    defines.events.on_textbox_valid_value_changed,
  },
  update_tab
)

egm.manager.define_action(defs.names.actions.refresh_button, update_tab)

script.on_event({
    defines.events.on_gui_click,
    defines.events.on_gui_text_changed,
  },
  egm.manager.on_gui_input
)

script.on_event(
  defines.events.on_gui_closed,
  function(event)
    -- event triggers whenever any UI element is closed, so check if it is actually the ltnt UI that is supposed to close
    local pind = event.player_index
    local window = get(pind)
    if event.element and event.element.valid and event.element.index == window.root.index then
      if gui_data.is_ltnc_active and gui_data.is_ltnc_open[pind] then
        gui_data.is_ltnc_open[pind] = nil
        remote.call("ltn-combinator", "close_ltn_combinator", pind)
        game.players[pind].opened = window.root
        update_tab(event)
      else
        egm.window.hide(window)
      end
    end
  end
)

local function on_toggle_button_click(event)
  local pind = event.player_index
  local new_state = egm.window.toggle(get(pind))
  if new_state then
    game.players[pind].opened = get(pind).root
    game.players[pind].set_shortcut_toggled("ltnt-toggle-shortcut", true)
    gui.update_tab(event)
  else
    game.players[pind].set_shortcut_toggled("ltnt-toggle-shortcut", false)
  end
end

script.on_event("ltnt-toggle-hotkey", on_toggle_button_click)
script.on_event(
  defines.events.on_lua_shortcut,
  function(event)
    if event.prototype_name == "ltnt-toggle-shortcut" then
      on_toggle_button_click(event)
    end
  end
)

script.on_event(
  defines.events.on_data_updated,
  function(event)
    local tick = game.tick
    --local interval = gui_data.refresh_interval
    for pind, interval in pairs(gui_data.refresh_interval) do
      if tick - gui_data.last_refresh_tick[pind] > interval  then
        gui_data.last_refresh_tick[pind] = tick
        update_tab({player_index = pind})
      end
    end
  end
)

local function player_init(pind)
  local player = game.players[pind]
  if debug_mode then
    log2("Building UI for player", player.name)
  end
  -- set UI state globals
  gui_data.last_refresh_tick[pind] = 0
  local refresh_interval = settings.get_player_settings(player)[defs.names.settings.refresh_interval].value
  if refresh_interval > 0 then
    gui_data.refresh_interval[pind] = refresh_interval * 60
  else
    gui_data.refresh_interval[pind] = nil
  end
  gui_data.station_select_mode[pind] = tonumber(settings.get_player_settings(player)[defs.names.settings.station_click_action].value)
  -- build UI
  if not settings.get_player_settings(player)["ltnt-show-button"].value then
    --GC.toggle_button:hide(pind)
  end
  build(pind)
end
script.on_event(defines.events.on_player_created, player_init)

gui.build = build
gui.get = get
gui.update_tab = update_tab
gui.player_init = player_init
function gui.on_init()
  global.gui_data = global.gui_data or gui_data
  egm.manager.on_init()
  gui_data.is_ltnc_active = game.active_mods[defs.names.ltnc] and true or false
  for pind in pairs(game.players) do
    player_init(pind)
  end
end
function gui.on_load()
  gui_data = global.gui_data
  egm.manager.on_load()
end
function gui.on_settings_changed(event)
  local pind = event.player_index
  local player = game.players[pind]
  local player_settings = settings.get_player_settings(player)
  local setting = event.setting
  if setting == defs.names.settings.window_height then
    build(pind)
  elseif setting == "ltnt-show-button" then
    -- show or hide toggle button
    if player_settings[setting].value then
      GC.toggle_button:show(pind)
    else
      GC.toggle_button:hide(pind)
    end
  elseif setting == defs.names.settings.refresh_interval then
      local refresh_interval = player_settings[setting].value
    if refresh_interval > 0 then
      gui_data.refresh_interval[pind] = refresh_interval * 60
    else
      gui_data.refresh_interval[pind] = nil
    end
  elseif setting == defs.names.settings.station_click_action then
    gui_data.station_select_mode[pind] = tonumber(player_settings[setting].value)
  end

end
function gui.on_configuration_changed(data)
  -- handle changes to LTN-Combinator
  local reset = false
  if data.mod_changes[defs.names.ltnc] then
    local was_active = gui_data.is_ltnc_active
    local is_active = game.active_mods[defs.names.ltnc] and true or false
    if is_active ~= was_active then
      gui_data.is_ltnc_active = is_active
      reset = true
    end
  end
  -- handles changes to LTNT
  if data.mod_changes[defs.names.mod_name] and data.mod_changes[defs.names.mod_name].old_version then
    reset = true
  end
  if reset then
    for pind in pairs(game.players) do
      build(pind)
    end
  end
end

function gui.clear_station_filter()
  -- hacky way to force reset of cached filter results
  for pind in pairs(game.players) do
    local filter = get(pind).tabs[defs.names.tabs.station].filter
    filter.cache = {}
    filter.last = nil
  end
end

return gui