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
egm.stored_functions[defs.names.functions.id_selector_valid] = function(text)
  local num = tonumber(text)
  return num and num == math.floor(num) and true
end

egm.stored_functions[defs.names.functions.station_row_constructor] = function(egm_table, data)
  local parent = egm_table.content
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
    if data.signal_col_count < 6 then
      local button = parent.add{
        type = "sprite-button",
        style = defs.names.styles.shared.default_button,
        sprite = "item/ltn-combinator",
        tooltip = {"station.combinator-tt"},
      }
      egm.manager.register(
        button, {
          action = defs.names.actions.select_ltnc,
          stop_entity = stopdata.entity,
          lamp_entity = stopdata.input,
        }
      )
    else
      parent.add{type = "flow"}
    end
  end
end

local function build_station_tab(window)
  local tab_index = defs.names.tabs.station
  local station_tab = {
    filter = {
      cache = {},
      current = nil,
      last = nil,
    }
  }
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab2-caption"}})
  station_tab.root = flow
  local button_flow = flow.add{
    type = "flow",
    style = defs.names.styles.shared.horizontal_container,
    direction = "horizontal",
  }
  local label = button_flow.add{
    type = "label",
    caption = {"station.id_selector-caption"},
    tooltip = {"station.id_selector-tt"},
  }
  station_tab.id_selector = egm.misc.make_textbox_with_range(
    button_flow,
    {text = "-1"},
    defs.names.functions.id_selector_valid
  )
  local checkbox = button_flow.add{
    type = "checkbox",
    state = false,
    caption = {"station.check-box-cap"},
    tooltip = {"station.check-box-tt"},
  }
  egm.manager.register(checkbox, {action = defs.names.actions.update_tab})
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
  egm.manager.register(
    filter,
    {action = defs.names.actions.update_filter, filter = station_tab.filter})
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

local find = string.find
local lower = string.lower
local insert = table.insert
local name2lowercase = setmetatable({}, {
  __index = function(self, station_name)
    local name = lower(station_name)
    rawset(self, station_name, name)
    return name
  end,
})
local function get_stops(station_tab, ltn_data)
  if station_tab.filter.current then
    if station_tab.filter.last == nil or station_tab.filter.last ~= station_tab.filter.current then
      station_tab.filter.cache = {}
      local filter_lower = lower(station_tab.filter.current)
      local find = find
      for _, stop_id in pairs(ltn_data.stop_ids) do
        local match = true
        for word in filter_lower:gmatch("%S+") do
          if not find(name2lowercase[ltn_data.stops[stop_id].name], word, 1, true) then match = false end
        end
        if match then insert(station_tab.filter.cache, stop_id) end
      end
      station_tab.filter.last = station_tab.filter.current
    end
    return station_tab.filter.cache
  else
    return ltn_data.stop_ids
  end
end

local function update_station_tab(station_tab, ltn_data)
  local station_table = station_tab.table
  egm.table.clear(station_table)
  local ltnc_active = global.gui_data.is_ltnc_active
  local signal_col_count = C.station_tab.item_table_col_count[3] + (ltnc_active and 0 or 1)
  local selector_data = egm.manager.get_registered_data(station_tab.id_selector)
  local selected_network_id = tonumber(selector_data.last_valid_value)
  local testfun
  if station_tab.checkbox.state then
    testfun = function(a,b) return a==b end
  else
    testfun = bit32.btest
  end
  local stops_to_list = get_stops(station_tab, ltn_data)
  for i = 1, #stops_to_list do
    local stop_id = stops_to_list[i]
    if stop_id and ltn_data.stops[stop_id] then
      local row_data = {
        signal_col_count = signal_col_count,
        testfun = testfun,
        selected_network_id = selected_network_id,
        stop_id = stop_id,
        stop_data = ltn_data.stops[stop_id],
      }
      egm.table.add_row_data(station_table, row_data)
    end
  end
  egm.table.sort_rows(station_table)
end

return {build_station_tab, update_station_tab}