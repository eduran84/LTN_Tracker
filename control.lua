-- code inspired by Optera's LTN and LTN Content Reader
-- LTN is required to run this mod (obviously, since its a UI to display data collected by LTN)
-- https://mods.factorio.com/mod/LogisticTrainNetwork

-- control.lua only handles initial setup and event registration
-- UI and data processing are kept seperate, to allow the UI to always be responsive
-- data_processor.lua module: receives event data from LTN and processes it for usage by UI
-- gui.lua module: handles UI events and displays data provided in global.data

-- constants
defs = require("__LTN_Tracker__.defines")
C = require(defs.pathes.modules.constants)
debug_mode = true --settings.global[defs.names.settings.debug_level].value

------------------------------
------- initialization -------
------------------------------
defines.events.on_data_updated = script.generate_event_name()
defines.events.on_train_alert = script.generate_event_name()
defines.events.on_ui_invalid = script.generate_event_name()

custom_events = {
  on_data_updated = defines.events.on_data_updated,
  on_train_alert = defines.events.on_train_alert,
  on_ui_invalid = defines.events.on_ui_invalid,
}

-- load modules
util = require(defs.pathes.modules.util)
logger = require(defs.pathes.modules.olib_logger)
log2 = logger.log
egm = require(defs.pathes.modules.import_egm)
local gui = require(defs.pathes.modules.gui)
local prc = require(defs.pathes.modules.data_processing)
if debug_mode then
  logger.add_debug_commands()
end

script.on_init(function()
  -- check for LTN interface, just in case
  if not remote.interfaces["logistic-train-network"] then
    error("LTN interface is not registered.")
  end
  if debug_mode then
    log2("Starting mod initialization for mod", defs.mod_name .. ".")
  end
  -- module init
  gui.on_init()
  prc.on_init()

  if debug_mode then
    log2("Initialization finished.")
  end
end)

script.on_load(function()
  gui.on_load()
  prc.on_load()
end)

-----------------------------------
------- settings and config -------
-----------------------------------
local setting_dict = require("script.constants").settings
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  -- notifies modules if one of their settings changed
  if not event then return end
  gui.on_settings_changed(event)
  local pind = event.player_index
  local player = game.players[pind]
  local setting = event.setting
  if debug_mode then
    log2("Player", player.name, "changed setting", setting)
  end
  if setting_dict.proc[setting] then
    prc.on_settings_changed(event)
  end
  if setting == defs.settings.debug_level then
    debug_mode = settings.global[setting].value
  end
end)

script.on_configuration_changed(function(data)
  if not data then return end
  -- handle changes to LTN
  gui.on_configuration_changed(data)
  if not game.active_mods[defs.names.ltn] then
    error("LogisticTrainNetwork is required to run LTNT.")
  end
  -- handles changes to LTNT
  if data.mod_changes[defs.names.mod_name] then
    -- migration to 0.10.7
    global.proc.underload_is_alert = not settings.global["ltnt-disable-underload-alert"].value
  end
end)