------------------------------------------------------------------------------------
-- cache variables
------------------------------------------------------------------------------------
local defs, egm, C = defs, egm, C
local alert_tab_name = defs.tabs.alert
local gui_data = {  -- cached global table data
  windows = {},
  alert_popup = {},
  show_alerts = {},
  is_ltnc_active = false,
  is_ltnc_open = {},
  station_select_mode = {},
  last_refresh_tick = {},
  refresh_interval = {},
}
gui = {}

------------------------------------------------------------------------------------
-- load sub-modules
------------------------------------------------------------------------------------
local mod_gui = require("mod-gui")
local tab_functions = {}
for _, tab_name in pairs(defs.tabs) do
  tab_functions[tab_name] = require(defs.pathes.modules[tab_name])
end

------------------------------------------------------------------------------------
-- gui module functions
------------------------------------------------------------------------------------
local function build(pind)--[[ --> custom egm_window
Creates the GUI for the given player.

Parameters:
  player_index :: uint
Return value
  the LTNT main window
]]
  local frame_flow
  local player = game.players[pind]
  local height = util.get_setting(defs.settings.window_height, player)
  if util.get_setting(defs.settings.window_location, player) == "left" then
    frame_flow = mod_gui.get_frame_flow(player)
    height = height < 710 and height or 710
  else
    frame_flow = player.gui.center
  end

  local preexisting_window = frame_flow[defs.names.window]
  if preexisting_window and preexisting_window.valid then
    preexisting_window.destroy()
  end
  egm.manager.delete_player_data(pind)

  local window = egm.window.build(frame_flow, {
    name = defs.names.window,
    caption = {"ltnt.mod-name"},
    height = height,
    width = C.window.width,
    direction = "vertical",
  })
  window.root.visible = false
  egm.window.add_button(window, {
    type = "sprite-button",
    style = defs.styles.shared.default_button,
    sprite = "utility/refresh",
    tooltip = {"ltnt.refresh-bt"},
  },
  {action = defs.actions.refresh_button})

  window.pane = egm.tabs.build(window.content, {direction = "vertical"})

  window.tabs = {}
  for tab_name, funcs in pairs(tab_functions) do
    window.tabs[tab_name] = tab_functions[tab_name].build(window)
  end
  gui_data.windows[pind] = window
  return window
end

local function get(pind)--[[  --> custom egm_window
Returns the GUI for the given player if it exists. Creates it otherwise.

Parameters
  player_index :: uint
Return value
  the LTNT main window
]]
  local window = gui_data.windows[pind]
  if window and window.content and window.content.valid then
    return window
  else
    return build(pind)
  end
end

local function update_tab(event)--[[
Updates the currently visible tab for the player given by event.player_index. Does
nothing if GUI is closed.

Parameters
  table with fields:
    player_index :: uint
]]
  local pind = event.player_index
  local window = get(pind)
  local tab_name = window.root.visible and window.pane.active_tab
  if tab_name then
    tab_functions[tab_name].update(window.tabs[tab_name], global.data)
    gui_data.last_refresh_tick[pind] = game.tick
    if tab_name == alert_tab_name then
      window.pane.buttons[alert_tab_name].style = defs.styles.shared.tab_button
    end
  end
end

local function update_tab_no_spam(event)--[[
Updates the currently visible tab for the player given by event.player_index. Does
nothing if GUI is closed or if the last update happened less than 60 ticks ago

Parameters
  table with fields:
    player_index :: uint
]]
  local pind = event.player_index
  local tick = game.tick
  if tick - gui_data.last_refresh_tick[pind] > 60 then
    local window = get(pind)
    local tab_name = window.root.visible and window.pane.active_tab
    if tab_name then
      tab_functions[tab_name].update(window.tabs[tab_name], global.data)
      gui_data.last_refresh_tick[pind] = game.tick
    end
  end
end

local function on_toggle_button_click(event)--[[
Toggles the visibility of the GUI window player given by event.player_index.

Parameters
  table with fields:
    player_index :: uint
]]
  local pind = event.player_index
  local new_state = egm.window.toggle(get(pind))
  if new_state then
    game.players[pind].opened = get(pind).root
    game.players[pind].set_shortcut_toggled(defs.controls.shortcut, true)
    update_tab(event)
  else
    game.players[pind].set_shortcut_toggled(defs.controls.shortcut, false)
  end
end

function gui.clear_station_filter()--[[
Resets station tab's cached filter results. Forces a cache rebuild next time the
station tab is updated.
]]
  for pind in pairs(game.players) do
    local filter = get(pind).tabs[defs.tabs.station].filter
    filter.cache = {}
    filter.last = nil
  end
end

