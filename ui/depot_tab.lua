local NAME = "depot_tab"
local DEPOT_CONST = require("ltnc.const").depot_tab
local N_COLS_LEFT = 3
local N_COLS_RIGHT = 3

local GC = require("ui.classes.GuiComposition")
local gcDepotTab= GC(NAME, {
  params = {type = "flow", direction = "horizontal"},
  style = {visible = false},
})
gcDepotTab.tab_index = DEPOT_CONST.tab_index

-- left pane with table header row
gcDepotTab:add{
  name = "frame_l",
  parent_name = "root",
  params = {
    type = "frame",
    caption = {"depot.frame-caption-left"},
    direction = "vertical",
  },
  style = {
    width = DEPOT_CONST.pane_width_left,
    left_padding = 0, right_padding = 0,
    top_padding = 0, bottom_padding = 0
  }  
}
gcDepotTab:add{
  name = "table_head_l",
  parent_name = "frame_l",
  params = {
    type = "table",
    column_count = N_COLS_LEFT,
    style = "table_with_selection",
  },
  style = {vertical_align = "center"},
}
for i = 1,N_COLS_LEFT do  
  gcDepotTab:add{
    name = "table_head_l_"..i,
    parent_name = "table_head_l",
    params = {
      type="label",
        caption={"depot.header-col-"..i},
        tooltip={"depot.header-col-"..i.."-tt"},
      style="ltnc_column_header",
      },    
    style = {width = DEPOT_CONST.col_width_left[i]},
  }
end
  
-- left pane main body
gcDepotTab:add{
  name = "pane_l",
  parent_name = "frame_l",
  params = {
    type = "scroll-pane",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space",
  }
}
gcDepotTab:add{
  name = "table_l",
  parent_name = "pane_l",
  params = {
    type = "table",
    column_count = N_COLS_LEFT,
    style = "table_with_selection",
  },
  style = {vertical_align = "center"},
}

-- right pane with table header row
gcDepotTab:add{
  name = "frame_r",
  parent_name = "root",
  params = {
    type = "frame",
    caption = {"depot.frame-caption-right", ""},
    direction = "vertical",
  },
  style = {
    width = DEPOT_CONST.pane_width_right,
    left_padding = 0, right_padding = 0,
    top_padding = 0, bottom_padding = 0
  }  
}
gcDepotTab:add{
  name = "table_head_r",
  parent_name = "frame_r",
  params = {
    type = "table",
    column_count = N_COLS_RIGHT,
    style = "table",
    draw_horizontal_lines = true
  },
  style = {vertical_align = "center"},
}
for i = 1,N_COLS_RIGHT do  
  gcDepotTab:add{
    name = "table_head_r_"..i,
    parent_name = "table_head_r",
    params = {
      type="label",
      caption={"depot.header-col-r-"..i},
      tooltip={"depot.header-col-r-"..i.."-tt"},
      style="ltnc_column_header",
      },    
    style = {width = DEPOT_CONST.col_width_right[i]},
    }
  end

-- right table main body
gcDepotTab:add{
  name = "pane_r",
  parent_name = "frame_r",
  params = {
    type = "scroll-pane",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space",
  }
}
gcDepotTab:add{
  name = "table_r",
  parent_name = "pane_r",
  params = {
    type = "table",
    column_count = N_COLS_RIGHT,
    style = "table",
    draw_horizontal_lines = true
  },
  style = {vertical_align = "center"},
}


-- overloaded methods
function gcDepotTab:on_init(storage_tb)
  GC.on_init(self, storage_tb)
  self.mystorage.selected_depot = self.mystorage.selected_depot or {}
end

-- additional methods
  
function gcDepotTab:event_handler(event, index, name_or_id)
  if tonumber(name_or_id) then -- stop name clicked, data_string is stop_id
    return "on_stop_name_clicked" -- send event back to gui_ctrl for handling
  else       
    if name_or_id:sub(1,1) == "%" then
      local depot_data = global.data.depots[self.mystorage.selected_depot[event.player_index]]
      local train_id = tonumber(name_or_id:match("%%(%d+)"))
      if train_id and depot_data then        
        return "on_train_clicked", depot_data.at[train_id]
      end     
    else
      -- depot name clicked, data_string is depot name
      self.mystorage.selected_depot[event.player_index] = name_or_id  
      self:show_details(event.player_index)
    end    
  end
  return nil
end

