----------------------
------ pre init ------
----------------------

-- localize helper functions
local s2n = tonumber
local match = string.match
local mod_gui = require("mod-gui")

-- load / set constants
local N_TABS = 0
local gc_pathes = {   -- list of GUIComposition objects to load
  "ui.toggle_button",
  "ui.outer_frame",
  "ui.depot_tab",
  "ui.history_tab", 
  "ui.inventory_tab",
  "ui.station_tab",
  "ui.alert_tab",
}
-- load and store GuiComposition objects
local GC = {} 
local tab_list = {}
for _,path in pairs(gc_pathes) do
  local gc = require(path)
  out.assert(not(GC[gc.name]), "GuiComposition object with name", gc.name, "does already exist.")
  GC[gc.name] = gc
  for _,sub_gc in pairs(gc.sub_gc) do
    out.assert(not(GC[sub_gc.name]), "GuiComposition object with name", sub_gc.name, "does already exist.")
    GC[sub_gc.name] = sub_gc
  end
  if gc.tab_index then
    out.assert(not tab_list[gc.tab_index], "Tab index", gc.tab_index, "is already registerd by another GC object.\ntab_list =", tab_list)
    tab_list[gc.tab_index] = gc
    N_TABS = N_TABS + 1
  end
end

-----------------------------
------ initialization  ------
-----------------------------
-- do not change any of the variables defined above from this point onward
-- enforced by desync

local function on_load()
  for _,gc in pairs(GC) do
    -- restore local references to objects' global storage tables
    gc:on_load(global.gui)
  end  
end

local function player_init(pind)
  local player = game.players[pind]
  local frame_flow = mod_gui.get_frame_flow(player)
  local button_flow = mod_gui.get_button_flow(player)  
  if debug_level > 0 then
    out.info("gui_ctrl.lua", "Preparing UI for player", player.name)
  end
  
  -- set UI state globals
  global.gui.active_tab[pind] = 1 -- even if ui is closed, active tab persists and is restored when UI opens
  global.gui.is_gui_open[pind] = false
  global.gui.last_refresh_tick[pind] = 0
  
  -- build UI
  GC.toggle_button:build(button_flow, pind)
  if not settings.get_player_settings(player)["ltnc-show-button"] then
    GC.toggle_button:hide(player)
  end  
  GC.outer_frame:build(frame_flow, pind)
  GC.outer_frame:hide(pind) -- UI is always closed on init
  
  -- add tabs to outer_frame
  local outer_frame = GC.outer_frame:get(pind)
  GC.depot_tab:build(outer_frame, pind)
  GC.stop_tab:build(outer_frame, pind)
  GC.inv_tab:build(outer_frame, pind) 
  GC.hist_tab:build(outer_frame, pind) 
  GC.alert_tab:build(outer_frame, pind)
  if debug_level > 0 then
    out.info("gui_ctrl.lua", "UI is ready.")
  end
end

local function on_init() 
  -- global storage for UI state
  global.gui = {is_gui_open = {}, active_tab = {}, last_refresh_tick = {}, alerts_enabled = {}} 
  for _,gc in pairs(GC) do
    -- creates and populates global.gui[gc.name]
    gc:on_init(global.gui)
  end  
  -- initialize present players, they dont trigger on_player_created event
  for pind,_ in pairs(game.players) do
    player_init(pind)
  end
end

local function on_configuration_changed()
  -- wipe existing UIs and clear global UI storage...
  for pind,_ in pairs(game.players) do
    for name, gc in pairs(GC) do
      gc:destroy(pind)
    end        
  end   
  global.gui = nil
  -- ... and rebuild
  on_init()
end

------------------------------
--- RUNTIME EVENT HANDLERS ---
------------------------------

local function setting_changed(pind, setting)
  local player = game.players[pind]
  if setting == "ltnc-window-height" then
    player_init(pind) -- rebuild entire ui for player
  elseif setting == "ltnc-show-button" then 
    -- show or hide toggle button
    if settings.get_player_settings(player)["ltnc-show-button"].value then
      GC.toggle_button:show(pind)
    else
      GC.toggle_button:hide(pind)
    end    
  end
end

-- basic UI functions
local function update_tab(pind)
  -- updates the currently selected tab for one player, if that player has the UI open  
  local tab_index = global.gui.is_gui_open[pind] and global.gui.active_tab[pind]
  if tab_index then
    for i = 1,N_TABS do
      tab_list[i]:update(pind, tab_index)
    end
  end  
end

local function on_toggle_button_click(event)
  if GC.outer_frame:toggle(event.player_index) then
    GC.toggle_button:clear_alert(event.player_index)  
    update_tab(event.player_index)	    
  end
end

local function close_gui(pind)
	GC.outer_frame:hide(pind)
end

-- handler for all events defined in global constant GUI_EVENTS
-- calls the appropriate handler for the given event
-- available handlers are stored in handlers table
local match_string = MOD_PREFIX.."_([%a_]+)(%d+)_?(.*)"
--local match_ui_name function(element_name) return match(element_name, ms) end
local handlers = {on_toggle_button_click = on_toggle_button_click}

