local defs = defs
local egm = egm
local C = C
local util = util

local elements = {
  button = {type = "button", style = defs.styles.depot_tab.depot_selector},
  name_label = {
    type = "label",
    caption = "",
    style = defs.styles.depot_tab.depot_label,
    ignored_by_interaction = true,
  },
  ignored_vertical_flow = {
    type = "flow",
    direction = "vertical",
    ignored_by_interaction = true,
  },
  ignored_horizontal_flow = {type = "flow", ignored_by_interaction = true},
  label_1 = {
    type = "label",
    style = defs.styles.depot_tab.cap_left_1,
    caption = {"depot.header-col-2"},
    tooltip = {"depot.header-col-2-tt"},
    ignored_by_interaction = true,
  },
  label_2 = {
    type = "label",
    style = defs.styles.depot_tab.cap_left_2,
    caption = "",
    ignored_by_interaction = true,
  },
  label_3 = {
  type = "label",
    style = defs.styles.depot_tab.cap_left_1,
    caption = {"depot.header-col-3"},
    tooltip = {"depot.header-col-3-tt"},
    ignored_by_interaction = true,
  },
  id_table_icon = {
    type = "sprite-button",
    sprite = "virtual-signal/" .. C.ltn.NETWORKID,
    number = 0,
    enabled = false,
    style = defs.styles.shared.gray_button,
  },
  table_frame = {type = "frame",
    style = defs.styles.shared.slot_table_frame,
    ignored_by_interaction = true,
  },
  icon_table = {type = "table", column_count = 4, style = "slot_table"},
}

return
function (parent, depot_name, depot_data, reduced_width)
  local bt = parent.add(elements.button)
  local flow = bt.add(elements.ignored_vertical_flow)
  -- first row: depot name
  elements.name_label.caption = depot_name
  flow.add(elements.name_label)

  -- second row: number of trains and capacity
  local subflow = flow.add(elements.ignored_horizontal_flow)
  subflow.add(elements.label_1)
  elements.label_2.caption = depot_data.n_parked .. "/" .. depot_data.n_all_trains
  subflow.add(elements.label_2)
  if reduced_width then
    bt.style.width = reduced_width
  else
    subflow.add(elements.label_3)
    elements.label_2.caption = util.format_number(depot_data.cap) .. " stacks + " .. util.format_number(depot_data.fcap) .. " fluid"
    subflow.add(elements.label_2).style.width = C.depot_tab.col_width_left[5]
  end

  -- third row: network id and depot state
  subflow = flow.add(elements.ignored_horizontal_flow)
  util.gui.build_item_table{
    parent = subflow,
    columns = 4,
    signals = depot_data.signals,
    enabled = false,
  }
  local elem = subflow.add(elements.table_frame)
  elem.style.maximal_height = 44
  elem = elem.add(elements.icon_table)
  local hash = {}
  for _, id in pairs(depot_data.network_ids) do
    if not hash[id] then
      elements.id_table_icon.number = id
      elem.add(elements.id_table_icon)
      hash[id] = true
    end
  end
  return bt
end