local function build_alert_popup(pind)--[[  -> custom egm_window
Creates the alert popup for the given player.

Parameters:
  player_index :: uint
Return value
  the alert popup window
]]
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])
  local preexisting_window = frame_flow[defs.names.alert_popup]
  if preexisting_window and preexisting_window.valid then
    egm.manager.unregister(preexisting_window)
    preexisting_window.destroy()
  end
  local alert_popup = egm.window.build(frame_flow, {
      frame_style = defs.styles.alert_notice.frame,
      title_style = defs.styles.alert_notice.frame_caption,
      width = 160,
      caption = {"alert.popup-caption"},
      name = defs.names.alert_popup,
    }
  )
  local button = egm.window.add_button(alert_popup, {
      type = "sprite-button",
      style = defs.styles.shared.large_close_button,
      sprite = "utility/go_to_arrow",
      tooltip = {"alert.open-button"},
    },
    {action = defs.actions.show_alerts, window = alert_popup}
  )
  egm.window.add_button(alert_popup, {
      type = "sprite-button",
      style = defs.styles.shared.large_close_button,
      sprite = "utility/close_black",
      tooltip = {"alert.close-button"},
    },
    {action = defs.actions.close_popup, window = alert_popup}
  )
  gui_data.alert_popup[pind] = alert_popup
  return alert_popup
end

local function get_alert_popup(pind)--[[ --> custom egm_window
Returns the alert popup window for the given player if it exists. Creates it otherwise.

Parameters
  player_index :: uint

Return value
  the alert popup window
]]
  local window = gui_data.alert_popup[pind]
  if window and window.content and window.content.valid then
    egm.window.clear(window)
    return window
  else
    return build_alert_popup(pind)
  end
end

local function on_new_alert(event)--[[
Opens alert pop-up for all players and highlights alert tab.

Parameters
  table with fields:
    type :: string: name of the alert
    loco :: LuaEntity: a locomotive entity
    delivery :: Table: delivery data as received from LTN
    cargo :: Table: [item] = count
]]
  for pind in pairs(gui_data.show_alerts) do
    local window = get(pind)
    if window.root.visible then
      if window.pane.active_tab == alert_tab_name then
        event.player_index = pind
        update_tab(event)
      else
        window.pane.buttons[alert_tab_name].style = defs.styles.shared.tab_button_red
      end
    else
      local alert_popup = get_alert_popup(pind)
      alert_popup.root.visible = true
      alert_popup.content.add{
        type = "label",
        style = "tooltip_heading_label",
        caption = defs.errors[event.type].caption,
        tooltip = defs.errors[event.type].tooltip,
      }.style.single_line = false
      window.pane.buttons[alert_tab_name].style = defs.styles.shared.tab_button_red
    end
  end
end

local function player_init(pind)--[[
Initializes global table for given player and builds GUI.

Parameters
  player_index :: uint
]]
  local player = game.players[pind]
  if debug_mode then log2("Building UI for player", player.name) end
  -- set UI state globals
  gui_data.show_alerts[pind] = util.get_setting(defs.settings.show_alerts, player)  or nil
  gui_data.last_refresh_tick[pind] = 0
  local refresh_interval = util.get_setting(defs.settings.refresh_interval, player)
  if refresh_interval > 0 then
    gui_data.refresh_interval[pind] = refresh_interval * 60
  else
    gui_data.refresh_interval[pind] = nil
  end
  gui_data.station_select_mode[pind] = tonumber(util.get_setting(defs.settings.station_click_action, player))

  build(pind)
end
------------------------------------------------------------------------------------
-- event registration
------------------------------------------------------------------------------------
script.on_event({  -- gui interactions handling is done by egm manager module
    defines.events.on_gui_click,
    defines.events.on_gui_text_changed,
  },
  egm.manager.on_gui_input
)

script.on_event(defines.events.on_train_alert, on_new_alert)
script.on_event(defs.controls.toggle_hotkey, on_toggle_button_click)
script.on_event(defs.controls.toggle_filter, function(event)
  local window = get(event.player_index)
  if window.root.visible and window.pane.active_tab == defs.tabs.station then
    tab_functions[defs.tabs.station].focus_filter(window)
  end
end)


-- different sources triggering tab update
script.on_event({
    defines.events.on_tab_changed,
    defines.events.on_textbox_valid_value_changed,
  },
  update_tab
)
script.on_event(defs.controls.refresh_hotkey, update_tab_no_spam)
egm.manager.define_action(defs.actions.refresh_button, update_tab_no_spam)