local format = string.format
function gcDepotTab:update(pind, index)
  if index == self.tab_index then
    self:show(pind)
    global.gui.active_tab[pind] = index
    local tb = self:get_el(pind, "table_l")
    tb.clear()
    -- table main body, left side
    local index = #self.elem + 1
    for depot_name, depot_data in pairs(global.data.depots) do
      -- first column: depot name
      local label = tb.add{
        type = "label",
        caption = depot_name,
        style = "ltnc_hover_bold_label",
        name = self:_create_name(index, depot_name),
      }        
      label.style.width = DEPOT_CONST.col_width_left[1]
      index = index+1
      
      -- second column: number of trains
      label = tb.add{
        type = "label",
        caption = depot_data.n_parked .. "/" .. depot_data.n_all_trains,
        style = "ltnc_label_default",
      }        
      label.style.width = DEPOT_CONST.col_width_left[2]
      
      -- third column: capacity
      label = tb.add{
        type = "label",
        caption =  format("%d stacks + %dk fluid", depot_data.cap,  depot_data.fcap/1000),
        style = "ltnc_label_default",
      }        
      label.style.width = DEPOT_CONST.col_width_left[3]      
    end
    self:show_details(pind)
  else
    self:hide(pind)
  end 
end

local build_train_composition_string = require("ltnc.util").build_train_composition_string
local train_state_dict = require("ltnc.const").train_state_dict
local build_item_table = require("ui.util").build_item_table

function gcDepotTab:show_details(pind)
  local depot_name = global.gui[self.name].selected_depot[pind]
  if not depot_name then return end
  self:get_el(pind, "frame_r").caption = {"depot.frame-caption-right", depot_name}
  local data = global.data
  local depot_data = data.depots[depot_name]
  local tb = self:get_el(pind, "table_r")
  tb.clear()
  
  -- table main body, right side
  -- list all trains assigned to the depot
  local index = #self.elem + 1 
  for train_id, train in pairs(depot_data.at) do 
    if train.valid then
      local comp = build_train_composition_string(train)
      -- first column: train composition
      local label = tb.add{
        type = "label",
        caption = comp,
        style = "ltnc_hover_bold_label",
        name = self:_create_name(index, "%" .. train_id),  
      }       
      label.style.width = DEPOT_CONST.col_width_right[1]
      label.style.vertical_align = "center"
      label.style.height = 38
      
      -- figure out train status
      local status = train_state_dict[train.state]
      local current_record = train.schedule.current
      local label_txt_1, label_txt_2, color
      -- the indexing here is a mess, as are the if statements !TODO: clean up
      if status.code == -1 or current_record > 3 then -- thats an error
        label_txt_1 = current_record >3 and "not LTN controlled" or status.msg
        color = DEPOT_CONST.color_dict[2]
      elseif  current_record == 1 then -- returning to or parking at depot
        label_txt_1 = DEPOT_CONST.depot_msg_dict[status.code]
        color = DEPOT_CONST.color_dict[status.code+1]
      else -- on delivery
        label_txt_1 = DEPOT_CONST.delivery_msg_dict[status.code+current_record-1]
        label_txt_2 = train.schedule.records[current_record].station
        color = DEPOT_CONST.color_dict[3]
      end
      label.style.font_color = color -- update color for first column
      
      -- second column: train status / current route
      local flow = tb.add{type = "table", column_count = 1}
      flow.style.align = "center"
      flow.style.cell_spacing = 0
      flow.style.vertical_spacing = 0
      label = flow.add{
        type = "label",
        caption = label_txt_1,
        style = "ltnc_label_default",    
      }        
      label.style.width = DEPOT_CONST.col_width_right[2]
      label.style.font_color = color
      if label_txt_2 then
        index = index + 1
        label = flow.add{
          type = "label",
          caption = label_txt_2,
          style = "ltnc_hover_bold_label",
          name = self:_create_name(index, data.name2id[label_txt_2]),    
        }        
        label.style.width = DEPOT_CONST.col_width_right[2]
      end
      
      -- third column: shipment or residual items
      if data.trains_error[train.id] then
        local residuals = data.trains_error[train.id].last_delivery.residuals
        if residuals and next(residuals) then
          label = build_item_table{
            parent = tb,
            requested = residuals[2],
            columns = 5,
            type = residuals[1],
            no_negate = true,
          } 
          label.style.vertical_align = "top"
          label.style.horizontally_stretchable = false
        end
      elseif data.deliveries[train.id] then
        build_item_table{parent = tb, provided = data.deliveries[train.id].shipment, columns = 5}
      else
        -- empty label, otherwise table is misaligned
        label = tb.add{
          type = "label",
          caption = "",
          style = "ltnc_label_default",
        } 
      end
    end -- if train.valid then
  end   -- for _, train in pairs(depot_data.all_trains) do   
end


return gcDepotTab