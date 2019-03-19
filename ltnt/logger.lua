-- hardcoded parameters
local filename = "ltnt.log"
local mod_tag = "[" .. MOD_PREFIX:upper() .. "]"
local ERROR = "ERROR"
local WARN = "WARN"
local INFO = "INFO"
local debug_print = settings.global["ltnt-debug-print"].value
local max_depth = 6 -- maximum depth up to which nested objects are converted

-- define factorio objects and properties the logger should convert
local class_dict = {
  LuaGuiElement = {
    name = {"name"},
    valid = {"valid"},
    type = {"type"},
    parent = {"parent", "name"},
    children = {"children"},
  },
  LuaTrain = {
    id = {"id"},
    valid = {"valid"},
    locomotives = {"locomotives"}
    --carriages = {"carriages"},
    --schedule = {"schedule"},
  },
  LuaPlayer = {
    name = {"name"},
    index = {"index"},
    opened = {"opened"},
  },
  LuaEntity = {
    backer_name = {"backer_name"},
    name = {"name"},
    type = {"type"},
  },
}

-- private functions of this module

-- cache functions
local match = string.match
local format = string.format
local getinfo = debug.getinfo
local function serpb(arg)  -- custom formatting for serpent.block output when handling factorio classes
   return serpent.block(
    arg, {
      sortkeys = false,
      custom = (function(tag,head,body,tail)
        if tag:find('^FOBJ_') then
          --body = body:gsub("\n%s+", "")
          tag = tag:gsub("^FOBJ_", "")
          tag = tag:gsub("[%s=]", "")
          return tag..head..body..tail
        else
          return tag..head..body..tail
        end
      end)
    }
  )
end

-- read class name of a Factorio lua object from string returned by its .help() method
local function help2name(str)
  return match(str, "Help for%s([^:]*)")
end
-- catch nils in variable length function input
local function pack_varargs(...)
  return { n = select("#", ...); ... }
end

-- Factorio lua objects are tables with key "__self" and a userdata value; most of them have a .help() method
local function is_object(tb)
  -- !ISSUE if the object does not have a help method (LuaBootstrap, LuaRemote, probably others) checking existence of .help will throw an error
  if tb["__self"] and type(tb["__self"]) == "userdata" and tb.valid and tb.help then
    return true
  else
    return false
  end
end

local function function_to_string(func)
  local info = getinfo(func, "S")
  return format("[%s]:%d", info.short_src, info.linedefined)
end

local function factorio_obj_to_table(obj)
  local class_name = help2name(obj.help())
  local tb = nil
  if class_dict[class_name] then
    tb = {}
    for k,v in pairs(class_dict[class_name]) do
      local value = obj
      for _,w in pairs(class_dict[class_name][k]) do
        value = value[w]
        if type(value) ~= "table" then
          break
        end
      end
      tb[k] = value
    end
  end
  return {["FOBJ_"..class_name] = tb} -- prefix for formatting with serpent.block
end

local function table_to_string(tb, level)
  level = (level or 0) + 1
  -- check for stuff that serpent does not convert to my liking and do the conversion here
  local log_tb = {} -- copy table, otherwise logger would modify the original input table
  for k,v in pairs(tb) do
    if type(v) == "table" and is_object(v) then
      log_tb[k] = table_to_string(factorio_obj_to_table(v), level) -- yay, recursion
    elseif type(v) == "table" and level < max_depth then --regular table
      log_tb[k] = table_to_string(v, level) -- more recursion
    elseif type(v) == "function" then
      v = function_to_string(v)
    else
      log_tb[k] = v
    end
  end
  if level == 1 then
    return serpb(log_tb) -- format converted table with serpent
  else
    return log_tb
  end
end

-- convert any type of argument into a human-readable string
local function _tostring(arg)
  if arg == nil then
    return "<nil>" -- otherwise the argument is just ommited
  end
  local t = type(arg)
  if t == "string" then return arg
  elseif t == "number" or t == "boolean" then return tostring(arg)
  elseif t == "function" then
    return function_to_string(arg)
  elseif t == "table" then
    if is_object(arg) then
      return table_to_string(factorio_obj_to_table(arg))
    else
      return table_to_string(arg)
    end
  elseif t == "userdata" then
    return serpb(arg)
  else
    _log("WARN", "Unknown data type: " .. t)
  end
end

-- main function to generate output
local function _log(msg_type, tag, pargs)
  local message = ""

  if msg_type == "ERROR" or msg_type == "WARN" then
    local info = getinfo(3, "Sl")
    tag = format("%s:%d", info.short_src, info.currentline)
  end
  -- build prefix
  if tag and type(tag) == "string" then
    message = mod_tag .. "[".. msg_type .."]<" .. tag .. "> "
  else
    message = mod_tag .. "[".. msg_type .."]" .. _tostring(tag)
  end
  -- convert all arguments to strings and concatenate
  local string_tb = {}
  for i = 1, pargs.n do
    string_tb[i] = _tostring(pargs[i])
  end
  message = message .. table.concat(string_tb, " ")

  -- add a traceback if it is an error
  if msg_type == "ERROR" then
    message = message.."\n"..debug.traceback(nil, 3)
  end

  if (debug_print or msg_type == "WARN") and game then
    game.print(message)
  end
  if debug_level > 0 then
    log(message)
  end
  return message
end

-- public module functions
-- wrappers for _log
local function _error(...)
  local message = _log(ERROR, "", pack_varargs(...))
  error(message)
end
local function warn(...)
  _log(WARN, "",  pack_varargs(...))
end
local function info(tag, ...)
  _log(INFO, tag, pack_varargs(...))
end
-- custom assert
local function _assert(arg, ...)
  if not arg then
    local message = _log("ERROR", "", pack_varargs(...))
    error(message)
  else
    return arg
  end
end

local function on_debug_settings_changed(event)
  debug_print = settings.global["ltnt-debug-print"].value
end

-- return public functions
local logger = {
  error = _error,
  info = info,
  warn = warn,
  assert = _assert,
  on_debug_settings_changed = on_debug_settings_changed,
  }
return logger