local function on_gui_closed(event)--[[
Closes LTNT GUI or LTNC GUI, depending on which one is open.

Parameters
  table with fields:
    player_index :: uint
    element :: LuaGuiElement
]]
  if not (event.element and event.element.valid) then return end
  local pind = event.player_index
  local window = get(pind)
  if event.element.index == window.root.index then
    if gui_data.is_ltnc_active and gui_data.is_ltnc_open[pind] then
      gui_data.is_ltnc_open[pind] = nil
      remote.call(defs.remote.ltnc_interface, defs.remote.ltnc_close, pind)
      game.players[pind].opened = window.root
      update_tab(event)
    else
      egm.window.hide(window)
      game.players[pind].set_shortcut_toggled(defs.controls.shortcut, false)
    end
  end
end

script.on_event(defines.events.on_lua_shortcut,
  function(event)
    if event.prototype_name == defs.controls.shortcut then
      on_toggle_button_click(event)
    end
  end
)

script.on_event(defines.events.on_data_updated,
  function(event)
    local tick = game.tick
    for pind, interval in pairs(gui_data.refresh_interval) do
      if tick - gui_data.last_refresh_tick[pind] > interval  then
        gui_data.last_refresh_tick[pind] = tick
        update_tab({player_index = pind})
      end
    end
  end
)

------------------------------------------------------------------------------------
-- gui action definitions
------------------------------------------------------------------------------------
egm.manager.define_action(defs.actions.update_tab,--[[
  Triggering elements:
    checkbox @ station_tab
  Event: any gui event
  Data:  none
]]
  function(event, data)
    update_tab(event)
  end
)

egm.manager.define_action(defs.actions.filter_items,--[[
  Triggering elements:
    filter buttons @ inventory_tab
  Event: on_gui_click
  Data:
    group_index :: unit: index of the selected item group
    buttons :: array of LuaGuiElement: all filter buttons
]]function(event, data)
    for i, button in pairs(data.buttons) do
      button.enabled = not (i == data.group_index)
    end
  end
)

egm.manager.define_action(defs.actions.show_alerts,--[[
  Triggering elements:
    show alerts button @ alert_popup
  Event: on_gui_click
  Data:
    window :: EGM_Window object: window the button belongs to
]]function(event, data)
    data.window.root.visible = false
    local main_window = get(event.player_index)
    egm.tabs.set_active_tab(main_window.pane, defs.tabs.alert)
    main_window.root.visible = true
    game.players[event.player_index].opened = main_window.root
    update_tab(event)
  end
)

egm.manager.define_action(defs.actions.close_popup,--[[
  Triggering elements:
    close button @ alert_popup
  Event: on_gui_click
  Data:
    window :: EGM_Window object: window the button belongs to
]]function(event, data)
    data.window.root.visible = false
  end
)

local draw_circle = rendering.draw_circle
local render_arguments = {
  color = C.window.marker_circle_color,
  radius = 3,
  width = 10,
  surface = "nauvis",
  filled = false,
  target = {},
  target_offset  = {-1, -1},
  time_to_live = 300,
  players = {0},
}
egm.manager.define_action(defs.actions.station_name_clicked,--[[
  Triggering elements:
    most station name labels
  Event: on_gui_click
  Data:
    name :: string: station name
]]function(event, data)
    if debug_mode then log2("station_name_clicked", event, data) end

    local stop = global.data.stops[tonumber(global.data.name2id[data.name])]
    if stop and stop.entity and stop.entity.valid then
      local pind = event.player_index
      local player = game.players[pind]
      local entity = stop.entity
      if gui_data.station_select_mode[pind] < 3  then
        player.opened = entity
      end
      if gui_data.station_select_mode[pind] > 1 then
        player.zoom_to_world({entity.position.x+40, entity.position.y+0}, 0.4)
        render_arguments.target = entity
        render_arguments.players = {pind}
        draw_circle(render_arguments)
      end
    end
  end
)
egm.manager.define_action(defs.actions.select_station_entity,--[[
  Triggering elements:
    some station name labels
  Event: on_gui_click
  Data:
    stop_entity :: LuaEntity: station entity
]]function(event, data)
    if debug_mode then log2("select_station_entity", event, data) end
    local stop_entity = data.stop_entity
    if stop_entity and stop_entity.valid then
      local pind = event.player_index
      if gui_data.station_select_mode[pind] < 3  then
        game.players[pind].opened = stop_entity
      end
      if gui_data.station_select_mode[pind] > 1 then
        game.players[pind].zoom_to_world({stop_entity.position.x+40, stop_entity.position.y+0}, 0.4)
        render_arguments.target = stop_entity
        render_arguments.players = {pind}
        draw_circle(render_arguments)
      end
    end
  end
)
egm.manager.define_action(defs.actions.select_ltnc,--[[
  Triggering elements:
    select ltnc buttons @ station_tab
  Event: on_gui_click
  Data:
    stop_entity :: LuaEntity: station entity
    lamp_entity :: LuaEntity: LTN lamp input entity
]]function(event, data)
    local pind = event.player_index
    local lamp_entity = data.lamp_entity
    if lamp_entity.valid then
      if remote.call("ltn-combinator", "open_ltn_combinator", pind, lamp_entity, false) then
        gui_data.is_ltnc_open = {[pind] = true}
      else
        local player = game.players[pind]
        player.surface.create_entity{
          name = "flying-text",
          position = player.position,
          text = {"ltnt.no-ltnc-found-msg"},
          color = {r=1,g=0,b=0}
        }
      end
    end
  end
)
egm.manager.define_action(defs.actions.select_entity,--[[
  Triggering elements:
    train composition label @ depot_tab
    select train button @ alert_tab
  Event: on_gui_click
  Data:
    entity :: LuaEntity
]]function(event, data)
    local player = game.players[event.player_index]
    if data.entity.valid and player then
      player.opened = data.entity
    end
  end
)

