-- constants
local NAME = "alert_tab"
local FRAME_WIDTH = require("ltnc.const").alert_tab.frame_width
local N_COLS = require("ltnc.const").alert_tab.n_columns
local COL_WIDTH_L = require("ltnc.const").alert_tab.col_width_l
local COL_WIDTH_R = require("ltnc.const").alert_tab.col_width_r

-- object creation
local GC = require("ui.classes.GuiComposition")
local gcAlertTab= GC(NAME, {
  params = {type = "flow", direction = "horizontal"},
  style = {visible = false},
})
gcAlertTab.tab_index = require("ltnc.const").alert_tab.tab_index

-- left side: table with stations
gcAlertTab:add{
  name = "frame_l",
  parent_name = "root",
  params = {type = "frame", direction = "vertical", caption = {"alert.frame_l_cap"}},
  style = {width = FRAME_WIDTH[1]}
}
gcAlertTab:add{
  name = "header_tb_l",
  parent_name = "frame_l",
  params =  {type = "table", column_count = N_COLS[1], cell_padding = 2},
}
for i = 1,N_COLS[1] do
  gcAlertTab:add{
    name = "header_l"..i,
    parent_name = "header_tb_l",
    params = {
      type = "label", 
      caption={"alert.header-col-l-"..i},
      style="ltnc_column_header"
    },
    style = {width = COL_WIDTH_L[i]}
  }    
end	
gcAlertTab:add{
  name = "table_l",
  parent_name = "frame_l",
  params =  {type = "table", column_count = N_COLS[1], draw_horizontal_lines = true, cell_padding = 2},
}
-- right side: table with trains
gcAlertTab:add{
  name = "frame_r",
  parent_name = "root",
  params = {type = "frame", direction = "vertical", caption = {"alert.frame_r_cap"}},
  style = {width = FRAME_WIDTH[2]}
}
gcAlertTab:add{
  name = "button",
  parent_name = "frame_r",
  params =  {type = "button", caption = "Check all trains", tooltip = "EXPERIMENTAL: Search all trains assigned to LTN depots for no-path and other errors states."},
  event = {id = defines.events.on_gui_click, handler = "check_trains"}
}
gcAlertTab:add{
  name = "header_tb_r",
  parent_name = "frame_r",
  params =  {type = "table", column_count = N_COLS[2]},
}
for i = 1,N_COLS[2] do
  gcAlertTab:add{
    name = "header_r"..i,
    parent_name = "header_tb_r",
    params = {
      type = "label", 
      caption={"alert.header-col-r-"..i},
      style="ltnc_column_header"
    },
    style = {width = COL_WIDTH_R[i]}
  }    
end	
gcAlertTab:element_by_name("header_r3").params.tooltip = {"alert.header-col-r-3-tt"}
gcAlertTab:element_by_name("header_r3").style.width = COL_WIDTH_R[3]+30
gcAlertTab:add{
  name = "table_r",
  parent_name = "frame_r",
  params =  {type = "table", column_count = N_COLS[2], draw_horizontal_lines = true, cell_padding = 2},
}

-- additional functions
local error_string = require("ltnc.const").ltn.error_string_lookup
local build_item_table = require("ui.util").build_item_table
local function build_route_label(parent, delivery) -- helper function for gcAlertTab:update
  if delivery then
    local inner_tb = parent.add{type = "table", column_count = 1}
    inner_tb.style.align = "center"
    inner_tb.style.cell_spacing = 0
    inner_tb.style.vertical_spacing = 0 
    local elem = inner_tb.add{
      type = "label",
      caption = delivery.from,
      style = "ltnc_label_default",
    } 
    elem.style.width = COL_WIDTH_R[1]
    elem = inner_tb.add{
      type = "label",
      caption = delivery.to,
      style = "ltnc_label_default",
    } 
    elem.style.width = COL_WIDTH_R[1]    
  else        
    local elem = parent.add{
    type = "label",
    caption = "unknown",
    style = "ltnc_label_default",
    } 
    elem.style.width = COL_WIDTH_R[1]         
  end     
