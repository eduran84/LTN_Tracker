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
  style = {vertical_align = "center", horizontal_spacing = 0},
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
    style = {width = DEPOT_CONST.col_width_header_left[i]},
  }
end

-- left pane main body
gcDepotTab:add{
  name = "pane_l",
  parent_name = "frame_l",
  params = {
    type = "scroll-pane",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto",---and-reserve-space",
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
    vertical_scroll_policy = "auto",
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
gcDepotTab:add{
  name = "desc",
  parent_name = "table_r",
  params = {type = "label", caption = {"depot.init-note"}, style = "ltnc_label_default"},
  style = {single_line = false, width = DEPOT_CONST.pane_width_right - 50},
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
      local train_index = tonumber(name_or_id:match("%%(%d+)"))
      if train_index and depot_data then
        return "on_train_clicked", depot_data.all_trains[train_index]
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
  local index = #self.elem
  for train_index, train in pairs(depot_data.all_trains) do
    if train.valid then
      index = index + 1
      local comp = build_train_composition_string(train)
      -- first column: train composition
      local label = tb.add{
        type = "label",
        caption = comp,
        style = "ltnc_hover_bold_label",
        name = self:_create_name(index, "%" .. train_index),
      }
      label.style.width = DEPOT_CONST.col_width_right[1]
      label.style.vertical_align = "center"
      label.style.height = 38

      -- figure out train status
      local label_txt_1, label_txt_2, state, color
      local train_id = train.id
      if depot_data.parked_trains[train_id] then
        label_txt_1 = {"depot.parked"}
        color = DEPOT_CONST.color_dict[1]
        state = 0
      elseif data.deliveries[train_id] then
        if train.schedule.current  == 1 then
          -- assigned for delivery, but has not left yet
          label_txt_1 = {"depot.parked"}
          color = DEPOT_CONST.color_dict[3]
        else
          -- display current delivery status
          local delivery = data.deliveries[train_id]
          if delivery.pickupDone then
            label_txt_1 = (train.state == defines.train_state.wait_station) and {"depot.unloading"} or {"depot.dropping-off"}
            label_txt_2 = delivery.to
          else
            label_txt_1 = (train.state == defines.train_state.wait_station) and {"depot.loading"} or {"depot.picking-up"}
            label_txt_2 = delivery.from
          end
          color = DEPOT_CONST.color_dict[3]
        end
        state = 1
      elseif data.trains_error[train_id] then
        --display errors state
        state = data.trains_error[train_id].state
        label_txt_1 = train_state_dict[state]
        color = DEPOT_CONST.color_dict[2]
      else
        -- train returning to depot is the only option left
        label_txt_1 = {"depot.returning"}
        color = DEPOT_CONST.color_dict[3]
        state = 0
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
        label = flow.add{
          type = "label",
          caption = label_txt_2,
          style = "ltnc_hover_bold_label",
          name = self:_create_name(index, data.name2id[label_txt_2]),
        }
        label.style.width = DEPOT_CONST.col_width_right[2]
      end

      -- third column: shipment or residual items
      if state == 0 then
        -- empty label, otherwise table is misaligned
        label = tb.add{
          type = "label",
          caption = "",
          style = "ltnc_label_default",
        }
      elseif state == 1 then
        build_item_table{parent = tb, provided = data.deliveries[train.id].shipment, columns = 5}
      elseif state == -100 then
        local residuals = data.trains_error[train_id].cargo
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
      else
        -- empty label, otherwise table is misaligned
        label = tb.add{
          type = "label",
          caption = train_state_dict[state],
          style = "ltnc_label_default",
        }
      end
    end -- if train.valid then
  end   -- for _, train in pairs(depot_data.all_trains) do
end


return gcDepotTab