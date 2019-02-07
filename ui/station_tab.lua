--[[
Layout:

------------ flow -------------
| <label> [textbox][checkbox] |  -- inside a flow
| ------ scroll-pane -------- |
| |<col1>   ......   <col5> | | > 5 column table listing stops
| |                         | | > col1 = name, col2 = networkID;
| |                         | | > col3 = items provided / requested
------------------------------- > col4 = control signals, col5 = current deliveries

--]]
local NAME = "stop_tab"
local N_COLS = 5
local ROW_HEIGHT = 34
local COL_WIDTH = require("ltnt.const").station_tab.header_col_width
local STATION_WIDTH = require("ltnt.const").station_tab.station_col_width
local MAX_ROWS = require("ltnt.const").station_tab.item_table_max_rows
local COL_COUNTS = require("ltnt.const").station_tab.item_table_col_count
local GC = require("ui.classes.GuiComposition")
local gcStopTab= GC(NAME, {
  params = {type = "flow", direction = "vertical"},
  style = {visible = false},
})
-- network id selector
gcStopTab:add{
  name = "button_flow",
  parent_name = "root",
  params = {type = "flow", direction = "horizontal"},
  style = {vertical_align = "center"},
}
gcStopTab:add{
  name = "idSelector",
  parent_name = "button_flow",
  gui_composition = require("ui.classes.TextFieldWithRange")(
    "IDSstop",
    {
      caption = {"inventory.id_selector-caption"},
      tooltip = {"inventory.id_selector-tt"},
    }
  )
}
gcStopTab:add{
  name = "checkbox",
  parent_name = "button_flow",
  params = {
    type = "checkbox",
    state = false,
    caption = {"station.check-box-cap"},
    tooltip = {"station.check-box-tt"},
  },
  event = {id = defines.events.on_gui_checked_state_changed, handler = {"on_checkbox_changed"}},
}

-- header row
gcStopTab:add{
  name = "header_table",
  parent_name = "root",
  params = {type = "table", column_count = N_COLS, draw_horizontal_lines = true},
  style = {vertical_align = "bottom"}
}
for i = 1,N_COLS do
  gcStopTab:add{
    name = "header"..i,
    parent_name = "header_table",
    params = {
      type = "label",
      caption={"station.header-col-"..i},
      tooltip={"station.header-col-"..i.."-tt"},
      style="ltnt_column_header"
    },
    style = {width = COL_WIDTH[i]}
  }
end

-- table for stations inside scroll-pane
gcStopTab:add{
  name = "scrollpane",
  parent_name = "root",
  params = {type = "scroll-pane", horizontal_scroll_policy = "never"},
}
gcStopTab:add{
  name = "table",
  parent_name = "scrollpane",
  params = {type = "table", column_count = N_COLS, draw_horizontal_lines = true},
  style = {vertical_align = "top"}
}
gcStopTab.tab_index = require("ltnt.const").station_tab.tab_index

-- overloaded methods
function gcStopTab:on_init(storage_tb)
  storage_tb[self.name] =  storage_tb[self.name] or {}
  storage_tb[self.name].root = storage_tb[self.name].root or {}
  storage_tb[self.name].checkbox = storage_tb[self.name].checkbox or {}
  self.mystorage = storage_tb[self.name]
  for _,gc in pairs(self.sub_gc) do
    gc:on_init(storage_tb)
  end
end

function gcStopTab:build(parent, pind)
  GC.build(self, parent, pind) -- super method
  self.mystorage.checkbox[pind] = self:get_el(pind, "checkbox")
end

-- additional methods
function gcStopTab:on_checkbox_changed(event)
  self:update(event.player_index, self.tab_index)
end

local btest = bit32.btest
local function eqtest(a,b) return a==b end
local build_item_table = require("ui.util").build_item_table
local get_control_signals = require("ltnt.util").get_control_signals
function gcStopTab:update(pind, index)
  if index == self.tab_index then
    self:show(pind)
    global.gui.active_tab[pind] = index

    local tb = self:get_el(pind, "table")
    tb.clear()

    -- table main body
    local selected_network_id = tonumber(self.sub_gc.idSelector:get_current_value(pind))
    local testfun
    if global.gui[self.name].checkbox[pind].state then
      testfun = eqtest
    else
      testfun = btest
    end
    local data = global.data
    local n = #self.elem
    local index = n + 1
    for stop_id,stopdata in pairs(data.stops) do
      if stopdata.errorCode == 0 and stopdata.isDepot == false and testfun(selected_network_id, stopdata.network_id) then
        -- stop is in selected network, create table entry
        -- first column: station name
        local label = tb.add{
          type = "label",
          caption = stopdata.name,
          style = "ltnt_hoverable_label",
          name = self:_create_name(index, stop_id),
        }
        label.style.single_line = false
        label.style.width = STATION_WIDTH
        index = index + 1
        -- second column: status
        tb.add{
				type = "sprite-button",
				sprite = stopdata.signals[1].name,
				number = stopdata.signals[1].count,
				enabled = false,
        style = "ltnt_empty_button",
        }
        -- third column: provided and requested items
        build_item_table{
          parent = tb,
          provided = data.stops[stop_id].provided,
          requested = data.stops[stop_id].requested,
          columns = COL_COUNTS[1],
          enabled = false,
          max_rows = MAX_ROWS[1],
        }
        -- fourth column: current deliveries
        build_item_table{
          parent = tb,
          provided = stopdata.incoming,
          requested = stopdata.outgoing,
          columns = COL_COUNTS[2],
          max_rows = MAX_ROWS[2],
          enabled = false,
        }
        -- fifth column: control signals
        build_item_table{parent = tb, signals = stopdata.signals[2], columns = COL_COUNTS[3], enabled = false}
      end
    end
   else
    self:hide(pind)
  end
end

function gcStopTab:event_handler(event, index, data_string)
  return "on_stop_name_clicked"
end

return gcStopTab
