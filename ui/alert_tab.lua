-- constants
local NAME = "alert_tab"
local FRAME_WIDTH = require("ltnt.const").alert_tab.frame_width
local N_COLS = require("ltnt.const").alert_tab.n_columns
local COL_WIDTH_L = require("ltnt.const").alert_tab.col_width_l
local COL_WIDTH_R = require("ltnt.const").alert_tab.col_width_r

-- object creation
local GC = require("ui.classes.GuiComposition")
local gcAlertTab= GC(NAME, {
  params = {type = "flow", direction = "horizontal"},
  style = {visible = false},
})
gcAlertTab.tab_index = require("ltnt.const").alert_tab.tab_index

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
      style="ltnt_column_header"
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
      style="ltnt_column_header"
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
local error_string = require("ltnt.const").ltn.error_string_lookup
local state_dict = require("ltnt.const").train_state_dict
local build_item_table = require("ui.util").build_item_table
local function build_route_labels(parent, route) -- helper function for gcAlertTab:update
  if route[2] and route[3] then
    local inner_tb = parent.add{type = "table", column_count = 1}
    inner_tb.style.align = "center"
    inner_tb.style.cell_spacing = 0
    inner_tb.style.vertical_spacing = 0
    local elem = inner_tb.add{
      type = "label",
      caption = route[2],
      style = "ltnt_label_default",
    }
    elem.style.width = COL_WIDTH_R[1]
    elem = inner_tb.add{
      type = "label",
      caption = route[3],
      style = "ltnt_label_default",
    }
    elem.style.width = COL_WIDTH_R[1]
  else
    local elem = parent.add{
    type = "label",
    caption = "unknown",
    style = "ltnt_label_default",
    }
    elem.style.width = COL_WIDTH_R[1]
  end
  -- depot name
  local elem = parent.add{
    type = "label",
    caption = route[1],
    style = "ltnt_label_default",
  }
  elem.style.vertical_align = "center"
  elem.style.width = COL_WIDTH_R[2]
end
function gcAlertTab:build_buttons(parent, index, loco_id, enabled) -- helper function for gcAlertTab:update
  local inner_tb = parent.add{type = "table", column_count = 2, style = "slot_table"}
  local elem = inner_tb.add{
    type = "sprite-button",
    sprite = "ltnt_sprite_enter",
    tooltip = {"alert.select-tt"},
    enabled = enabled,
    name = self:_create_name(index, "s" .. loco_id),
  }
  elem = inner_tb.add{
    type = "sprite-button",
    sprite = "ltnt_sprite_delete",
    tooltip = {"alert.delete-tt"},
    name = self:_create_name(index, "d" .. loco_id),
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
    if next(global.data.stops_error) then
      for stop_id, stopdata in pairs(global.data.stops_error) do
        local elem = tb.add{
          type = "label",
          caption = stopdata.name,
          style = "ltnt_hoverable_label",
          name = self:_create_name(index, stop_id),
        }
        elem.style.vertical_align = "center"
        elem.style.width = COL_WIDTH_L[1]
        index = index + 1
        build_item_table{parent = tb, signals = stopdata.signals, columns = 1}
        elem = tb.add{type = "label", caption = error_string[stopdata.errorCode], style = "ltnt_label_default"}
        elem.style.width = COL_WIDTH_L[3]
      end
    else
      local elem = tb.add{
        type = "label",
        caption = {"alert.no-error-stops"},
        style = "ltnt_label_default",
      }
    end

    -- right side: table listing trains with residual items or error state
    tb = self:get_el(pind, "table_r")
    tb.clear()
    if next(global.data.trains_error) then
      for train_id, error_data in pairs(global.data.trains_error) do
        build_route_labels(tb, error_data.route)
        if error_data.type == "residuals" then
          -- residual item overview
          build_item_table{
            parent = tb,
            requested = error_data.cargo[2],
            columns = 4,
            type = error_data.cargo[1],
            no_negate = true,
          }
          self:build_buttons(tb, index, train_id, true)
        elseif error_data.type == "timeout" then
          local elem = tb.add{
            type = "label",
            caption = {"error.train-timeout"},
            style = "ltnt_error_label",
          }
          elem.style.width = COL_WIDTH_R[3]
          self:build_buttons(tb, index, train_id, true)
        else
          --train invalid
          local elem = tb.add{
            type = "label",
            caption = {"error.train-invalid"},
            style = "ltnt_error_label",
          }
          elem.style.width = COL_WIDTH_R[3]
          self:build_buttons(tb, index, train_id, false)
        end
      end
      index = index + 1
    else
      local elem = tb.add{
        type = "label",
        caption = {"alert.no-error-trains"},
        style = "ltnt_label_default",
      }
    end
  else
    self:hide(pind)
  end
end

function gcAlertTab:event_handler(event, index, data_string)
  if data_string:sub(1, 1) == "s" then
    -- select train
    return "on_entity_clicked", global.data.trains_error[tonumber(data_string:sub(2))].loco
  elseif data_string:sub(1, 1) == "d" then
    -- remove train from error list
    global.data.trains_error[tonumber(data_string:sub(2))] = nil
    self:update(event.player_index, self.tab_index)
  else
    -- select stop
    return "on_error_stop_clicked"
  end
end
--test
return gcAlertTab