--[[
Layout:

------------ frame ------------
| <item name>    [item icon]  |  -- inside a flow
| <provided>        <NUBMER>  |  >
| <requested>       <NUBMER>  |  > inside of a table with two columns
| <transit>         <NUBMER>  |  >
| <table caption>             |
| <col1>   <col2>   <col3>    | > table listing stations
| <col1>   <col2>   <col3>    | > col1 = name col2 = networkID; 
| .....                       | > col3 = items provided / requested
-------------------------------
--]]

-- set/get constants
local TOTAL_WIDTH = require("ltnc.const").inventory_tab.details_width
local COL_WIDTH = require("ltnc.const").inventory_tab.details_tb_col_width
local COL_WIDTH_1_2 = COL_WIDTH[1] + COL_WIDTH[2] + 20
local SUM_LABEL_WIDTH =  TOTAL_WIDTH - 150
local NAME = "inv_details"

local GC = require("ui.classes.GuiComposition")
local gcDetails = GC(NAME, {
  params = {
    type = "frame",
    direction = "vertical",
    caption = {"inventory.detail-caption"},
    style = "tool_bar_frame"
  },  
})
do -- add elements for layout
-- header line with item name and icon
gcDetails:add{
  name = "header_flow",
  parent_name = "root",
  params = {type = "flow", direction = "horizontal"}
}
gcDetails:add{
  name = "item_label",
  parent_name = "header_flow",
  params = {type = "label", caption = "", style = "ltnc_label_default"},
  style = {font = "ltnc_font_subheading", width = TOTAL_WIDTH - 75},
}
gcDetails:add{
  name = "item_icon",
  parent_name = "header_flow",
  params = {type = "sprite-button", sprite = "item-group/intermediate-products", enabled = false},
}
-- summary at the top of the pane
gcDetails:add{
  name = "summary_tb",
  parent_name = "root",
  params = {type = "table", column_count = 2, style = "slot_table"}
}
gcDetails:add{
  name = "tprov_label",
  parent_name = "summary_tb",
  params = {type = "label", caption = {"inventory.detail-prov"}, style = "ltnc_summary_label"},
  style = {width = SUM_LABEL_WIDTH},
}
gcDetails:add{
  name = "tprov_num",
  parent_name = "summary_tb",
  params = {type = "label", caption = "0", style = "ltnc_summary_number"},
}
gcDetails:add{
  name = "treq_label",
  parent_name = "summary_tb",
  params = {type = "label", caption = {"inventory.detail-req"}, style = "ltnc_summary_label"},
  style = {width = SUM_LABEL_WIDTH},
}
gcDetails:add{
  name = "treq_num",
  parent_name = "summary_tb",
  params = {type = "label", caption = "0", style = "ltnc_summary_number"},
}
gcDetails:add{
  name = "ttr_label",
  parent_name = "summary_tb",
  params = {type = "label", caption = {"inventory.detail-tr"}, style = "ltnc_summary_label"},
  style = {width = SUM_LABEL_WIDTH},
}
gcDetails:add{
  name = "ttr_num",
  parent_name = "summary_tb",
  params =  {type = "label", caption = "0", style = "ltnc_summary_number"},
}

-- scrollpane for following tables
gcDetails:add{
  name = "scroll",
  parent_name = "root",
  params = {type = "scroll-pane", style = "ltnc_scrollpane"},
}  

-- table with label listing stops
gcDetails:add{
  name = "stoptb_label",
  parent_name = "scroll",
  params = {type = "label", style = "ltnc_column_header", caption = {"inventory.stop_header_p"}} 
}
gcDetails:add{
  name = "stoptb",
  parent_name = "scroll",
  params = {type = "table", column_count = 3, style = "table_with_selection"},
  style = {vertical_align = "center", cell_spacing = 0},
}
gcDetails:add{
  name = "desc",
  parent_name = "stoptb",
  params = {type = "label", caption = {"inventory.detail_label"}, style = "ltnc_label_default"},
  style = {single_line = false, width = TOTAL_WIDTH - 30},
}
end
-- table with label listing deliveries
gcDetails:add{
  name = "deltb_label",
  parent_name = "scroll",
  params = {type = "label", style = "ltnc_column_header", caption = {"inventory.del_header"}} 
}
gcDetails:add{
  name = "deltb",
  parent_name = "scroll",
  params = {type = "table", column_count = 2, style = "table_with_selection"},
  style = {vertical_align = "center", cell_spacing = 0},
}

