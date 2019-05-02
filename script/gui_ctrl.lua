----------------------
------ pre init ------
----------------------

-- localize helper functions
local s2n = tonumber
local match = string.match
local defs = defs
local egm = egm
local C = C
local gui = require(defs.pathes.modules.gui)

-----------------------------
------ initialization  ------
-----------------------------
-- do not change any of the variables defined above from this point onward
-- enforced by desync
local function on_load()
  gui.on_load()
end

local function player_init(pind)
  local player = game.players[pind]
  if debug_mode then
    log2("Building UI for player", player.name)
  end

  -- set UI state globals
  global.gui.last_refresh_tick[pind] = 0
  global.gui.refresh_interval[pind] = settings.get_player_settings(player)["ltnt-refresh-interval"].value * 60
  global.gui.station_select_mode[pind] = tonumber(settings.get_player_settings(player)["ltnt-station-click-behavior"].value)

  -- build UI
  if not settings.get_player_settings(player)["ltnt-show-button"].value then
    --GC.toggle_button:hide(pind)
  end

  gui.build(pind)
end

local LTNC_MOD_NAME = require("script.constants").global.mod_name_ltnc
local function on_init()
  gui.on_init()
  -- global storage for UI state
  global.gui = {
    last_refresh_tick = {},
    refresh_interval = {},
    ltnc_is_active = game.active_mods[LTNC_MOD_NAME] and true or false,
    is_ltnc_open = {},
    station_select_mode = {},
  }

  global.last_sort = {}
  -- initialize present players, they dont trigger on_player_created event
  for pind,_ in pairs(game.players) do
    player_init(pind)
  end
end

local function reset_ui()
  -- wipe existing UIs and clear global UI storage...
  log2("Resetting UI.")
  global.gui = nil
  -- ... and rebuild
  on_init()
end

local function clear_station_filter()
  -- hacky way to force reset of cached filter results
  GC.stop_tab.mystorage.last_filter = {}
end
------------------------------
--- RUNTIME EVENT HANDLERS ---
------------------------------
local function on_settings_changed(pind, event)
  local player = game.players[pind]
  local setting = event.setting
  if setting == "ltnt-window-height" then
    player_init(pind) -- rebuild entire ui for player
  elseif setting == "ltnt-show-button" then
    -- show or hide toggle button
    if settings.get_player_settings(player)[setting].value then
      GC.toggle_button:show(pind)
    else
      GC.toggle_button:hide(pind)
    end
  end
  if setting == "ltnt-refresh-interval" then
    global.gui.refresh_interval[pind] = settings.get_player_settings(player)[setting].value * 60 -- convert seconds to ticks
  end
  if setting == "ltnt-station-click-behavior" then
    global.gui.station_select_mode[pind] = tonumber(settings.get_player_settings(player)["ltnt-station-click-behavior"].value)
  end
end

-- basic UI functions

local function on_toggle_button_click(event)
  local pind = event.player_index
  local new_state = egm.window.toggle(gui.get(pind))
  if new_state then
    game.players[pind].opened = gui.get(pind).root
    game.players[pind].set_shortcut_toggled("ltnt-toggle-shortcut", true)
    gui.update_tab(event)
  else
    game.players[pind].set_shortcut_toggled("ltnt-toggle-shortcut", false)
  end
end

local function close_gui(pind)
  game.players[pind].opened = nil
  egm.window.hide(gui.get(pind))
  if debug_mode then
    log2("Closing UI for player", pind)
  end
end

--local match_ui_name function(element_name) return match(element_name, ms) end
local handlers = {on_toggle_button_click = on_toggle_button_click}

-- handler for on_data_updated event
local function update_ui(event)
  local tick = game.tick
  local interval = global.gui.refresh_interval
  for pind in pairs(game.players) do
    if interval[pind] > 0 and tick - global.gui.last_refresh_tick[pind] > interval[pind]  then
      global.gui.last_refresh_tick[pind] = tick
      gui.update_tab({player_index = pind})
    end
  end
end

-- handler for on_gui_closed event
local function on_ui_closed(event)
  -- event triggers whenever any UI element is closed, so check if it is actually the ltnt UI that is supposed to close
  local pind = event.player_index
	if event.element and event.element.valid and event.element.index == gui.get(pind).root.index then
    if global.gui.ltnc_is_active and global.gui.is_ltnc_open and global.gui.is_ltnc_open[pind] then
      global.gui.is_ltnc_open[pind] = nil
      remote.call("ltn-combinator", "close_ltn_combinator", pind)
      game.players[pind].opened = gui.get(pind).root.index
      gui.update_tab(event)
    else
      close_gui(event.player_index)
    end
	end
end

-- handler for on_new_alert custom event
local function on_new_alert(event)
  if event and event.type then
    for pind in pairs(game.players) do
      -- GC.toggle_button:set_alert(pind)
      -- GC.outer_frame:set_alert(pind)
    end
  end
end

function handlers.on_refresh_bt_click(event, data_string)
  local pind = event.player_index
  if global.gui.last_refresh_tick[pind] + global.gui.refresh_interval[pind] < game.tick  then
    global.gui.last_refresh_tick[pind] = game.tick
    update_tab(event)
  end
end

do -- handle button/label clicks that are supposed to select a train/station/cc
  local function select_entity(pind, entity)
    if entity and entity.valid and game.players[pind] then
      game.players[pind].opened = entity
      return true
    end
  end
  local function select_combinator(pind, stop_entity, input_lamp)
    if global.gui.ltnc_is_active then
      if remote.call("ltn-combinator", "open_ltn_combinator", pind, input_lamp, false) then
        global.gui.is_ltnc_open = {[pind] = true}
        return true
      end
      local player = game.players[pind]
      player.surface.create_entity{
        name="flying-text",
        position=player.position,
        text={"ltnt.no-ltnc-found-msg"},
        color={r=1,g=0,b=0}
      }
      return false
    end
    return false
  end

  function handlers.on_cc_button_clicked(event, data_string)
    local stop =  global.data.stops[s2n(match(data_string, "cc_(.*)"))]
    if stop and stop.entity and stop.entity.valid then
      select_combinator(event.player_index, stop.entity, stop.input)
    end
  end
end --do

function handlers.on_item_clicked(event, data_string)
  -- item name and amount is encoded in data_string
  GC.inv_tab:on_item_clicked(event.player_index, data_string)
end


return {
  on_init = on_init,
  on_load = on_load,
  on_toggle_button_click = on_toggle_button_click,
  on_settings_changed = on_settings_changed,
  player_init = player_init,
  on_ui_closed = on_ui_closed,
  on_new_alert = on_new_alert,
  update_ui = update_ui,
  reset_ui = reset_ui,
  clear_station_filter = clear_station_filter,
}