local function trim(s)
  local from = s:match("^%s*()")
  return from > #s and "" or s:match(".*%S", from)
end
egm.manager.define_action(defs.actions.update_filter,--[[
  Triggering elements:
    filter textbox @ station_tab
  Event: on_gui_text_changed
  Data:
    filter :: Table with fields:
      cache :: Table: cached results for old filter string
      last :: string: filter string before change
      current :: string: filter string after change
]]function(event, data)
    if event.name ~= defines.events.on_gui_text_changed then return end
    local elem = event.element
    if elem.text then
      local input = trim(elem.text)
      if input:len() == 0 then
        data.filter.current = nil
      else
        data.filter.current = input
      end
    end
    update_tab(event)
  end
)

egm.manager.define_action(defs.actions.clear_history,--[[
  Triggering elements:
    delete button @ history_tab
  Event: on_gui_click
  Data:
    egm_table :: EGM_SortableTable object
]]function(event, data)
    global.data.delivery_hist = {}
    global.data.newest_history_index = 1
    egm.table.clear(data.egm_table)
  end
)
egm.manager.define_action(defs.actions.clear_alerts,--[[
  Triggering elements:
    delete all button @ alert_tab
  Event: on_gui_click
  Data:
    egm_table :: EGM_SortableTable object
]]function(event, data)
    global.data.trains_error = {}
    global.data.train_error_count = 1
    egm.table.clear(data.egm_table)
  end
)
egm.manager.define_action(defs.actions.clear_single_alert,--[[
  Triggering elements:
    delete row button @ alert_tab
  Event: on_gui_click
  Data:
    egm_table :: EGM_SortableTable object
    row_data :: Table containing information about clicked row
]]function(event, data)
    global.data.trains_error[data.row_data.error_id] = nil
    egm.table.delete_row(data.egm_table, data.row_data.row_index)
  end
)

------------------------------------------------------------------------------------
-- initialization and configuration
------------------------------------------------------------------------------------
local function on_settings_changed(event)
  local setting = event and event.setting
  if not(setting and setting:sub(1, 4) == defs.mod_prefix) then return end
  local pind = event.player_index
  if     setting == defs.settings.window_height
      or setting == defs.settings.window_location then
    build(pind)
  end
  local player = game.players[pind]
  if setting == defs.settings.refresh_interval then
    local refresh_interval = util.get_setting(setting, player)
    if refresh_interval > 0 then
      gui_data.refresh_interval[pind] = refresh_interval * 60
    else
      gui_data.refresh_interval[pind] = nil
    end
  end
  if setting == defs.settings.fade_timeout then
    tab_functions[defs.tabs.inventory].set_fadeout_time(get(pind).tabs[defs.tabs.inventory], pind)
  end
  if setting == defs.settings.station_click_action then
    gui_data.station_select_mode[pind] = tonumber(util.get_setting(setting, player))
  end
  if setting == defs.settings.show_alerts then
    gui_data.show_alerts[pind] = util.get_setting(defs.settings.show_alerts) or nil
  end
end

local events = {
    [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
    [defines.events.on_gui_closed] = on_gui_closed,
    [defines.events.on_player_created] = player_init,
  }

local gui_main = {}

function gui_main.on_init()
  global.gui_data = global.gui_data or gui_data
  egm.manager.on_init()
  gui_data.is_ltnc_active = game.active_mods[defs.names.ltnc] and true or false
  for pind in pairs(game.players) do
    player_init(pind)
  end
end

function gui_main.get_events()
  return events
end

function gui_main.on_load()
  gui_data = global.gui_data
  egm.manager.on_load()
end

function gui_main.on_configuration_changed(data)
   -- handle changes to LTN-Combinator
  local reset = true  -- TODO implement proper logic for UI reset
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
    gui.clear_station_filter()
    for pind in pairs(game.players) do
      build(pind)
    end
  end
end

return gui_main