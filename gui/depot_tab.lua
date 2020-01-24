local defs = defs
local egm = egm
local C = C
local styles = defs.styles.depot_tab

local DEPOT_CONST = C.depot_tab
local column_count_table_right = 3

local build_item_table = util.gui.build_item_table

egm.stored_functions[defs.functions.depot_row_constructor] = function(egm_table, data)
  local parent = egm_table.content
  -- first column: train composition
  local label = parent.add{
    type = "label",
    caption = data.composition,
    style = styles.label_col_1,
  }
  label.style.font_color = data.color
  if data.locomotive then
    egm.manager.register(label, {
        action = defs.actions.select_entity,
        entity = data.locomotive,
      }
    )
  end
  -- second column: train status / current route
  local flow = parent.add{
    type = "flow",
    style = defs.styles.shared.vertical_container,
    direction = "vertical"
  }
  label = flow.add{
    type = "label",
    caption = data.label_txt_1,
    style = styles.label_col_2,
  }
  label.style.font_color = data.color
  local label_txt_2 = data.label_txt_2
  if label_txt_2 then
    label = flow.add{
      type = "label",
      caption = label_txt_2,
      style = styles.label_col_2_bold,
    }
    egm.manager.register(
      label, {
        action = defs.actions.station_name_clicked,
        name = label_txt_2
      }
    )
  end
  -- third column: shipment
  if data.shipment then
    build_item_table{
      parent = parent,
      provided = data.shipment,
      columns = 3,
      max_rows = 2,
    }
  else
    -- empty label, otherwise table is misaligned
    label = parent.add{
      type = "label",
      caption = "",
    }
  end
end

egm.stored_functions[defs.functions.depot_sort .. 1] = function(a, b) return a.composition < b.composition end
egm.stored_functions[defs.functions.depot_sort .. 2] = function(a, b) return a.col_2_sort_rank < b.col_2_sort_rank end

local function build_depot_tab(window)
  local tab_index = defs.tabs.depot
  local depot_tab = {}
  local flow = egm.tabs.add_tab(
    window.pane,
    tab_index,
    {caption = {"ltnt.tab1-caption"}, direction = "horizontal"}
  )
  flow.style.horizontal_spacing = 0
  depot_tab.root = flow
  local frame_left = flow.add{
    type = "frame",
    style = defs.styles.shared.no_padding_frame,
    caption = {"depot.frame-caption-left"},
    direction = "vertical",
  }

  frame_left.style.width = DEPOT_CONST.pane_width_left
  local pane_left = frame_left.add{
    type = "scroll-pane",
    style = defs.styles.shared.no_frame_scroll_pane,
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space",
  }
  depot_tab.pane_left = pane_left

  local frame_right = flow.add{
    type = "frame",
    style = defs.styles.shared.no_padding_frame,
    caption = {"depot.frame-caption-right", ""},
    direction = "vertical",
  }
  frame_right.style.width = 548
  depot_tab.frame_right = frame_right

  local table = egm.table.build(
    frame_right,
    {column_count = column_count_table_right},
    defs.functions.depot_row_constructor
  )
  for i = 1, column_count_table_right do
    egm.table.add_column_header(table, {
        sortable = (i ~= 3),
        width = DEPOT_CONST.col_width_right[i],
        caption={"depot.header-col-r-"..i},
        tooltip={"depot.header-col-r-"..i.."-tt"},
      },
      defs.functions.depot_sort .. i
    )
  end
  depot_tab.table_right = table
  return depot_tab
end

local get_composition_string = util.get_train_composition_string
local get_locomotive = util.get_main_locomotive
local function update_details_view(depot_tab, ltn_data)
  local depot_data = ltn_data.depots[depot_tab.selected_depot]
  if not depot_data then return end
  local depot_name = depot_tab.selected_depot
  if not depot_name then return end
  depot_tab.frame_right.caption = {"depot.frame-caption-right", depot_name}
  local table = depot_tab.table_right
  egm.table.clear(table)
  -- list all trains assigned to the depot
  for train_index, train in pairs(depot_data.all_trains) do
    if train.valid then
      local composition, counts = get_composition_string(train)
      local locomotive = get_locomotive(train)
      -- figure out train status
      local label_txt_1, label_txt_2, shipment, color, sort_rank
      local train_id = train.id
      if depot_data.parked_trains[train_id] then
        label_txt_1 = {"depot.parked"}
        color = DEPOT_CONST.color_dict[1]
        sort_rank = 0
      elseif ltn_data.deliveries[train_id] then
        if train.schedule.current  == 1 then
          -- assigned for delivery, but has not left yet
          label_txt_1 = {"depot.parked"}
          color = DEPOT_CONST.color_dict[3]
          sort_rank = 1
        else
          -- display current delivery status
          local delivery = ltn_data.deliveries[train_id]
          if delivery.pickupDone then
            label_txt_1 = (train.state == defines.train_state.wait_station) and {"depot.unloading"} or {"depot.dropping-off"}
            label_txt_2 = delivery.to
            sort_rank = 2
          else
            label_txt_1 = (train.state == defines.train_state.wait_station) and {"depot.loading"} or {"depot.picking-up"}
            label_txt_2 = delivery.from
            sort_rank = 3
          end
          color = DEPOT_CONST.color_dict[3]
        end
        shipment = ltn_data.deliveries[train.id].shipment
      else
        -- train returning to depot is the only option left
        label_txt_1 = {"depot.returning"}
        color = DEPOT_CONST.color_dict[3]
        sort_rank = 4
      end
      egm.table.add_row_data(table, {
        locomotive = locomotive,
        depot_data = depot_data,
        composition = composition,
        col_2_sort_rank = sort_rank,
        shipment = shipment,
        label_txt_1 = label_txt_1,
        label_txt_2 = label_txt_2,
        color = color,
      })
    end
  end
  egm.table.sort_rows(table)
end

local function update_depot_tab(depot_tab, ltn_data)
  local pane_left = depot_tab.pane_left
  egm.manager.unregister(pane_left)
  pane_left.clear()
  local build_depot_button = util.gui.build_depot_button
  for depot_name, depot_data in pairs(ltn_data.depots) do
    local button = build_depot_button(pane_left, depot_name, depot_data)
    egm.manager.register(
      button, {
        action = defs.actions.show_depot_details,
        depot_name = depot_name,
        depot_tab = depot_tab,
        ltn_data = ltn_data,
      }
    )
  end
  update_details_view(depot_tab, ltn_data)
end

egm.manager.define_action(
  defs.actions.show_depot_details,
  function(event, data)
    data.depot_tab.selected_depot = data.depot_name
    update_details_view(data.depot_tab, data.ltn_data)
  end
)

return {
  build = build_depot_tab,
  update = update_depot_tab,
}