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
class_dict.LuaGuiElement.item = true

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
if DEV_MODE then
  logger.settings.log_to_file = "ltnt.log"
end

local function add_debug_commands()
  logger.add_debug_commands()
  if not commands.commands["reset-ltnt-stats"] then
    commands.add_command(
      "reset-ltnt-stats",
      "<item> - Resets stored data used in LTN Tracker's statistics window for one item. If no item is specified, all data is deleted.",
      function(args)
        if args and args.parameter then
          print(args.parameter)
          local ltn_item = args.parameter
          local proto = game.item_prototypes[ltn_item]
          if proto then
            ltn_item = "item," .. ltn_item
          else
            local proto = game.fluid_prototypes[ltn_item]
            if proto then
              ltn_item = "fluid," .. ltn_item
            else
              ltn_item = nil
            end
          end
          if ltn_item then
            for _, stats in pairs(global.statistics) do
              stats[ltn_item] = nil
            end
            print("LTN Tracker statistics for item", args.parameter, "have been deleted.")
          else
            print("Item", args.parameter, "does not exist.")
          end
        else
          for k in pairs(global.statistics) do
            global.statistics[k] = nil
          end
          print("LTN Tracker statistics have been deleted.")
        end
      end
    )
  end
  if not commands.commands["reset-ltnt-gui"] then
    commands.add_command(
      "reset-ltnt-gui",
      "Resets LTN Tracker's GUI elements.",
      function(args)
        for pind, player in pairs(game.players) do
          local frame_flow = player.gui.left
          -- wipe every gui component
          local old_window = frame_flow[defs.names.alert_popup]
          if old_window and old_window.valid then
            old_window.destroy()
          end
          old_window = frame_flow[defs.names.sidebar]
          if old_window and old_window.valid then
            old_window.destroy()
          end
          frame_flow = player.gui.center
          old_window = frame_flow[defs.names.window]
          if old_window and old_window.valid then
            old_window.destroy()
          end
          egm.manager.delete_player_data(pind)
        end
        print("LTN Tracker GUI has been reset.")
      end
    )
  end
end
local function remove_debug_commands()
  logger.remove_debug_commands()
  commands.remove_command("reset-ltnt-stats")
  commands.remove_command("reset-ltnt-gui")
end

debug_mode = DEV_MODE or util.get_setting(defs.settings.debug_mode)
if debug_mode then
  add_debug_commands()
end

local function on_settings_changed(event)
  if event.setting and event.setting == defs.settings.debug_mode then
    debug_mode = settings.global[defs.settings.debug_mode].value
    if debug_mode then
      add_debug_commands()
    else
      remove_debug_commands()
    end
  end
end

local events = {
    [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
  }

local dbg = {}

function dbg.get_events()
  return events
end

return dbg
