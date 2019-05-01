local defs = defs
local egm_defs = require("__GUI_Modules__.defines")
local egm = egm
local C = C

local tonumber = tonumber

require(defs.pathes.modules.action_definitions)

-----------------
-- History Tab --
-----------------
local n_cols_shipment = C.history_tab.n_cols_shipment
local build_item_table = util.build_item_table
local styles = defs.names.styles.hist_tab
egm.stored_functions[defs.names.functions.hist_row_constructor] = function(parent, data)
  local delivery = data.delivery
  parent.add{
    type = "label",
    caption = delivery.depot,
    style = styles.label_col_1
  }
  local flow = parent.add{type = "flow", direction = "vertical"}
  local label_from = flow.add{
    type = "label",
    caption = delivery.from,
    style = styles.label_col_2
  }
  egm.manager.register(label_from, {action = defs.names.actions.station_name_clicked, name = delivery.from})
  local label_to = flow.add{
    type = "label",
    caption = delivery.to,
    style = styles.label_col_2
  }
  egm.manager.register(label_to, {action = defs.names.actions.station_name_clicked, name = delivery.to})
  -- network id
  parent.add{
    type = "label",
    caption = delivery.networkID,
    style = styles.label_col_3
  }
  -- runtime, possibly with time-out warning
  if delivery.timed_out then
    parent.add{
      type = "label",
      caption = data.time[1],
      tooltip = {"error.train-timeout"},
    style = styles.label_col_4_red
    }
  else
    parent.add{
      type = "label",
      caption = data.time[1],
    style = styles.label_col_4
    }
  end
  -- time this delivery finished at
  parent.add{
    type = "label",
    caption = data.time[2],
    style = styles.label_col_5
  }
  -- shipement and residual items, if any
  if delivery.residuals then
    local tb = parent.add{type = "table", column_count = 1, style = "slot_table"}
    build_item_table{
      parent = tb,
      provided = delivery.shipment,
      columns = n_cols_shipment
    }
    build_item_table{
      parent = tb,
      requested = delivery.residuals[2],
      columns = n_cols_shipment,
      type = delivery.residuals[1],
      no_negate = true,
    }
  else
    build_item_table{
      parent = parent,
      provided = delivery.shipment,
      columns = n_cols_shipment
    }
  end -- if delivery.residuals then
end

egm.stored_functions[defs.names.functions.hist_sort .. 1] = function(a, b) return a.delivery.depot < b.delivery.depot end
egm.stored_functions[defs.names.functions.hist_sort .. 2] = function(a, b) return a.delivery.from < b.delivery.from end
egm.stored_functions[defs.names.functions.hist_sort .. 3] = function(a, b) return a.delivery.networkID < b.delivery.networkID end
egm.stored_functions[defs.names.functions.hist_sort .. 4] = function(a, b) return a.delivery.finished < b.delivery.finished end
egm.stored_functions[defs.names.functions.hist_sort .. 5] = function(a, b) return a.delivery.finished < b.delivery.finished end

local function build_history_tab(window, tab_index)
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab4-caption"}})
  local table = egm.table.build(
    flow,
    {column_count = C.history_tab.n_columns},
    defs.names.functions.hist_row_constructor
  )
  for i = 1, C.history_tab.n_columns - 1 do
    egm.table.add_column_header(table, {
        sortable = true,
        width = C.history_tab.column_width[i],
        caption = {"history.header-col-"..i},
        tooltip = {"history.header-col-"..i.."-tt"},
      },
      defs.names.functions.hist_sort .. i
    )
  end
  egm.table.add_column_header(table, {
    width = C.history_tab.column_width[C.history_tab.n_columns],
    caption = {"history.header-col-"..C.history_tab.n_columns},
    tooltip = {"history.header-col-"..C.history_tab.n_columns.."-tt"},
  })
  local button = table.root.children[1].add{
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"history.delete-tt"},
  }
  egm.manager.register(button, {action = defs.names.actions.clear_history, egm_table = table})
  window.tabs[tab_index] = table
end

-----------------
--  Alert Tab  --
-----------------
local col_width = C.alert_tab.col_width
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
  window.tabs[tab_index] = table
end

local w = {}
function w.build(parent)
  local pind = parent.player_index
  local window_height = settings.get_player_settings(game.players[pind])[defs.names.settings.window_height].value
  local window = egm.window.build(parent, {
    caption = {"ltnt.mod-name"},
    height = window_height,
    width = C.window.width,
    direction = "vertical",
  })
  window.root.visible = false
  egm.window.add_button(window, {
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = defs.names.sprites.refresh,
    tooltip = {"ltnt.refresh-bt"},
  },
  {action = defs.names.actions.refresh_button})

  local pane = egm.tabs.build(window.content, {direction = "vertical"})
  window.pane = pane
  egm.tabs.add_tab(pane, 1, {caption = {"ltnt.tab1-caption"}})
  egm.tabs.add_tab(pane, 2, {caption = {"ltnt.tab2-caption"}})
  egm.tabs.add_tab(pane, 3, {caption = {"ltnt.tab3-caption"}})

  window.tabs = {}
  local history_table = build_history_tab(window, defs.names.tabs.history)
  local alert_tab = build_alert_tab(window, defs.names.tabs.alert)
  return window, pane
end

return w