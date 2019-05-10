local gui_type_dict = {
  [defines.gui_type.none] = "none",
  [defines.gui_type.entity] = "entity",
  [defines.gui_type.research] = "research",
  [defines.gui_type.controller] = "controller",
  [defines.gui_type.production] = "production",
  [defines.gui_type.item] = "item",
  [defines.gui_type.bonus] = "bonus",
  [defines.gui_type.trains] = "trains",
  [defines.gui_type.achievement] = "achievement",
  [defines.gui_type.blueprint_library] = "blueprint_library",
  [defines.gui_type.equipment] = "equipment",
  [defines.gui_type.logistic] = "logistic",
  [defines.gui_type.other_player] = "other_player",
  [defines.gui_type.kills] = "kills",
  [defines.gui_type.permissions] = "permissions",
  [defines.gui_type.tutorials] = "tutorials",
  [defines.gui_type.custom] = "custom",
  [defines.gui_type.server_management] = "server_management",
  [defines.gui_type.player_management] = "player_management",
}
local class_dict = logger.settings.class_dictionary
class_dict.LuaGuiElement.index = true

local LuaEntity = class_dict.LuaEntity
LuaEntity.position = nil
LuaEntity.unit_number = true

class_dict.LuaGroup = {
  name = true,
  type = true,
  group = true,
  subgroups = true,
  order = true,
}

if defs.DEVELOPER_MODE then
  debug_mode = true
  logger.add_debug_commands()
  logger.settings.max_depth = 6
  class_dict.LuaTrain.LuaTrain.station = true
else
  debug_mode = util.get_setting(defs.settings.debug_mode)
end

local function on_settings_changed(event)
  if event.setting and event.setting == defs.names.settings.debug_mode then
    debug_mode = settings.global[defs.names.settings.debug_mode].value
  end
end

local events = {
    [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
  }

local dbg = {}

function dbg.on_init()
  if defs.DEVELOPER_MODE then
    debug_mode = true
  else
    debug_mode = util.get_setting(defs.settings.debug_mode)
  end
end

function dbg.get_events()
  return events
end

return dbg
