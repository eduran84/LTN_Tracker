-- code inspired by Optera's LTN and LTN Content Reader
-- LTN is required to run this mod (obviously, since its a UI to display data collected by LTN)
-- https://mods.factorio.com/mod/LogisticTrainNetwork

-- control.lua only handles initial setup and event registration
-- UI and data processing are kept seperate, to allow the UI to always be responsive
-- data_processor.lua module: receives event data from LTN and processes it for usage by UI
-- gui.lua module: handles UI events and displays data provided in global.data

------------------------------------------------------------------------------------
-- initialization
------------------------------------------------------------------------------------
defs = require("defines")
logger = require(defs.pathes.modules.olib_logger)
log2 = logger.log
C = require(defs.pathes.modules.constants)
defines.events.on_data_updated = script.generate_event_name()
defines.events.on_train_alert = script.generate_event_name()

util = require(defs.pathes.modules.util)
egm = require(defs.pathes.modules.import_egm)
local gui = require(defs.pathes.modules.gui_main)
local prc = require(defs.pathes.modules.data_processing)
local cache_item_data = require(defs.pathes.modules.cache_item_data)

debug_mode = util.get_setting(defs.settings.debug_mode)

script.on_init(function()
  -- check for LTN interface, just in case
  if not remote.interfaces[defs.remote.ltn] then
    error("LTN interface is not registered.")
  end
  if debug_mode then
    log2("Starting mod initialization for mod", defs.mod_name .. ".")
  end
  -- module init
  global.item_groups = {}
  cache_item_data(global.item_groups)
  gui.on_init()
  prc.on_init()

  if debug_mode then
    log2("Initialization finished.")
  end
end)

script.on_load(function()
  gui.on_load()
  prc.on_load()
  if debug_mode then
    logger.add_debug_commands()
  end
end)

-------------------------------------------------------------------------------------
-- settings and config
-------------------------------------------------------------------------------------
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  local setting = event and event.setting
  if not(setting and setting:sub(1, 4) == defs.mod_prefix) then return end

  if debug_mode then
    log2("Player", game.players[event.player_index].name, "changed setting", setting)
  end
  if setting == defs.settings.debug_mode then
    debug_mode = util.get_setting(setting)
    if debug_mode then
      logger.add_debug_commands()
    else
      logger.remove_debug_commands()
    end
    return
  end
  local setting_found = gui.on_settings_changed(event)
  if setting_found then return end
  prc.on_settings_changed(event)
end)

script.on_configuration_changed(function(data)
  if not data then return end
  if not game.active_mods[defs.names.ltn] then
    error("LogisticTrainNetwork is required to run LTNT.")
  end
  cache_item_data(global.item_groups)
  gui.on_configuration_changed(data)
  local ltnt_data = data.mod_changes[defs.names.mod_name]
  if ltnt_data and ltnt_data.old_version
      and util.misc.format_version(ltnt_data.old_version) < "00.10.07" then
    -- migration to 0.10.7
    global.proc.underload_is_alert = not util.get_setting(defs.settings.disable_underload)
  end
end)