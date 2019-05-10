local util = require("util")
util.misc =  require(defs.pathes.modules.olib_misc)
util.train = require(defs.pathes.modules.olib_train)
util.build_item_table = require(defs.pathes.modules.build_item_table)

local match, format = string.match, string.format
local floor, math_log = math.floor, math.log

function util.get_items_in_network(items_by_network, network_id)--[[
Extracts number of items provided in a certain network from list items_by_network.

Parameters:
  items_by_network :: dictionary int -> LtnItemList
  network id :: int: the selected network ID

Return value:
  items_in_network :: LtnItemList
]]local new_item_list = {}
  local btest = bit32.btest
	for items_network_id, item_list in pairs(items_by_network) do
		if btest(network_id, items_network_id) then
			for item, count in pairs(item_list) do
				new_item_list[item] = (new_item_list[item] or 0) + count
			end
		end
  end
	return new_item_list
end

local base_1000 = math_log(1000)
local metric_prefix = {[-2] = "n", [-1] = "m", [0] = "", [1] = "k", [2] = "M", [3] = "G", [4] = "T"}
function util.format_number(x)--[[ --> string
Formats large number N into nnn[prefix] format.

Parameters:
  x :: int or float

Return value:
  formatted number :: string
]]if x then
    local sign = 1
    if x < 0 then
      sign = -1
      x = -x
    elseif x == 0 then
      return "0"
    end
    local order = floor(math_log(x) / base_1000)
    return format("%3d%s", sign * x / (1000 ^ order), metric_prefix[order])
  end
  return "0"
end

function util.sort(t, func)--[[ --> table
Sort table with non-integer keys. Works because of Factorio's pairs() implementation.
Does NOT work in-place, sorted table is returned.
See: https://lua-api.factorio.com/latest/Libraries.html

Parameters:
  t :: table: the table to be sorted
  func :: function (optional): function to use for sorting (same as you would use for table.sort)

Return value:
  sorted table ::  table
]]local keys = {}
  local n = 0
  for k, v in pairs(t) do
    n = n + 1
    keys[n] = k
  end
  table.sort(keys, function(a, b)
    local value_a, value_b = t[a], t[b]
    return func(value_a, value_b)
  end)
  local sorted_t = {}
  for i = 1, n do
    local key = keys[i]
    sorted_t[key] = t[key]
  end
  return sorted_t
end

function util.get_setting(setting, player)--[[ --> string, int or bool
Get value of "setting".

Parameters:
  setting :: string: name of the setting
  player :: LuaPlayer (optional): needed for per-player settings

Return value:
  value :: string, int or bool: value of the setting
]]if settings.global[setting] then
    return settings.global[setting].value
  elseif settings.player[setting] then
    if not player then
      error(logger.tostring("No player specified when trying to read per-player setting", setting))
    end
    return settings.get_player_settings(player)[setting].value
  elseif settings.startup[setting] then
    return settings.startup[setting].value
  end
  error(logger.tostring("Mod setting", setting, "does not exist."))
end

local sprite_cache = {}
function util.get_item_sprite(item)--[[ --> string
Gets the sprite name for an item.

Parameters
  item :: LtnItem

Return value
  sprite :: string
]]if sprite_cache[item] then return sprite_cache[item] end
  local type, name = match(item, "([^,]+),(.+)") -- format: "<item_type>,<item_name>"
  if (type and name) then
    local proto
    if type == "item" then
      proto = game.item_prototypes[name]
    else
      proto = game.fluid_prototypes[name]
    end
    if proto then
      sprite_cache[item] = type .. "/" .. name
    else
      sprite_cache[item] = ""
    end
  else
    sprite_cache[item] = ""
  end
  return sprite_cache[item]
end

local name_cache = {}
function util.get_item_name(item)--[[ --> string
Gets the localized name for an item.

Parameters
  item :: LtnItem

Return value
  name :: string
]]if name_cache[item] then return name_cache[item] end
  local type, name = match(item, "([^,]+),(.+)") -- format: "<item_type>,<item_name>"
  if (type and name) then
    local proto
    if type == "item" then
      proto = game.item_prototypes[name]
    else
      proto = game.fluid_prototypes[name]
    end
    if proto then
      name_cache[item] = proto.localised_name or name
    else
      name_cache[item] = ""
    end
  else
    name_cache[item] = ""
  end
  return name_cache[item]
end

local composition_cache = {}
function util.get_train_composition_string(train)
  if not composition_cache[train.id] then
    composition_cache[train.id] = util.train.get_train_composition_string(train)
  end
  return composition_cache[train.id]
end

local locomotive_cache = {}
function util.get_main_locomotive(train)
  if not locomotive_cache[train.id] then
    locomotive_cache[train.id] = util.train.get_main_locomotive(train)
  end
  return locomotive_cache[train.id]
end

return util