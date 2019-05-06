local defs = defs
local egm = egm
local C = C
local n_cols_shipment = C.history_tab.n_cols_shipment
local styles = defs.styles.hist_tab

local ticks_to_timestring = util.misc.ticks_to_timestring
local build_item_table = util.build_item_table
egm.stored_functions[defs.functions.hist_row_constructor] = function(egm_table, data)
  local parent = egm_table.content
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
  egm.manager.register(label_from, {action = defs.actions.station_name_clicked, name = delivery.from})
  local label_to = flow.add{
    type = "label",
    caption = delivery.to,
    style = styles.label_col_2
  }
  egm.manager.register(label_to, {action = defs.actions.station_name_clicked, name = delivery.to})
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
  -- shipment and residual items, if any
  if delivery.residuals then
    local tb = parent.add{type = "table", column_count = 1, style = "slot_table"}
    build_item_table{
      parent = tb,
      provided = delivery.shipment,
      columns = n_cols_shipment
    }
    build_item_table{
      parent = tb,
      requested = delivery.residuals,
      columns = n_cols_shipment,
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

egm.stored_functions[defs.functions.hist_sort .. 1] = function(a, b) return a.delivery.depot < b.delivery.depot end
egm.stored_functions[defs.functions.hist_sort .. 2] = function(a, b) return a.delivery.from < b.delivery.from end
egm.stored_functions[defs.functions.hist_sort .. 3] = function(a, b) return a.delivery.networkID < b.delivery.networkID end
egm.stored_functions[defs.functions.hist_sort .. 4] = function(a, b) return a.time[1] < b.time[1] end
egm.stored_functions[defs.functions.hist_sort .. 5] = function(a, b) return a.time[2] < b.time[2] end

local function build_history_tab(window)
  local tab_index = defs.tabs.history
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab4-caption"}})
  local table = egm.table.build(
    flow,
    {column_count = C.history_tab.n_columns, draw_horizontal_lines = true},
    defs.functions.hist_row_constructor
  )
  for i = 1, C.history_tab.n_columns - 1 do
    egm.table.add_column_header(table, {
        sortable = true,
        width = C.history_tab.column_width[i],
        caption = {"history.header-col-"..i},
        tooltip = {"history.header-col-"..i.."-tt"},
      },
      defs.functions.hist_sort .. i
    )
  end
  egm.table.add_column_header(table, {
    width = C.history_tab.column_width[C.history_tab.n_columns],
    caption = {"history.header-col-"..C.history_tab.n_columns},
    tooltip = {"history.header-col-"..C.history_tab.n_columns.."-tt"},
  })
  local button = table.root.children[1].add{
    type = "sprite-button",
    style = defs.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"history.delete-tt"},
  }
  egm.manager.register(button, {action = defs.actions.clear_history, egm_table = table})
  return table
end

local function update_history_tab(hist_tab, ltn_data)
  local history_data = ltn_data.delivery_hist
  egm.table.clear(hist_tab)
  local offset = ltn_data.newest_history_index
  local max = ltn_data.history_limit
  for i = offset-1, (offset-max+1), -1 do
    local delivery = history_data[(i > 0) and i or (i + max)]
    if delivery then
      egm.table.add_row(hist_tab, {
        delivery = delivery,
        time = {ticks_to_timestring(delivery.runtime), ticks_to_timestring(delivery.finished)},
      })
    end
  end
end

return {build_history_tab, update_history_tab}