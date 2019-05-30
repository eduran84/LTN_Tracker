local defs = defs
local egm = egm
local C = C
local styles = defs.styles.inventory_tab

local tonumber, match, btest, gsub = tonumber, string.match, bit32.btest, string.gsub
local get_items_in_network = util.get_items_in_network
local get_item_in_network = util.get_item_in_network
local build_item_table = util.gui.build_item_table
local bar_graph = require(defs.pathes.modules.bar_graph)

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

  local left_flow = flow.add(C.elements.flow_vertical_container)
  left_flow.style.vertical_spacing = 6
  local button_flow = left_flow.add(C.elements.flow_horizontal_container)
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

  local left_pane = left_flow.add(C.elements.no_frame_scroll_pane)

  local fade_time = util.get_setting(defs.settings.station_click_action, game.players[window.player_index]) * 60 * 60
  if fade_time == 0 then fade_time = nil end
  local width = C.inventory_tab.item_table_width
  inv_tab.item_tables[1] = egm.item_table.build(
    left_pane, {
      caption = {"inventory.provide-caption"},
      item_list = {},
      width = width,
      column_count = C.inventory_tab.item_table_column_count,
      row_count = 3,
      color = "green",
      action = defs.actions.show_item_details,
      super = inv_tab,
      fade_timeout = fade_time,
      buttons_per_row = 9,
    }
  )
  inv_tab.item_tables[2] = egm.item_table.build(
    left_pane, {
      caption = {"inventory.request-caption"},
      item_list = {},
      column_count = C.inventory_tab.item_table_column_count,
      width = width,
      row_count = 2,
      color = "red",
      action = defs.actions.show_item_details,
      super = inv_tab,
      buttons_per_row = 9,
    }
  )
  inv_tab.item_tables[3] = egm.item_table.build(
    left_pane, {
      caption = {"inventory.transit-caption"},
      item_list = {},
      column_count = C.inventory_tab.item_table_column_count,
      width = width,
      row_count = 2,
      action = defs.actions.show_item_details,
      super = inv_tab,
      buttons_per_row = 9,
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
  inv_tab.bar_graph = bar_graph.build(details_frame.content)
  local summary = details_frame.content.add{type = "table", column_count = 2, style = "slot_table"}
  width = C.inventory_tab.details_width - C.inventory_tab.summary_number_width - 25
  details_frame.summary = summary
  label = summary.add{type = "label", caption = {"inventory.detail-prov"}, style = "bold_label"}
  label.style.width = width

  summary.add{type = "label", caption = "0", style = styles.summary_number}.style.width = 90
  label = summary.add{type = "label", caption = {"inventory.detail-req"}, style = "bold_label"}
  label.style.width = width
  summary.add{type = "label", caption = "0", style = styles.summary_number}.style.width = 90
  label = summary.add{type = "label", caption = {"inventory.detail-tr"}, style = "bold_label"}
  label.style.width = width
  summary.add{type = "label", caption = "0", style = styles.summary_number}.style.width = 90

  local spacer_flow = details_frame.content.add(C.elements.flow_default)
  spacer_flow.style.height = 10

  local pane = details_frame.content.add(C.elements.no_frame_scroll_pane)

  details_frame.stop_header = pane.add{type = "label", style = "heading_2_label", caption = {"inventory.stop_header_p"}}
  details_frame.stop_table = pane.add(C.elements.flow_vertical_container)
  label = details_frame.stop_table.add{type = "label", caption = {"inventory.detail_label"}}
  label.style.single_line = false
  label.style.width = C.inventory_tab.details_width - 45

  details_frame.request_header = pane.add{type = "label", style = "heading_2_label", caption = {"inventory.req_header"}}
  details_frame.request_table = pane.add(C.elements.flow_vertical_container)

  details_frame.delivery_header = pane.add{type = "label", style = "heading_2_label", caption = {"inventory.del_header"}}
  details_frame.delivery_table = pane.add(C.elements.flow_vertical_container)


  inv_tab.details_frame = details_frame

  return inv_tab
end

local function set_fadeout_time(inv_tab, pind)
  local setting_value = util.get_setting(defs.settings.fade_timeout, game.players[pind]) * 60 * 60
  if setting_value == 0 then setting_value = nil end
  inv_tab.item_tables[1].fade_timeout = setting_value
end

local elements = {
  label_stop_col1 = {
    type = "label",
    caption = "",
    style = styles.stops_col_1,
  },
  label_stop_col2 = {
    type = "label",
    caption = "",
    style = styles.stops_col_2,
  },
  label_req_1 = {
    type = "label",
    caption = {"inventory.req_station"},
    style = "heading_3_label_yellow",
  },
  label_req_2 = {
    type = "label",
    caption = "",
    style = "bold_label",
  },
  label_req_3 = {
    type = "label",
    caption = "State:",
    style = "heading_3_label_yellow",
  },
  label_req_4 = {
    type = "label",
    caption = "",
    style = "bold_red_label",
  },
  icon_req_1 = {
    type = "sprite-button",
    sprite = "",
    number = 0,
    style = defs.styles.shared.gray_button,
    tooltip = {"inventory.amt_requested"},
    enabled = false,
  },
  icon_req_2 = {
    type = "sprite-button",
    sprite = "virtual-signal/" .. C.ltn.NETWORKID,
    number = -1,
    style = defs.styles.shared.gray_button,
    tooltip = {"inventory.id_icon_tt"},
    enabled = false,
  },
  icon_req_3 = {
    type = "sprite-button",
    sprite = "virtual-signal/" .. C.ltn.MINTRAINLENGTH,
    number = 0,
    style = defs.styles.shared.gray_button,
    tooltip = {"inventory.min_length_icon_tt"},
    enabled = false,
  },
  icon_req_4 = {
    type = "sprite-button",
    sprite = "virtual-signal/" .. C.ltn.MAXTRAINLENGTH,
    number = 0,
    style = defs.styles.shared.gray_button,
    tooltip = {"inventory.max_length_icon_tt"},
    enabled = false,
  },
  label_del_col1 = {
    type = "label",
    caption = "",
    style = styles.del_col_1,
  },
  label_del_col2 = {
    type = "label",
    caption = " >> ",
    style = styles.del_col_2,
  },
  label_del_col3 = {
    type = "label",
    caption = "",
    style = styles.del_col_3,
  },
  item_table = {
    parent = 1,
    provided = {},
    requested = {},
    columns = COL_COUNT,
    max_rows = 2,
  },
}


local function update_details(inv_tab, network_id)
  local item = inv_tab.selected_item
  if not item then return end
  local data = global.data

  bar_graph.update(inv_tab.bar_graph, item)
  -- set item name and icon
  local details_frame = inv_tab.details_frame
  details_frame.root.children[1].children[1].caption = {
    "inventory.detail-caption",
    util.get_item_name(item),
  }
  local sprite = util.get_item_sprite(item)
  details_frame.icon.sprite = sprite
  -- update totals
  local chd = details_frame.summary.children
  local format_number = util.format_number
  chd[2].caption = format_number(get_item_in_network(data.provided, network_id, item))
  chd[4].caption = format_number(get_item_in_network(data.requested, network_id, item))
  chd[6].caption = format_number(get_item_in_network(data.in_transit, network_id, item))


  local requesting_stops = {}
  local btest = btest
  local flow_params = C.elements.flow_default

  -- update stop table with relevant stops
  local tble = details_frame.stop_table
  egm.manager.unregister(tble)
  tble.clear()
  local table_add = tble.add
  local show_header = false
  if data.item2stop[item] then
		for _,stop_id in pairs(data.item2stop[item]) do
      local stop = data.stops[stop_id]
      if btest(stop.network_id, network_id) then
        local outer_flow = table_add(flow_params)
        elements.label_stop_col1.caption = stop.name
        local label = outer_flow.add(elements.label_stop_col1)
        egm.manager.register(
          label, {
            action = defs.actions.select_station_entity,
            stop_entity = stop.entity,
          }
        )
        elements.label_stop_col2.caption = "ID: " .. stop.network_id
        label = outer_flow.add(elements.label_stop_col2)
        egm.manager.register(
          label, {
            action = defs.actions.select_station_entity,
            stop_entity = stop.entity,
          }
        )
        elements.item_table.parent = table_add(flow_params)
        elements.item_table.provided = data.provided_by_stop[stop_id]
        elements.item_table.requested = data.requested_by_stop[stop_id]
        if data.requested_by_stop[stop_id] and data.requested_by_stop[stop_id][item] then
          requesting_stops[stop_id] = stop
        end
        build_item_table(elements.item_table)
        show_header = true
      end
		end
	end
  details_frame.stop_header.visible = show_header

 -- update request table
  local available = (get_item_in_network(data.provided, -1, item) > 0)
  tble = details_frame.request_table
  egm.manager.unregister(tble)
  tble.clear()
  table_add = tble.add
  show_header = false
  for stop_id, stop in pairs(requesting_stops) do
    local frame = table_add{
      type = "frame",
      style = defs.styles.shared.no_padding_frame,
      direction = "vertical",
    }
    frame.style.horizontally_stretchable = true
    local outer_flow = frame.add(flow_params)
    elements.icon_req_1.sprite = sprite
    elements.icon_req_1.number = data.requested_by_stop[stop_id][item]
    outer_flow.add(elements.icon_req_1)

    outer_flow.add(elements.label_req_1)
    elements.label_req_2.caption = stop.name
    outer_flow.add(elements.label_req_2)

    outer_flow = frame.add(flow_params)
    outer_flow.add(elements.label_req_3)
    if available then
      if get_item_in_network(data.provided, stop.network_id, item) > 0 then
        elements.label_req_4.caption = "No suitable train found."
      else
        elements.label_req_4.caption = "Item not available in network."
      end
    else
      elements.label_req_4.caption = "Item not available."
    end
    outer_flow.add(elements.label_req_4)

    outer_flow = frame.add(flow_params)
    elements.icon_req_2.number = stop.network_id
    outer_flow.add(elements.icon_req_2)
    elements.icon_req_3.number = stop[C.ltn.ctrl_signal_var_name_num[C.ltn.MINTRAINLENGTH]]
    outer_flow.add(elements.icon_req_3)
    elements.icon_req_4.number = stop[C.ltn.ctrl_signal_var_name_num[C.ltn.MAXTRAINLENGTH]]
    outer_flow.add(elements.icon_req_4)
    show_header = true
  end
  details_frame.request_header.visible = show_header

  -- update delivery table
  tble = details_frame.delivery_table
  egm.manager.unregister(tble)
  tble.clear()
  table_add = tble.add
  show_header = false
  if data.item2delivery[item] then
		for _, delivery_id in pairs(data.item2delivery[item]) do
      local delivery = data.deliveries[delivery_id]
      if btest(delivery.networkID or -1, network_id) then
        local flow = table_add(flow_params)
        flow.style.vertical_align = "center"

        elements.label_del_col1.caption = delivery.from
        local label = flow.add(elements.label_del_col1)
        egm.manager.register(
          label, {
            action = defs.actions.station_name_clicked,
            name = delivery.from,
          }
        )
        label = flow.add(elements.label_del_col2)
        elements.label_del_col3.caption = delivery.to
        label = flow.add(elements.label_del_col3)
        egm.manager.register(
          label, {
            action = defs.actions.station_name_clicked,
            name = delivery.to,
          }
        )
        elements.item_table.parent = table_add(flow_params)
        elements.item_table.provided = delivery.shipment
        elements.item_table.requested = nil
        build_item_table(elements.item_table)
        show_header = true
      end
		end
	end
  details_frame.delivery_header.visible = show_header
end

local function update_inventory_tab(inv_tab, ltn_data)
  local selector_data = egm.manager.get_registered_data(inv_tab.id_selector)
  local selected_network_id = tonumber(selector_data.last_valid_value)
  egm.item_table.update_items(inv_tab.item_tables[1], get_items_in_network(ltn_data.provided, selected_network_id))
  egm.item_table.update_items(inv_tab.item_tables[2], get_items_in_network(ltn_data.requested, selected_network_id))
  egm.item_table.update_items(inv_tab.item_tables[3], get_items_in_network(ltn_data.in_transit, selected_network_id))

  update_details(inv_tab, selected_network_id)
end

egm.manager.define_action(defs.actions.show_item_details,--[[
Triggering elements:
  item icons @ egm_item_table
Event: on_gui_click
Data:
  super :: egm_object: the parent object of the item table the clicked icon belongs to
  item :: string: the item name of the clicked icon in "<type>,<name>" format
]]function(event, data)
    data.super.selected_item = data.item
    local selector_data = egm.manager.get_registered_data(data.super.id_selector)
    local selected_network_id = tonumber(selector_data.last_valid_value)
    update_details(data.super, selected_network_id)
  end
)

return {
  build = build_inventory_tab,
  update = update_inventory_tab,
  set_fadeout_time = set_fadeout_time,
}