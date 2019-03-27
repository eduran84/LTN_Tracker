-- code inspired by Optera's LTN and LTN Content Reader
-- LTN is required to run this mod (obviously, since its a UI to display data collected by LTN)
-- https://mods.factorio.com/mod/LogisticTrainNetwork
-- https://mods.factorio.com/mod/LTN_Content_Reader

-- control.lua only handles initial setup and event registration
-- UI and data processing are kept seperate, to allow the UI to always be responsive
-- data_processor.lua module: receives event data from LTN and processes it for usage by UI
-- gui_ctrl.lua module: handles UI events and displays data provided in global.data

-- constants
MOD_NAME = require("ltnt.const").global.mod_name
MOD_PREFIX = require("ltnt.const").global.mod_prefix
GUI_EVENTS = require("ltnt.const").global.gui_events
local LTN_MOD_NAME = require("ltnt.const").global.mod_name_ltn
local LTN_MINIMAL_VERSION = require("ltnt.const").global.minimal_version_ltn
local LTN_CURRENT_VERSION = require("ltnt.const").global.current_version_ltn

-- debugging / logging
-- levels:
--  0 =  no logging at all;
--  1 = log only important events;
--  2 = lots of logging;
--  3 = not available as setting, only for use during development

out = require("ltnt.logger")
debug_level = tonumber(settings.global["ltnt-debug-level"].value)

-- modules
local prc = require("ltnt.data_processing")
local ui = require("ltnt.gui_ctrl")

-- helper functions
local function format_version(version_string)
  return string.format("%02d.%02d.%02d", string.match(version_string, "(%d+).(%d+).(%d+)"))
end

  --create custom events
  custom_events = {
    on_data_updated = script.generate_event_name(),
    on_train_alert = script.generate_event_name(),
    on_ui_invalid = script.generate_event_name(),
  }

-----------------------------
------ event handlers  ------
-----------------------------

local function on_init()
  -- check for LTN
  local ltn_version = nil
  local ltn_version_string = game.active_mods[LTN_MOD_NAME]
  if ltn_version_string then
    ltn_version = format_version(ltn_version_string)
  end
  if not ltn_version or ltn_version < LTN_MINIMAL_VERSION then
    out.error(MOD_NAME, "requires version", LTN_MINIMAL_VERSION, "later of Logistic Train Network to run.")
  end
  -- also check for LTN interface, just in case
  if not remote.interfaces["logistic-train-network"] then
    out.error("LTN interface is not registered.")
  end
  if debug_level > 0 then
    out.info("control.lua", "Starting mod initialization for mod", MOD_NAME .. ". LTN version", ltn_version_string, "has been detected.")
  end

  -- module init
  ui.on_init()
  prc.on_init()

  if debug_level > 0 then
    out.info("control.lua", "Initialization finished.")
  end
end -- on_init()

do --handle runtime settings
  local setting_dict = require("ltnt.const").settings
  local function on_settings_changed(event)
    -- notifies modules if one of their settings changed
    if not event then return end
    local pind = event.player_index
    local player = game.players[pind]
    local setting = event.setting
    if debug_level > 0 then
      out.info("control.lua", "Player", player.name, "changed setting", setting)
    end
    if setting_dict.ui[setting] then
      ui.on_settings_changed(pind, event)
    end
    if setting_dict.proc[setting] then
      prc.on_settings_changed(event)
    end
    -- debug settings
    if setting_dict.debug[setting] then
      debug_level = tonumber(settings.global["ltnt-debug-level"].value)
      out.on_debug_settings_changed(event)
    end
  end

  script.on_event(defines.events.on_runtime_mod_setting_changed, on_settings_changed)
end
-----------------------------
------- STATIC EVENTS -------
-----------------------------
-- additional events are (un-)registered dynamically as needed by data_processing.lua

script.on_init(on_init)

script.on_load(
  function()
    ui.on_load()
    prc.on_load()
    if debug_level > 0 then
      out.info("control.lua", "on_load finished.")
    end
  end
)

local LTNC_MOD_NAME = require("ltnt.const").global.mod_name_ltnc
script.on_configuration_changed(
  function(data)
    if data and data.mod_changes[LTN_MOD_NAME] then
      local ov = data.mod_changes[LTN_MOD_NAME].old_version
      ov = ov and format_version(ov) or "0.0.0 (not present)"
      local nv = data.mod_changes[LTN_MOD_NAME].new_version
      nv = nv and format_version(nv) or "0.0.0 (not present)"
      if nv >= LTN_MINIMAL_VERSION then
        if nv > LTN_CURRENT_VERSION then
          out.warn("LTN version changed from ", ov, " to ", nv, ". That version is not supported, yet. Depending on the changes to LTN, this could result in issues with LTNT.")
        else
          out.info("control.lua", "LTN version changed from ", ov, " to ", nv)
        end
      else
        out.error("LTN version was changed from ", ov, " to ", nv, ".", MOD_NAME, "requires version",  LTN_MINIMAL_VERSION, " or later of Logistic Train Network to run.")
      end
    end
    if data and (data.mod_changes[MOD_NAME] or data.mod_changes[LTNC_MOD_NAME]) then
      global.gui.ltnc_is_active = game.active_mods[LTNC_MOD_NAME] and true or false
      ui.reset_ui()
      out.info("control.lua", MOD_NAME .. " updated to version " .. tostring(game.active_mods[MOD_NAME]))
    end
  end
)

script.on_event(defines.events.on_player_created, function(event) ui.player_init(event.player_index) end)


-- gui events
script.on_event(defines.events.on_gui_closed, ui.on_ui_closed)
script.on_event(GUI_EVENTS, ui.ui_event_handler)
script.on_event("ltnt-toggle-hotkey", ui.on_toggle_button_click)

-- custom events
-- raised when updated data for gui is available
script.on_event(custom_events.on_data_updated, ui.update_ui)
-- raised when a train with an error is detected
script.on_event(custom_events.on_train_alert, ui.on_new_alert)
-- raised when UI element(s) became invalid
script.on_event(custom_events.on_ui_invalid, ui.reset_ui) -- force full reset for all players