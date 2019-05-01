local defs = defs
local egm = egm
local C = C

local MAX_ROWS = require("script.constants").station_tab.item_table_max_rows
local COL_COUNTS = require("script.constants").station_tab.item_table_col_count
local build_item_table = util.build_item_table

local color_order = {["signal-red"] = 0, ["signal-pink"] = 3, ["signal-blue"] = 4, ["signal-yellow"] = 4.1, ["signal-green"] = 10000}
egm.stored_functions[defs.names.functions.station_sort .. 1] = function(a, b)
  return a.stop_data.name < b.stop_data.name
end
egm.stored_functions[defs.names.functions.station_sort .. 2] = function(a, b)
  local rank_a = color_order[a.stop_data.signals[1][1]] + a.stop_data.signals[1][2]
  local rank_b = color_order[b.stop_data.signals[1][1]] + b.stop_data.signals[1][2]
  return rank_a < rank_b
end

egm.stored_functions[defs.names.functions.station_row_constructor] = function(parent, data)
  local stopdata = data.stop_data
  local stop_id = data.stop_id
  if stopdata.isDepot == false and data.testfun(data.selected_network_id, stopdata.network_id) then
    -- stop is in selected network, create table entry
    -- first column: station name
    local label = parent.add{
      type = "label",
      caption = stopdata.name,
      style = defs.names.styles.station_tab.station_label,
    }
    egm.manager.register(
      label, {
        action = defs.names.actions.select_station_entity,
        stop_entity = stopdata.entity,
      }
    )
    -- second column: status
    parent.add{
      type = "sprite-button",
      sprite = "virtual-signal/"..stopdata.signals[1][1],
      number = stopdata.signals[1][2],
      enabled = false,
      style = "ltnt_empty_button",
    }
    -- third column: provided and requested items
    build_item_table{
      parent = parent,
      provided = global.data.provided_by_stop[stop_id],
      requested = global.data.requested_by_stop[stop_id],
      columns = COL_COUNTS[1],
      enabled = false,
      max_rows = MAX_ROWS[1],
    }
    -- fourth column: current deliveries
    build_item_table{
      parent = parent,
      provided = stopdata.incoming,
      requested = stopdata.outgoing,
      columns = COL_COUNTS[2],
      max_rows = MAX_ROWS[2],
      enabled = false,
    }
    -- fifth column: control signals
    build_item_table{
      parent = parent,
      signals = stopdata.signals[2],
      columns = data.signal_col_count,
      max_rows = MAX_ROWS[3],
      enabled = false,
    }
    -- LTNC button
    if data.signal_col_count < 6 then -- TODO fix this condition
      parent.add{
        type = "sprite-button",
        sprite = "item/ltn-combinator",
        tooltip = {"station.combinator-tt"},
      }
    else
      parent.add{type = "flow"}
    end
  end
end

local function build_station_tab(window, tab_index)
  local station_tab = {}
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab2-caption"}})
  local button_flow = flow.add{
    type = "flow",
    style = defs.names.styles.horizontal_container,
    direction = "horizontal",
  }
  local label = button_flow.add{
    type = "label",
    caption = {"station.id_selector-caption"},
    tooltip = {"station.id_selector-tt"},
  }
  local tonumber, floor = tonumber, math.floor
  station_tab.id_selector = egm.misc.make_textbox_with_range(
    button_flow,
    {text = "-1"},
    function(text)
      local num = tonumber(text)
      return num and num == floor(num) and true
    end
  )
  local checkbox = button_flow.add{
    type = "checkbox",
    state = false,
    caption = {"station.check-box-cap"},
    tooltip = {"station.check-box-tt"},
  }
  egm.manager.register(checkbox, {action = defs.names.actions.update_tab, tab_index = tab_index})
  station_tab.checkbox = checkbox
  button_flow.add{
    type = "flow",
    style = defs.names.styles.shared.horizontal_spacer,
    direction = "horizontal",
  }
  label = button_flow.add{
    type = "label",
    caption = {"station.filter_lb"},
    style = "ltnt_label_default",
  }
  local filter = button_flow.add{type = "textfield"}
  egm.manager.register(filter, {action = defs.names.actions.filter_input})
  local table = egm.table.build(
    flow,
    {column_count = C.station_tab.n_columns},
    defs.names.functions.station_row_constructor
  )
  for i = 1, C.station_tab.n_columns do
    egm.table.add_column_header(table, {
        sortable = i == 1 or i == 2,
        width = C.station_tab.col_width[i],
        caption = {"station.header-col-"..i},
        tooltip = {"station.header-col-"..i.."-tt"},
      },
      defs.names.functions.station_sort .. i
    )
  end
  station_tab.table = table
  return station_tab
end

return build_station_tab