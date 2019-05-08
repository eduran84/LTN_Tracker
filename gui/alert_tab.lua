local defs = defs
local egm = egm
local C = C
local styles = defs.styles.alert_tab
local build_item_table = util.build_item_table
local error_defs = defs.errors

egm.stored_functions[defs.functions.alert_sort .. 1] = function(a, b) return a.error_data.delivery.depot < b.error_data.delivery.depot end
egm.stored_functions[defs.functions.alert_sort .. 2] = function(a, b) return a.error_data.delivery.from < b.error_data.delivery.from end
egm.stored_functions[defs.functions.alert_sort .. 3] = function(a, b) return a.error_data.time < b.error_data.time end
egm.stored_functions[defs.functions.alert_sort .. 4] = function(a, b) return a.error_data.type < b.error_data.type end

egm.stored_functions[defs.functions.alert_row_constructor] = function(egm_table, data)
  local parent = egm_table.content
  local error_id = data.error_id
  local error_data = data.error_data
  local delivery = error_data.delivery
  -- depot name
  local elem = parent.add{
    type = "label",
    style = styles.label_col_1,
    caption = delivery.depot,
    tooltip = delivery.depot,
  }
  -- route name
  if delivery.to and delivery.from then
    local inner_flow = parent.add{
      type = "flow",
      direction = "vertical",
      style = defs.styles.shared.vertical_container,
    }
    local elem = inner_flow.add{
      type = "label",
      style = styles.label_col_2_hover,
      caption = delivery.from,
      tooltip = delivery.from,
    }
    egm.manager.register(elem, {
      action = defs.actions.station_name_clicked,
      name = delivery.from
    })
    elem = inner_flow.add{
      type = "label",
      style = styles.label_col_2_hover,
      caption = delivery.to,
      tooltip = delivery.to,
    }
    egm.manager.register(elem, {
      action = defs.actions.station_name_clicked,
      name = delivery.to
    })
  else
    local elem = parent.add{
      type = "label",
      style = styles.label_col_2,
      caption = "unknown",
    }
  end
  elem = parent.add{
    type = "label",
    style = styles.label_col_3,
    caption = error_data.time,
  }

  local error_type = error_data.type
  elem = parent.add{
    type = "label",
    style = styles.label_col_4,
    caption = error_defs[error_type].caption,
    tooltip = error_defs[error_type].tooltip,
  }
  local inner_flow = parent.add{type = "flow", direction = "vertical"}
  local enable_select_button = true
  if error_type == "train_invalid" then
    inner_flow.style.width = C.alert_tab.col_width[5]
    enable_select_button =  false
  else
    build_item_table{
      parent = inner_flow,
      provided = error_data.delivery.shipment,
      columns = 6,
      no_negate = true,
    }
  end
  if error_type == "residuals" then
    -- residual item overview
    build_item_table{
      parent = inner_flow,
      requested = error_data.cargo,
      columns = 6,
      no_negate = true,
    }
  elseif error_type == "incorrect_cargo" then
    -- cargo table
    build_item_table{
      parent = inner_flow,
      requested = error_data.cargo,
      columns = 6,
      no_negate = true,
    }
  end
  local button_flow = parent.add{type = "table", column_count = 2, style = "slot_table"}
  elem = button_flow.add{
    type = "sprite-button",
    style = defs.styles.shared.default_button,
    sprite = "utility/gps_map_icon",
    tooltip = {"alert.select-tt"},
    enabled = enable_select_button,
  }
  egm.manager.register(elem, {action = defs.actions.select_entity, entity = error_data.loco})

  elem = button_flow.add{
    type = "sprite-button",
    style = defs.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"alert.delete-tt"},
  }
  egm.manager.register(
    elem, {
      action = defs.actions.clear_single_alert,
      row_data = data,
      egm_table = egm_table,
    }
  )
end

local function build_alert_tab(window)
  local tab_index = defs.tabs.alert
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab5-caption"}})

  local table = egm.table.build(
    flow,
    {column_count = C.alert_tab.n_columns, draw_horizontal_lines = true},
    defs.functions.alert_row_constructor
  )
  for i = 1, C.alert_tab.n_columns - 2 do
    egm.table.add_column_header(table, {
        sortable = true,
        width = C.alert_tab.col_width[i],
        caption = {"alert.header-col-r-"..i},
      },
      defs.functions.alert_sort .. i
    )
  end
  table.root.children[1].add{
    type = "flow",
    style = defs.styles.shared.horizontal_spacer,
  }
  local button = table.root.children[1].add{
    type = "sprite-button",
    style = defs.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"alert.delete-all-tt"},
  }
  egm.manager.register(button, {action = defs.actions.clear_alerts, egm_table = table})
  return table
end

local function update_alert_tab(alert_tab, ltn_data)
  local error_list = ltn_data.trains_error
  egm.table.clear(alert_tab)
  if next(error_list) then
    for error_id, error_data in pairs(error_list) do
      egm.table.add_row(
        alert_tab,
        {error_id = error_id, error_data = error_data}
      )
    end
  else
    alert_tab.content.add{
      type = "label",
      caption = {"alert.no-error-trains"},
    }
  end
end

return {
  build = build_alert_tab,
  update = update_alert_tab,
}