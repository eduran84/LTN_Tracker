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
print = logger.print
C = require(defs.pathes.modules.constants)
defines.events.on_data_updated = script.generate_event_name()
defines.events.on_train_alert = script.generate_event_name()

util = require(defs.pathes.modules.util)

egm = require(defs.pathes.modules.import_egm)
local cache_item_data = require(defs.pathes.modules.cache_item_data)

-------------------------------------------------------------------------------------
-- settings and config
-------------------------------------------------------------------------------------
local event_blacklist = {
  [defines.events.on_gui_click] = true,
  [defines.events.on_gui_text_changed] = true,
  [defines.events.on_tick] = true,
}

local modules = {
  dbg = require("script/debug"),
  gui_main = require(defs.pathes.modules.gui_main),
  gui_sidebar = require(defs.pathes.modules.gui_sidebar),
  data_processing = require(defs.pathes.modules.data_processing),
}

local function register_events(modules)
  local events = {}
  for module_name, module in pairs(modules) do
    if module.get_events then
      local module_events = module.get_events()
      for event, handler in pairs(module_events) do
        events[event] = events[event] or {}
        events[event][module_name] = handler
      end
    end
  end
  for event, handlers in pairs(events) do
    if event_blacklist[event] then
      error(logger.tostring("Event is blacklisted for use with general event handler."))
    end
    local function action(event)
      for _, handler in pairs(handlers) do
        handler(event)
      end
    end
    script.on_event(event, action)
  end
end

script.on_event({  -- gui interactions handling is done by egm manager module
    defines.events.on_gui_click,
    defines.events.on_gui_text_changed,
    defines.events.on_gui_elem_changed,
  },
  egm.manager.on_gui_input
)

script.on_init(function()
  -- check for LTN interface, just in case
  if not remote.interfaces[defs.remote.ltn] then
    error("LTN interface is not registered.")
  end
  if debug_mode then
    log2("Starting mod initialization for mod", defs.mod_name .. ".")
  end

  global.item_groups = {}
  global.statistics = {}
  global.temp_stats = {}
  cache_item_data(global.item_groups)

  for _, module in pairs(modules) do
    if module.on_init then
      module.on_init()
    end
  end
  register_events(modules)
  if debug_mode then
    log2("Initialization finished.")
  end
  log2("after on_init:", global)
end)

script.on_load(function()
  for _, module in pairs(modules) do
    if module.on_load then
      module.on_load()
    end
  end
  register_events(modules)
end)

script.on_configuration_changed(function(data)
  if not data then return end
  if not game.active_mods[defs.names.ltn] then
    error("LogisticTrainNetwork is required to run LTNT.")
  end
  cache_item_data(global.item_groups)
  for _, module in pairs(modules) do
    if module.on_configuration_changed then
      module.on_configuration_changed(data)
    end
  end
  log2("after on_configuration_changed:", global)
end)