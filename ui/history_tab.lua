-- localize helper functions
local build_item_table = require("ui.util").build_item_table
local tick2timestring = require("ltnc.util").tick2timestring

-- set/get constants
local N_COLS = require("ltnc.const").history_tab.n_columns
local COL_WIDTH = require("ltnc.const").history_tab.col_width
local H_COL_WIDTH = require("ltnc.const").history_tab.header_col_width
local HISTORY_LIMIT = require("ltnc.const").proc.history_limit
local NAME = "hist_tab"

local gcHistTab = require("ui.classes.GuiComposition")(NAME, {
  params = {type = "flow", direction = "vertical"},
  style = {visible = false},
})

-- header row
gcHistTab:add{
  name = "header_table",
  parent_name = "root",
  params = {
    type = "table",
    column_count = N_COLS+1,
    style = "table_with_selection"
  }
}   
for i = 1,N_COLS do
  gcHistTab:add{
    name = "header"..i,
    parent_name = "header_table",
    params = {
      type = "label",
      caption = {"history.header-col-"..i},
      tooltip = {"history.header-col-"..i.."-tt"},
      style = "ltnc_column_header"
    },
    style = {width = H_COL_WIDTH[i]}
  }    
end	 

-- main table
gcHistTab:add{name = "pane", parent_name = "root", params = {type = "scroll-pane"}}
gcHistTab:add{
  name = "table", 
  parent_name = "pane",
  params = {
    type = "table",
    column_count = N_COLS,
    caption = {"history.table-caption"},
    style = "table_with_selection",
  },
  style = {vertical_align = "center"}
}
gcHistTab.tab_index = require("ltnc.const").history_tab.tab_index

-- overloaded methods
function gcHistTab:event_handler(event, index, data_string)
  return "on_stop_name_clicked"
end

-- additional methods
function gcHistTab:update(pind, index)
  if index == self.tab_index then
    self:show(pind)
    global.gui.active_tab[pind] = index
    local hist_table = self:get_el(pind, "table")
    local history_data = global.data.delivery_hist
    hist_table.clear()
    
    ---- repopulate table ----	
    local offset = global.data.newest_history_index
    for i = -1, -99, -1 do    
      -- start at (offset - 1), counting down
      -- on reaching 0, jump back up to HISTORY_LIMIT
      -- this allows reuse of the array without table inserts or deletions
      local delivery = history_data[(i + offset > 0) and (i + offset) or (i + offset + 100)]
      if delivery then
        -- involved stops and depot
        local label = hist_table.add{
          type = "label",
          caption = delivery.from,
          style = "ltnc_label_default"
        }
        label.style.width = COL_WIDTH[1]
        label = hist_table.add{
          type = "label",
          caption = delivery.to,
          style = "ltnc_label_default"
        }
        label.style.width = COL_WIDTH[2]
        label = hist_table.add{
          type = "label",
          caption = delivery.depot,
          style = "ltnc_label_default"
        }
        label.style.width = COL_WIDTH[3]
        
        -- runtime, possibly with time-out warning
        if delivery.timed_out then
          local inner_tb = hist_table.add{type = "table", column_count = 1, style = "slot_table"}      
          label = inner_tb.add{
            type = "label",
            caption = tick2timestring(delivery.runtime),
          }
          label.style.width = COL_WIDTH[4]
          label.style.align = "right"
          label.style.font_color = {r = 1, g = 0, b = 0}
          label = inner_tb.add{
            type = "label",
            caption = "timed out",    -- !TODO localize
          }
          label.style.width = COL_WIDTH[4]
          label.style.align = "right"
          label.style.font_color = {r = 1, g = 0, b = 0}          
          
        else            
          label = hist_table.add{
            type = "label",
            caption = tick2timestring(delivery.runtime),
          }
          label.style.width = COL_WIDTH[4]
          label.style.align = "right"
        end      
        
        -- shipement and residual items, if any
        if delivery.residuals then
          local tb = hist_table.add{type = "table", column_count = 1}
          tb.style.align = "center"
          tb.style.cell_spacing = 0
          tb.style.vertical_spacing = 0 
          
          build_item_table{parent = tb, provided = delivery.shipment, columns = 5}        
          build_item_table{
            parent = tb,
            requested = delivery.residuals[2],
            columns = 5,
            type = delivery.residuals[1],
            no_negate = true,
          }      
        else
          build_item_table{parent = hist_table, provided = delivery.shipment, columns = 5}
        end -- if delivery.residuals then
      end --if delivery then
    end -- for i = -1, -99, -1 do  
  else
    self:hide(pind)
  end -- if index == self.tab_index then 
end

return gcHistTab