local function ui_event_handler(event)
  -- check element name; pattern used by all GuiComposition objects is
  -- "ltnc_<name of GC object>_<index of element in the GC object>_<[optional]any string>"
  local gc_name, elem_index, data_string = match(event.element.name, match_string)
  if gc_name then -- this element belongs to ltnc, so continue (or some other mod with the same prefix xX)
    if debug_level > 1 then
      out.info("ui_event_handler", "Gui event received. Event:", event, "\ngc_name =", gc_name, "elem_index =", elem_index, "data_string=", data_string) 
    end    
    if GC[gc_name] then -- should not be necessary, but let's be extra safe in case another mod uses exactly the same naming pattern
      local handler, data = GC[gc_name]:get_event_handler(event, s2n(elem_index), data_string)      
      if debug_level > 2 then -- !DEBUG
        out.info("ui_event_handler", "handler:", handler, "data:", data, "\nfull GC object state:\n", GC[gc_name]) 
      end  
      if type(handler) == "string" then 
        if data then
          handlers[handler](event, data)
        else          
          handlers[handler](event, data_string)
        end
      end
    else
      if debug_level > 0 then
        out.warn("Gui event registerd for UI element with name", event.element.name, ", but corresponding GC object was not found.\nCurrent state of GC:\n", GC, "\nTriggering event:", event)
      end      
    end    
  end
end

-- handler for on_data_updated event
local function update_ui(event)
  for i in pairs(game.players) do    
    update_tab(i)
  end
end

-- handler for on_gui_closed event
local function on_ui_closed(event)
  -- event triggers whenever any UI element is closed, so check if it is actually the LTNC UI that is supposed to close
	if event.element and event.element.valid and event.element.index == GC.outer_frame:get(event.player_index).index then
    close_gui(event.player_index)
	end
end

-- handler for on_new_alert custom event
local function on_new_alert(event)
  if event and event.type and event.type == "residuals" then
    for pind, p in pairs(game.players) do
      GC.toggle_button:set_alert(pind)   
      GC.outer_frame:set_alert(pind)
    end    
  end
end

-- event handlers called by ctrl.gui_event_handler
function handlers.on_tab_changed(event, data_string)
  -- data string is index of clicked tab button
  GC.outer_frame:update_buttons(event.player_index, s2n(data_string))
  update_tab(event.player_index)
end

local MINIMAL_REFRESH_DELAY = require("ltnc.const").ui_ctrl.refresh_delay
function handlers.on_refresh_bt_click(event, data_string)
  local pind = event.player_index
  if global.gui.last_refresh_tick[pind] + MINIMAL_REFRESH_DELAY < game.tick then
    update_tab(event.player_index)
  end  
end

-- and even more helper functions
local select_entity = require("ltnc.util").select_entity
local select_train = require("ltnc.util").select_train

function handlers.on_stop_name_clicked(event, data_string)
  local stop = global.data.stops[s2n(data_string)]
  if stop and stop.entity and stop. entity.valid then
    close_gui(event.player_index)
    select_entity(event.player_index, global.data.stops[s2n(data_string)].entity)
  end  
end

function handlers.on_error_stop_clicked(event, data_string)
  local stop = global.data.stops_error[s2n(data_string)]
  if stop and stop.entity and stop. entity.valid then
    close_gui(event.player_index)
    select_entity(event.player_index, global.data.stops_error[s2n(data_string)].entity)
  end
end

function handlers.on_train_clicked(event, train)
  if train and train.valid then
    close_gui(event.player_index)
    select_train(event.player_index, train)	
  end  
end

function handlers.on_item_clicked(event, data_string)
  -- set item displayed on details tab
  -- item name and amount is encoded in data_string
  GC.inv_details:set_item(event.player_index, data_string)
end

-- !TODO this does not belong here, integrate into data processing
local state_dict = require("ltnc.const").train_state_dict
function handlers.check_trains(event, data_string)
  local trains_error = global.data.trains_error
  for train_id, train_data in pairs(trains_error) do
    if not train_data.last_delivery then
      trains_error[train_id] = nil
    end
  end  
  for depot_name, depot_data in pairs(global.data.depots) do
    for train_id, train in pairs(depot_data.at) do
      local state = state_dict[train.state]
      if state.code == -1 then
        trains_error[train_id] = trains_error[train_id] or {}
        trains_error[train_id].train = train
        trains_error[train_id].state = state.msg
        trains_error[train_id].depot = depot_name
      end
    end
  end
  update_tab(event.player_index)
end

return {
  on_init = on_init,
  on_load = on_load,
  on_configuration_changed = on_configuration_changed,
  on_toggle_button_click = on_toggle_button_click,
  setting_changed = setting_changed,
  player_init = player_init,
  ui_event_handler = ui_event_handler,
  on_ui_closed = on_ui_closed,
  on_new_alert = on_new_alert,
  update_ui = update_ui,
  }