-- overloaded methods
function gcDetails:on_init(storage_tb)
  GC.on_init(self, storage_tb)
  self.mystorage.selected_item = self.mystorage.selected_item or {}
end

function gcDetails:event_handler(event, index, data_string)
  return "on_stop_name_clicked"
end

-- additional methods
-- cache functions
local match = string.match
local get_items_in_network = require("ltnc.util").get_items_in_network
local build_item_table = require("ui.util").build_item_table

function gcDetails:set_item(pind, ltn_item)
  ltn_item = ltn_item or self.mystorage.selected_item[pind]
  if not ltn_item then return end
  self.mystorage.selected_item[pind] = ltn_item
  local item_type, item_name = match(ltn_item, "([^,]+),(.+)") -- format: "<item_type>,<item_name>"
	local spritepath = item_type .. "/" .. item_name
  local localised_name = item_name
  local get = self.get_el
  local data = global.data
  -- set item name and icon
  local proto
  if item_type == "fluid" then
    proto = game.fluid_prototypes[item_name]
  elseif item_type == "item" then
    proto = game.item_prototypes[item_name]
  end
  get(self, pind, "item_label").caption = proto.localised_name or item_name
  get(self, pind, "item_icon").sprite = spritepath
  -- update totals
  local provided_items = get_items_in_network(data.provided, -1)
	get(self, pind, "tprov_num").caption = provided_items[ltn_item] or 0	
	local requested_items = get_items_in_network(data.requested, -1)
	get(self, pind, "treq_num").caption = requested_items[ltn_item] or 0
	get(self, pind, "ttr_num").caption = data.in_transit[ltn_item] or 0
	
  
  -- update stop table with relevant stops
  local tb = get(self, pind, "stoptb")
  local create_name = self._create_name
  tb.clear()
  -- all stops providing /requesting the selected item
  local index = #self.elem
  if data.item2stop[ltn_item] then
		for _,stop_id in pairs(data.item2stop[ltn_item]) do
      local stop = data.stops[stop_id]
      index = index + 1 
			local label = tb.add{
				type = "label",
				caption = stop.name,
				style = "ltnc_hoverable_label",
        name = create_name(self, index, stop_id)
			}
      index = index + 1 
			label.style.width = COL_WIDTH[1]
			label.style.single_line = false
			label = tb.add{
				type = "label",
				caption = "ID: " ..stop.network_id,
				style = "ltnc_hoverable_label",
        name = create_name(self, index, stop_id)
			}
			label.style.width = COL_WIDTH[2]
      build_item_table{
        parent = tb,
        provided = stop.provided,
        requested = stop.requested,
        columns = 3,
      }      
		end
	end
  
  -- update delivery table
  tb = get(self, pind, "deltb")
  tb.clear()
  if data.item2delivery[ltn_item] then
		for _,delivery_id in pairs(data.item2delivery[ltn_item]) do
      local delivery = data.deliveries[delivery_id]
			local flow = tb.add{type = "flow", direction = "vertical"}
      flow.style.vertical_align = "center"
      index = index + 1 
      local label = flow.add{
				type = "label",
				caption = delivery.from,
				style = "ltnc_hoverable_label",
        name = create_name(self, index, delivery.from_id)
			}
			label.style.width = COL_WIDTH_1_2
      index = index + 1 
      label = flow.add{
				type = "label",
				caption = delivery.to,
				style = "ltnc_hoverable_label",
        name = create_name(self, index, delivery.to_id)
			}
			label.style.width = COL_WIDTH_1_2
      
      build_item_table{
        parent = tb,
        provided = delivery.shipment,
        columns = 3,
      }      
		end
	end
end

return gcDetails