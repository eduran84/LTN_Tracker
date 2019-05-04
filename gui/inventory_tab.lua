local defs = defs
local egm = egm
local C = C
local styles = defs.styles.inventory_tab

local tonumber, match, btest = tonumber, string.match, bit32.btest
local get_items_in_network = util.get_items_in_network
local build_item_table = util.build_item_table

local TOTAL_WIDTH = C.inventory_tab.details_width
local SUM_LABEL_WIDTH =  TOTAL_WIDTH - 150
local COL_COUNT =  C.inventory_tab.details_item_tb_col_count

local function build_inventory_tab(window)
  local tab_index = defs.tabs.inventory
  local flow = egm.tabs.add_tab(
    window.pane,
    tab_index,
    {caption = {"ltnt.tab3-caption"}, direction = "horizontal"}
  )
  local inv_tab = {
    root = flow,
    item_tables = {},
    selected_item = nil,
  }

  local left_flow = flow.add{
    type = "flow",
    direction = "vertical",
    style = defs.styles.shared.vertical_container,
  }
  left_flow.style.vertical_spacing = 6
  local button_flow = left_flow.add{
    type = "flow",
    style = defs.styles.shared.horizontal_container,
    direction = "horizontal",
  }
  button_flow.style.horizontal_spacing = 4

  local label = button_flow.add{
    type = "label",
    caption = {"inventory.id_selector-caption"},
    tooltip = {"inventory.id_selector-tt"},
  }
  inv_tab.id_selector = egm.misc.make_textbox_with_range(
    button_flow,
    {text = "-1"},
    defs.functions.id_selector_valid
  )

  local left_pane = left_flow.add{
    type = "scroll-pane",
    style = defs.styles.shared.no_frame_scroll_pane,
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space",
  }
  inv_tab.item_tables[1] = egm.item_table.build(
    left_pane, {
      caption = {"inventory.provide-caption"},
      item_list = {},
      width = 398,
      column_count = 10,
      row_count = 3,
      color = "green",
      action = defs.actions.show_item_details,
      super = inv_tab,
    }
  )
  inv_tab.item_tables[2] = egm.item_table.build(
    left_pane, {
      caption = {"inventory.request-caption"},
      item_list = {},
      column_count = 10,
      width = 398,
      row_count = 2,
      color = "red",
      action = defs.actions.show_item_details,
      super = inv_tab,
    }
  )
  inv_tab.item_tables[3] = egm.item_table.build(
    left_pane, {
      caption = {"inventory.transit-caption"},
      item_list = {},
      column_count = 10,
      width = 398,
      row_count = 2,
      action = defs.actions.show_item_details,
      super = inv_tab,
    }
  )
  -- details pane
  local details_frame = egm.window.build(flow, {
    caption = {"inventory.detail-caption", ""},
    --width = TOTAL_WIDTH,
    direction = "vertical",
  })
  local button = egm.window.add_button(details_frame, {
    type = "sprite-button",
    sprite = "item-group/intermediate-products",
  })
  button.enabled = false
  details_frame.icon = button
  -- summary at the top of the pane
  local summary = details_frame.content.add{type = "table", column_count = 2, style = "slot_table"}
  details_frame.summary = summary
  label = summary.add{type = "label", caption = {"inventory.detail-prov"}, style = "bold_label"}
  label.style.width = SUM_LABEL_WIDTH
  summary.add{type = "label", caption = "0", style = "ltnt_summary_number"}
  label = summary.add{type = "label", caption = {"inventory.detail-req"}, style = "bold_label"}
  label.style.width = SUM_LABEL_WIDTH
  summary.add{type = "label", caption = "0", style = "ltnt_summary_number"}
  label = summary.add{type = "label", caption = {"inventory.detail-tr"}, style = "bold_label"}
  label.style.width = SUM_LABEL_WIDTH
  summary.add{type = "label", caption = "0", style = "ltnt_summary_number"}

  local spacer_flow = details_frame.content.add{type = "flow"}
  spacer_flow.style.height = 10

  local pane = details_frame.content.add{
    type = "scroll-pane",
    style = defs.styles.shared.no_frame_scroll_pane,
    vertical_scroll_policy = "auto-and-reserve-space",
    horizontal_scroll_policy = "never",
  }

  pane.add{type = "label", style = "heading_2_label", caption = {"inventory.stop_header_p"}}
  local stop_table = pane.add{type = "flow", style = defs.styles.shared.vertical_container, direction = "vertical"}
  label = stop_table.add{type = "label", caption = {"inventory.detail_label"}}
  label.style.single_line = false
  label.style.width = TOTAL_WIDTH - 30

  pane.add{type = "label", style = "heading_2_label", caption = {"inventory.del_header"}}
  local del_table = pane.add{type = "flow", style = defs.styles.shared.vertical_container, direction = "vertical"}

  details_frame.stop_table = stop_table
  details_frame.delivery_table = del_table
  inv_tab.details_frame = details_frame

  return inv_tab