end
function gcAlertTab:build_buttons(parent, index, train_id) -- helper function for gcAlertTab:update
  local inner_tb = parent.add{type = "table", column_count = 2, style = "slot_table"}
  --inner_tb.style.align = "center"
  --inner_tb.style.cell_spacing = 0
  --inner_tb.style.horizontal_spacing = 0  
  local elem = inner_tb.add{
    type = "sprite-button",
    sprite = "ltnc_sprite_enter",
    tooltip = {"alert.select-tt"},
    name = self:_create_name(index, "s" .. train_id),
  } 
  elem = inner_tb.add{
    type = "sprite-button",
    sprite = "ltnc_sprite_delete",
    tooltip = {"alert.delete-tt"},
    name = self:_create_name(index, "d" .. train_id),
  }
end

function gcAlertTab:update(pind, index)
  if index == self.tab_index then
    self:show(pind)
    global.gui.active_tab[pind] = index
    
    -- left side: table listing stops with error state
    local tb = self:get_el(pind, "table_l")
    tb.clear() 
    local index = #self.elem + 1
    for stop_id, stopdata in pairs(global.data.stops_error) do
      local elem = tb.add{
        type = "label",
        caption = stopdata.name,
        style = "ltnc_hoverable_label",
        name = self:_create_name(index, stop_id),
      }        
      elem.style.vertical_align = "center"
      elem.style.width = COL_WIDTH_L[1]
      index = index + 1
      elem = tb.add{
        type = "sprite-button",
        sprite = stopdata.signals.name,
        count = 1,
        enabled = false,
      }  
      elem = tb.add{type = "label", caption = error_string[stopdata.errorCode], style = "ltnc_label_default"} 
      elem.style.width = COL_WIDTH_L[3]
    end
    
    -- right side: table listing trains with residual items or error state
    tb = self:get_el(pind, "table_r")
    tb.clear()    
    for train_id, traindata in pairs(global.data.trains_error) do
      local delivery = traindata.last_delivery
      if delivery then -- train with residual items from its last delivery        
        build_route_label(tb, delivery)
        -- depot name
        local elem = tb.add{
          type = "label",
          caption = delivery.depot,
          style = "ltnc_label_default",
        } 
        elem.style.vertical_align = "center"
        elem.style.width = COL_WIDTH_R[2]      
        -- residual item overview
        build_item_table{
          parent = tb,
          requested = delivery.residuals[2],
          columns = 4,
          type = delivery.residuals[1],
          no_negate = true,
        } 
        self:build_buttons(tb, index, train_id)
        index = index + 1  
      else -- other errors
        build_route_label(tb, global.data.deliveries[train_id])
        local elem = tb.add{
          type = "label",
          caption = traindata.depot,
          style = "ltnc_label_default",
        } 
        elem.style.vertical_align = "center"
        elem.style.width = COL_WIDTH_R[2]     
        elem = tb.add{
          type = "label",
          caption = traindata.state,
          style = "ltnc_label_default",
        } 
        elem.style.font = "ltnc_font_bold"
        elem.style.width = COL_WIDTH_R[3]  
        elem.style.font_color = {r = 1, g = 0, b = 0}
        
        self:build_buttons(tb, index, train_id)
        index = index + 1  
      end    
    end    
  else
    self:hide(pind)
  end 
end

function gcAlertTab:event_handler(event, index, data_string)
  if data_string:sub(1, 1) == "s" then
    -- select train
    return "on_train_clicked", global.data.trains_error[tonumber(data_string:sub(2))].train
  elseif data_string:sub(1, 1) == "d" then
    -- remove train from error list
    global.data.trains_error[tonumber(data_string:sub(2))] = nil
    self:update(event.player_index, self.tab_index)
  else
    -- select stop
    return "on_error_stop_clicked"
  end
end

return gcAlertTab