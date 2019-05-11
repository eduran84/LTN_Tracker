local defs = defs
local egm = egm
local C = C
local styles = defs.styles.depot_tab
local util = util

return
function (parent, depot_name, depot_data)
  local bt = parent.add{
    type = "button",
    style = styles.depot_selector,
  }
  local flow = bt.add{
    type = "flow",
    direction = "vertical",
    ignored_by_interaction = true,
  }
  -- first row: depot name
  local label = flow.add{
    type = "label",
    caption = depot_name,
    style = styles.depot_label,
    ignored_by_interaction = true,
  }

  -- second row: number of trains and capacity
  local subflow = flow.add{type = "flow"}
  label = subflow.add{
    type = "label",
    style = styles.cap_left_1,
    caption = {"depot.header-col-2"},
    tooltip = {"depot.header-col-2-tt"},
    ignored_by_interaction = true,
  }

  label = subflow.add{
    type = "label",
    style = styles.cap_left_2,
    caption = depot_data.n_parked .. "/" .. depot_data.n_all_trains,
    ignored_by_interaction = true,
  }

  label = subflow.add{
    type = "label",
    style = styles.cap_left_1,
    caption = {"depot.header-col-3"},
    tooltip = {"depot.header-col-3-tt"},
    ignored_by_interaction = true,
  }
  label = subflow.add{
    type = "label",
    style = styles.cap_left_2,
    caption =  util.format_number(depot_data.cap) .. " stacks + " .. util.format_number(depot_data.fcap)" fluid",
    ignored_by_interaction = true,
  }
  label.style.width = C.depot_tab.col_width_left[5]
  -- third row: network id and depot state
  subflow = flow.add{type = "flow", ignored_by_interaction = true,}
  util.gui.build_item_table{
    parent = subflow,
    columns = 4,
    signals = depot_data.signals,
    enabled = false,
  }
  local elem = subflow.add{type = "frame", style = defs.styles.shared.slot_table_frame, ignored_by_interaction = true,}
  elem.style.maximal_height = 44
  elem = elem.add{type = "table", column_count = 4, style = "slot_table"}
  local hash = {}
  local network_id_sprite = "virtual-signal/" .. C.ltn.NETWORKID
  for _, id in pairs(depot_data.network_ids) do
    if not hash[id] then
      elem.add{
        type = "sprite-button",
        sprite = network_id_sprite,
        number = id,
        enabled = false,
        style = defs.styles.shared.gray_button,
      }
      hash[id] = true
    end
  end
  return bt
end