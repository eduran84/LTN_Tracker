local defs = defs
local egm_defs = require("__GUI_Modules__.defines")
local egm = egm
local C = C
local col_width = C.alert_tab.col_width
local build_item_table = util.build_item_table

egm.stored_functions[defs.names.functions.alert_sort .. 1] = function(a, b) return a.error_data.delivery.depot < b.error_data.delivery.depot end
egm.stored_functions[defs.names.functions.alert_sort .. 2] = function(a, b) return a.error_data.delivery.from < b.error_data.delivery.from end
egm.stored_functions[defs.names.functions.alert_sort .. 3] = function(a, b) return a.error_data.type < b.error_data.type end

egm.stored_functions[defs.names.functions.alert_row_constructor] = function(parent, data)
  local error_id = data.error_id
  local error_data = data.error_data
  local delivery = error_data.delivery
  -- depot name
  local elem = parent.add{
    type = "label",
    caption = delivery.depot,
    tooltip = delivery.depot,
    style = "ltnt_label_default",
  }
  elem.style.vertical_align = "center"
  elem.style.width = col_width[1]
  if delivery.to and delivery.from then
    local inner_tb = parent.add{type = "table", column_count = 1}
    inner_tb.style.horizontal_align = "center"
    inner_tb.style.horizontal_spacing = 0
    inner_tb.style.vertical_spacing = 0

    local elem = inner_tb.add{
      type = "label",
      caption =delivery.from,
      tooltip = delivery.from,
      style = "ltnt_hoverable_label",
    }
    elem.style.width = col_width[2]
    elem = inner_tb.add{
      type = "label",
      caption = delivery.to,
      tooltip = delivery.to,
      style = "ltnt_hoverable_label",
    }
    elem.style.width = col_width[2]
  else
    local elem = parent.add{
    type = "label",
    caption = "unknown",
    style = "ltnt_label_default",
    }
    elem.style.width = col_width[2]
  end
  local enable_select_button = true
  if error_data.type == "residuals" then
    local elem = parent.add{
      type = "label",
      caption = {"error.train-leftover-cargo"},
      tooltip = {"error.train-leftover-cargo-tt"},
      style = "ltnt_error_label",
    }
    elem.style.width = col_width[3]
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
      caption = {"error.train-incorrect-cargo"},
      tooltip = {"error.train-incorrect-cargo-tt"},
      style = "ltnt_error_label",
    }
    elem.style.width = col_width[3]
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
        caption = {"error.train-timeout-post-pickup"},
        tooltip = {"error.train-timeout-post-pickup-tt"},
        style = "ltnt_error_label",
      }
    else
      elem = parent.add{
        type = "label",
        caption = {"error.train-timeout-pre-pickup"},
        tooltip = {"error.train-timeout-pre-pickup-tt"},
        style = "ltnt_error_label",
      }
    end
    elem.style.width = col_width[3]
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
      caption = {"error.train-invalid"},
      caption = {"error.train-invalid-tt"},
      style = "ltnt_error_label",
    }
    elem.style.width = col_width[3]
    elem = parent.add{type = "flow"}
    elem.style.width = col_width[4]
    enable_select_button =  false
  end
  local button_flow = parent.add{type = "table", column_count = 2, style = "slot_table"}
  elem = button_flow.add{
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = "ltnt_sprite_enter",
    tooltip = {"alert.select-tt"},
    enabled = enable_select_button,
  }
  egm.manager.register(elem, {action = defs.names.actions.select_entity, entity = error_data.loco})

  elem = button_flow.add{
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"alert.delete-tt"},
  }
  egm.manager.register(
    elem, {
      action = defs.names.actions.clear_single_alert,
      row_data = data,
      egm_table = data.egm_table
    }
  )
end

local function build_alert_tab(window, tab_index)
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab5-caption"}})
  local table = egm.table.build(
    flow,
    {column_count = C.alert_tab.n_columns},
    defs.names.functions.alert_row_constructor
  )
  for i = 1, C.alert_tab.n_columns - 2 do
    egm.table.add_column_header(table, {
        sortable = true,
        width = C.alert_tab.col_width[i],
        caption = {"alert.header-col-r-"..i},
      },
      defs.names.functions.alert_sort .. i
    )
  end
  table.root.children[1].add{
    type = "flow",
    style = egm_defs.style_names.shared.horizontal_spacer,
  }
  local button = table.root.children[1].add{
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"alert.delete-all-tt"},
  }
  egm.manager.register(button, {action = defs.names.actions.clear_alerts, egm_table = table})
  return table
end

return build_alert_tab