end

local function update_details(inv_tab, network_id)
  local item = inv_tab.selected_item
  if not item then return end
  local item_type, item_name = match(item, "([^,]+),(.+)") -- format: "<item_type>,<item_name>"
  local localised_name = item_name
  local data = global.data
  -- set item name and icon
  local proto
  if item_type == "fluid" then
    proto = game.fluid_prototypes[item_name]
  elseif item_type == "item" then
    proto = game.item_prototypes[item_name]
  end

  local details_frame = inv_tab.details_frame
  details_frame.root.children[1].children[1].caption = {
    "inventory.detail-caption",
    proto and proto.localised_name or item_name
  }
  details_frame.icon.sprite = proto and item_type .. "/" .. item_name or ""
  -- update totals
  local chd = details_frame.summary.children
  chd[2].caption = get_items_in_network(data.provided, network_id)[item] or 0
  chd[4].caption = get_items_in_network(data.requested, network_id)[item] or 0
  chd[6].caption = get_items_in_network(data.in_transit, network_id)[item] or 0

  -- update stop table with relevant stops
  local stop_table = details_frame.stop_table
  egm.manager.unregister(stop_table)
  stop_table.clear()
  local btest = btest
  if data.item2stop[item] then
		for _,stop_id in pairs(data.item2stop[item]) do
      local stop = data.stops[stop_id]
      if btest(stop.network_id, network_id) then
        local outer_flow = stop_table.add{type = "flow"}
        local label = outer_flow.add{
          type = "label",
          caption = stop.name,
          style = styles.stops_col_1,
        }
        egm.manager.register(
          label, {
            action = defs.actions.select_station_entity,
            stop_entity = stop.entity,
          }
        )
        label = outer_flow.add{
          type = "label",
          style = styles.stops_col_2,
          caption = "ID: " ..stop.network_id,
        }
        egm.manager.register(
          label, {
            action = defs.actions.select_station_entity,
            stop_entity = stop.entity,
          }
        )
        local inner_flow = stop_table.add{type = "flow"}
        build_item_table{
          parent = inner_flow,
          provided = data.provided_by_stop[stop_id],
          requested = data.requested_by_stop[stop_id],
          columns = COL_COUNT,
          max_rows = 2,
        }
      end
		end
	end

  -- update delivery table
  local delivery_table = details_frame.delivery_table
  egm.manager.unregister(delivery_table)
  delivery_table.clear()
  if data.item2delivery[item] then
		for _, delivery_id in pairs(data.item2delivery[item]) do
      local delivery = data.deliveries[delivery_id]
      if btest(delivery.networkID or -1, network_id) then
        local flow = delivery_table.add{type = "flow"}
        flow.style.vertical_align = "center"
        local label = flow.add{
          type = "label",
          caption = delivery.from,
          style = styles.del_col_1,
        }
        egm.manager.register(
          label, {
            action = defs.actions.station_name_clicked,
            name = delivery.from,
          }
        )
        label = flow.add{
          type = "label",
          caption = " >> ",
          style = styles.del_col_2,
        }
        label = flow.add{
          type = "label",
          caption = delivery.to,
          style = styles.del_col_3,
        }
        egm.manager.register(
          label, {
            action = defs.actions.station_name_clicked,
            name = delivery.to,
          }
        )
        flow = delivery_table.add{type = "flow"}
        build_item_table{
          parent = flow,
          provided = delivery.shipment,
          columns = COL_COUNT,
          max_rows = 2,
        }
      end
		end
	end
end

local function update_inventory_tab(inv_tab, ltn_data)
  local selector_data = egm.manager.get_registered_data(inv_tab.id_selector)
  local selected_network_id = tonumber(selector_data.last_valid_value)
  egm.item_table.set_items(inv_tab.item_tables[1], get_items_in_network(ltn_data.provided, selected_network_id))
  egm.item_table.set_items(inv_tab.item_tables[2], get_items_in_network(ltn_data.requested, selected_network_id))
  egm.item_table.set_items(inv_tab.item_tables[3], get_items_in_network(ltn_data.in_transit, selected_network_id))

  update_details(inv_tab, selected_network_id)
end

egm.manager.define_action(
  defs.actions.show_item_details,
  function(event, data)
    data.super.selected_item = data.item
    local selector_data = egm.manager.get_registered_data(data.super.id_selector)
    local selected_network_id = tonumber(selector_data.last_valid_value)
    update_details(data.super, selected_network_id)
  end
)

return {build_inventory_tab, update_inventory_tab}