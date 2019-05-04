local defs = defs
local egm = egm
local C = C
local styles = defs.styles.alert_tab
local build_item_table = util.build_item_table

egm.stored_functions[defs.functions.alert_sort .. 1] = function(a, b) return a.error_data.delivery.depot < b.error_data.delivery.depot end
egm.stored_functions[defs.functions.alert_sort .. 2] = function(a, b) return a.error_data.delivery.from < b.error_data.delivery.from end
egm.stored_functions[defs.functions.alert_sort .. 3] = function(a, b) return a.error_data.type < b.error_data.type end
-- TODO: make styles for labels with width included
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
  if delivery.to and delivery.from then
    local inner_flow = parent.add{
      type = "flow",
      direction = "vertical",
      style = defs.styles.shared.vertical_container,
    }
    local elem = inner_flow.add{
      type = "label",
      style = styles.label_col_2_hover,
      caption =delivery.from,
      tooltip = delivery.from,
    }
    elem = inner_flow.add{
      type = "label",
      style = styles.label_col_2_hover,
      caption = delivery.to,
      tooltip = delivery.to,
    }
  else
    local elem = parent.add{
      type = "label",
      style = styles.alert_col_2,
      caption = "unknown",
    }
  end
  local enable_select_button = true
  if error_data.type == "residuals" then
    local elem = parent.add{
      type = "label",
      style = styles.label_col_3,
      caption = {"error.train-leftover-cargo"},
      tooltip = {"error.train-leftover-cargo-tt"},
    }
    -- residual item overview
    elem = parent.add{type = "flow", direction = "vertical"}
    build_item_table{
      parent = elem,
      provided = error_data.delivery.shipment,
      columns = 6,
      no_negate = true,
    }
    build_item_table{
      parent = elem,
      requested = error_data.cargo[2],
      columns = 6,
      type = error_data.cargo[1],
      no_negate = true,
    }
  elseif error_data.type == "incorrect_cargo" then
    -- cargo table
    local elem = parent.add{
      type = "label",
      style = styles.label_col_3,
      caption = {"error.train-incorrect-cargo"},
      tooltip = {"error.train-incorrect-cargo-tt"},
    }
    elem = parent.add{type = "flow", direction = "vertical"}
    build_item_table{
      parent = elem,
      provided = error_data.delivery.shipment,
      columns = 6,
      no_negate = true,
    }
    build_item_table{
      parent = elem,
      requested = error_data.cargo,
      columns = 6,
      no_negate = true,
    }
  elseif error_data.type == "timeout" then
    local elem
    if error_data.delivery.pickupDone then
      elem = parent.add{
        type = "label",
        style = styles.label_col_3,
        caption = {"error.train-timeout-post-pickup"},
        tooltip = {"error.train-timeout-post-pickup-tt"},
      }
    else
      elem = parent.add{
        type = "label",
        style = styles.label_col_3,
        caption = {"error.train-timeout-pre-pickup"},
        tooltip = {"error.train-timeout-pre-pickup-tt"},
      }
    end
    build_item_table{
      parent = parent,
      provided = error_data.delivery.shipment,
      columns = 6,
      no_negate = true,
    }
  else
    --train invalid
    local elem = parent.add{
      type = "label",
      style = styles.label_col_3,
      caption = {"error.train-invalid"},
      caption = {"error.train-invalid-tt"},
    }
    elem = parent.add{type = "flow"}
    elem.style.width = C.alert_tab.col_width[4]
    enable_select_button =  false
  end
  local button_flow = parent.add{type = "table", column_count = 2, style = "slot_table"}
  elem = button_flow.add{
    type = "sprite-button",
    style = defs.styles.shared.default_button,
    sprite = "utility/gps_map_icon", --"ltnt_sprite_enter", --TODO: new sprite, add to defines
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
    {column_count = C.alert_tab.n_columns},
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

return {build_alert_tab, update_alert_tab}