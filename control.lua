-- code inspired by Optera's LTN and LTN Content Reader
-- LTN is required to run this mod (obviously, since its a UI to display data collected by LTN)
-- https://mods.factorio.com/mod/LogisticTrainNetwork
-- https://mods.factorio.com/mod/LTN_Content_Reader

-- control.lua only handles initial setup and event registration
-- UI and data processing are kept seperate, to allow the UI to always be responsive
-- data_processor.lua module: receives event data from LTN and processes it for usage by UI
-- gui_ctrl.lua module: handles UI events and displays data provided in global.data

-- constants
defs = require("__LTN_Tracker__.defines")
C = require(defs.pathes.modules.constants)
debug_log = settings.global[defs.names.settings.debug_level].value

------------------------------
------- initialization -------
------------------------------
custom_events = {
  on_data_updated = script.generate_event_name(),
  on_train_alert = script.generate_event_name(),
  on_ui_invalid = script.generate_event_name(),
}

-- load modules
util = require(defs.pathes.modules.util)
log2 = require(defs.pathes.modules.logger).log
egm = require(defs.pathes.modules.import_egm)
ui = require(defs.pathes.modules.gui_ctrl)
local prc = require(defs.pathes.modules.data_processing)

script.on_init(function()
  -- check for LTN interface, just in case
  if not remote.interfaces["logistic-train-network"] then
    error(log2("LTN interface is not registered."))
  end
  if debug_log then
    log2("Starting mod initialization for mod", defs.mod_name .. ".")
  end

  -- module init
  ui.on_init()
  prc.on_init()

  if debug_log then
    log2("Initialization finished.")
  end
end)

script.on_event(defines.events.on_player_created, function(event) ui.player_init(event.player_index) end)

script.on_load(function()
  ui.on_load()
  prc.on_load()
  if debug_log then
    log2("on_load finished")
  end
end)

-----------------------------------
------- settings and config -------
-----------------------------------

do
  local setting_dict = require("script.constants").settings
  script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    -- notifies modules if one of their settings changed
    if not event then return end
    local pind = event.player_index
    local player = game.players[pind]
    local setting = event.setting
    if debug_log then
      log2("Player", player.name, "changed setting", setting)
    end
    if setting_dict.ui[setting] then
      ui.on_settings_changed(pind, event)
    end
    if setting_dict.proc[setting] then
      prc.on_settings_changed(event)
    end
    if setting_dict.debug[setting] then
      debug_log = settings.global["ltnt-debug-level"].value
    end
  end)
end

do
  script.on_configuration_changed(function(data)
    if not data then return end
    -- handle changes to LTN
    if not game.active_mods[defs.names.ltn] then
      error("LogisticTrainNetwork is required to run LTNT.")
    end
    -- handle changes to LTN-Combinator
    if data.mod_changes[defs.names.ltnc] then
      global.gui.ltnc_is_active = game.active_mods[defs.names.ltnc] and true or false
      --if not data.mod_changes[MOD_NAME] then ui.reset_ui() end
    end
    -- handles changes to LTNT
    if data.mod_changes[defs.names.mod_name] then
      --ui.reset_ui()
      -- migration to 0.10.7
      global.proc.underload_is_alert = not settings.global["ltnt-disable-underload-alert"].value
    end
  end)
end

-----------------------------
------- STATIC EVENTS -------
-----------------------------
-- additional events are (un-)registered dynamically as needed by data_processing.lua

-- gui events
script.on_event(defines.events.on_gui_closed, ui.on_ui_closed)
--script.on_event(defs.gui_events, ui.ui_event_handler)

script.on_event("ltnt-toggle-hotkey", ui.on_toggle_button_click)
script.on_event(
  defines.events.on_lua_shortcut,
  function(event)
    if event.prototype_name == "ltnt-toggle-shortcut" then
      ui.on_toggle_button_click(event)
    end
  end
)

-- custom events
-- raised when updated data for gui is available
script.on_event(custom_events.on_data_updated, ui.update_ui)
-- raised when a train with an error is detected
script.on_event(custom_events.on_train_alert, ui.on_new_alert)
-- raised when UI element(s) became invalid
--script.on_event(custom_events.on_ui_invalid, ui.reset_ui)