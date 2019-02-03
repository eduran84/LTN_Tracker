-- localize helper functions
local get_items_in_network = require("ltnc.util").get_items_in_network

-- set/get constants
local NAME = "inv_tab"
local N_SUBPANES = 4

local gcInvTab= require("ui.classes.GuiComposition")(NAME, {
  params = {type = "flow", direction = "vertical"},
  style = {visible = false},
})

-- add ID selector
gcInvTab:add{
  name = "idSelector",
  parent_name = "root",
  gui_composition = require("ui.classes.TextFieldWithRange")(
    "IDSinv", 
    {
      caption = {"inventory.id_selector-caption"},
      tooltip = {"inventory.id_selector-tt"},
    }
  )  
}

-- flow for tab main body
gcInvTab:add{
  name = "flow",
  parent_name = "root",
  params = {type = "flow", direction = "horizontal"},
}

gcInvTab:add{
  name = "spane",
  parent_name = "flow",
  params = {
    type = "scroll-pane",
    horizontal_scroll_policy = "never"
  },
}

-- add item tables
local IT = require("ui.classes.ItemTable")
gcInvTab:add{
  name = "provided",
  parent_name = "spane",
  gui_composition = IT("inv_provided", {
    column_count = 15,
    enabled = true,
    caption = {"inventory.provide-caption"},
    button_style = 1, --green background
    use_placeholders = 29,
  })
}
gcInvTab:add{
  name = "requested",
  parent_name = "spane",
  gui_composition = IT("inv_requested", {
    column_count = 15,
    enabled = true,
    caption = {"inventory.request-caption"},
    button_style = 2, --red background
    use_placeholders = 29,
  })
}
gcInvTab:add{
  name = "transit",
  parent_name = "spane",
  gui_composition = IT("inv_transit", {
    column_count = 15,
    enabled = true,
    caption = {"inventory.transit-caption"},
    use_placeholders = 29,
  })
}
gcInvTab:add{
  name = "spacer_flow",
  parent_name = "flow",
  params = {type = "flow", horizontally_stretchable = "true"}
}
gcInvTab.tab_index = require("ltnc.const").inventory_tab.tab_index
-- details pane on the right side
gcInvTab:add{
  name = "details",
  parent_name = "flow",
  gui_composition = require("ui.inventory_tab.details_pane"), 
}
gcInvTab.tab_index = require("ltnc.const").inventory_tab.tab_index

-- additional methods
function gcInvTab:update(pind, index)
  if index == self.tab_index then
    self:show(pind)
    global.gui.active_tab[pind] = index
    local selected_network_id = self.sub_gc.idSelector:get_current_value(pind)
    local data = global.data
    local itemTables = self.sub_gc
    itemTables.provided:update_table(pind, get_items_in_network(data.provided, selected_network_id))
    itemTables.requested:update_table(pind, get_items_in_network(data.requested, selected_network_id))
    itemTables.transit:update_table(pind, data.in_transit or {})
    itemTables.details:set_item(pind)
    
    -- !DEBUG
    --[[
    if self:get(pind).test then self:get(pind).test.destroy() end    
    local testflow = self:get(pind).add{type = "flow", name ="test", direction = "horizontal"}
    local testtb = testflow.add{type = "table", name ="test", column_count = 2}
    local testlb = testtb.add{type = "label", caption = "LABEL"}
    testlb.style.height = 100
    local testframe = testtb.add{type = "frame", caption = "frame in table"}    
    testframe.style.vertically_stretchable = false
    testframe = testflow.add{type = "frame", caption = "frame outside of table"}     
    testframe.style.vertically_stretchable = false
    --]]
  else
    self:hide(pind)
  end 
end


return gcInvTab