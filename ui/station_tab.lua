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
local ARROW_STYLE_ON = "ltnt_sort_button_on"
local ARROW_STYLE_OFF = "ltnt_sort_button_off"
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
  style = {vertical_align = "center", horizontally_stretchable = true},
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
  },
  event = {id = defines.events.on_gui_checked_state_changed, handler = {"on_checkbox_changed"}},
}
gcStopTab:add{
  name = "filler_flow",
  parent_name = "button_flow",
  params = {type = "flow", direction = "horizontal"},
  style = {horizontally_stretchable = true},
}
gcStopTab:add{
  name = "filter_label",
  parent_name = "button_flow",
  params = {
    type = "label",
    caption = {"station.filter_lb"},
    style = "ltnt_label_default",
  },
}
gcStopTab:add{
  name = "filter",
  parent_name = "button_flow",
  params = {type = "textfield", tooltip = {"station.filter_tt"}},
  event = {id = defines.events.on_gui_text_changed, handler = {"on_filter_changed"}},
}
-- header row
gcStopTab:add{
  name = "header_table",
  parent_name = "root",
  params = {type = "table", column_count = N_COLS, draw_horizontal_lines = true},
}
for i = 1,N_COLS do
  gcStopTab:add{
    name = "header_flow"..i,
    parent_name = "header_table",
    params = {
      type = "flow", direction = "horizontal"},
    style = {width = COL_WIDTH[i], vertical_align = "center"},
  }
  if i == 1 or i == 2 or i == 4 then
    gcStopTab:add{
      name = "arrow"..i,
      parent_name = "header_flow"..i,
      params = {type = "button", style = "ltnt_sort_button_off"},
      event = {id = defines.events.on_gui_click, handler = {"on_header_click"}, data = tostring(i)}
    }
    gcStopTab:add{
      name = "header"..i,
      parent_name ="header_flow"..i,
      params = {
        type = "label",
        caption={"station.header-col-"..i},
        tooltip={"station.header-col-"..i.."-tt"},
        style="ltnt_hover_column_header"
      },
      event = {id = defines.events.on_gui_click, handler = {"on_header_click"}, data = tostring(i)}
    }
  else
    gcStopTab:add{
      name = "header"..i,
      parent_name ="header_flow"..i,
      params = {
        type = "label",
        caption={"station.header-col-"..i},
        tooltip={"station.header-col-"..i.."-tt"},
        style="ltnt_column_header"
      },
    }
  end
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
  storage_tb[self.name].sort_by = storage_tb[self.name].sort_by or {}
  self.mystorage = storage_tb[self.name]
  for _,gc in pairs(self.sub_gc) do
    gc:on_init(storage_tb)
  end
end

function gcStopTab:build(parent, pind)
  GC.build(self, parent, pind) -- super method
  self.mystorage.checkbox[pind] = self:get_el(pind, "checkbox")
  self.mystorage.sort_by[pind] = "name"
end

-- additional methods
function gcStopTab:on_checkbox_changed(event)
  self:update(event.player_index, self.tab_index)
end

function gcStopTab:on_header_click(event, index, data_string)
  local name = event.element.name
  if data_string == "1" then
    self.mystorage.sort_by[event.player_index] = "name"
    self:get_el(event.player_index, "arrow1").style = ARROW_STYLE_ON
    self:get_el(event.player_index, "arrow2").style = ARROW_STYLE_OFF
    self:get_el(event.player_index, "arrow4").style = ARROW_STYLE_OFF
  elseif data_string == "2"  then
    self.mystorage.sort_by[event.player_index] = "state"
    self:get_el(event.player_index, "arrow2").style = ARROW_STYLE_ON
    self:get_el(event.player_index, "arrow1").style = ARROW_STYLE_OFF
    self:get_el(event.player_index, "arrow4").style = ARROW_STYLE_OFF
  elseif data_string == "4"  then
    self.mystorage.sort_by[event.player_index] = "deliveries"
    self:get_el(event.player_index, "arrow4").style = ARROW_STYLE_ON
    self:get_el(event.player_index, "arrow1").style = ARROW_STYLE_OFF
    self:get_el(event.player_index, "arrow2").style = ARROW_STYLE_OFF
  else
    return
  end
  self:update(event.player_index, self.tab_index)
end

local function trim(s)
  local from = s:match("^%s*()")
  return from > #s and "" or s:match(".*%S", from)
end
function gcStopTab:on_filter_changed(event, data_string)
  local elem = event.element
  if elem.text and type(elem.text) == "string" then
    local input = trim(elem.text)
    if input:len() == 0 then
      global.filter[event.player_index] = nil
    else
      global.filter[event.player_index] = input
    end
  end
  self:update(event.player_index, self.tab_index)
end

local get_stops
do
	-- map, key: actual station name, value: lowercased name
	local name2lowercase = setmetatable({}, {
		__index = function(self, stop_id)
			local name = global.data.stops[stop_id].name:lower()
			rawset(self, stop_id, name)
			return name
		end,
	})
  -- sort functions
  local sort = table.sort
  local color_order = {["signal-blue"] = 1, ["signal-yellow"] = 2, ["signal-green"] = 3}

  local get_sort_func = {
    ["name"] = function(a,b) return global.data.stops[a].name < global.data.stops[b].name end,
    ["state"] = function(a,b) return color_order[global.data.stops[a].signals[1][1]] < color_order[global.data.stops[b].signals[1][1]] end,
    ["deliveries"] = function(a,b) return #global.data.stops[a].activeDeliveries > #global.data.stops[b].activeDeliveries end,
  }
  local function sort_stops(stops, sort_by)
    sort(stops, get_sort_func[sort_by])
    return stops
  end

	get_stops = function(self, pind)
		if not global.filter[pind] then
      sort(global.data.stop_ids, get_sort_func[self.mystorage.sort_by[pind]])
      out.info("DEBUG", global.data.stops)
      return global.data.stop_ids
		else
			--if new_sort or global.last_filter[pind] or global.last_filter[pind] ~= global.filter[pind] then
      if global.last_filter[pind] or global.last_filter[pind] ~= global.filter[pind] then
				global.tempResults[pind] = {} -- rehash all results
				local lower = global.filter[pind]:lower()
				for _, station in next, global.data.stop_ids do
					local match = true
					for word in lower:gmatch("%S+") do
						if not name2lowercase[station]:find(word, 1, true) then match = false end
					end
					if match then table.insert(global.tempResults[pind], station) end
				end
				global.last_filter[pind] = global.filter[pind]
			end
      sort(global.tempResults[pind], get_sort_func[self.mystorage.sort_by[pind]])
      return global.tempResults[pind]
		end
	end
end

local btest = bit32.btest
local function eqtest(a,b) return a==b end
local build_item_table = require("ui.util").build_item_table
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
    local stops_to_list = get_stops(self, pind)
    for i = 1, #stops_to_list do
      local stop_id = stops_to_list[i]
      if stop_id and data.stops[stop_id] then
        local stopdata = data.stops[stop_id]
        if stopdata.errorCode == 0 and stopdata.isDepot == false and testfun(selected_network_id, stopdata.network_id) then
          -- stop is in selected network, create table entry
          -- first column: station name
          local label = tb.add{
            type = "label",
            caption = stopdata.name,
            style = "ltnt_lb_inv_station_name",
            name = self:_create_name(i+n, stop_id),
          }
          -- second column: status
          tb.add{
          type = "sprite-button",
          sprite = "virtual-signal/"..stopdata.signals[1][1],
          number = stopdata.signals[1][2],
          enabled = false,
          style = "ltnt_empty_button",
          }
          -- third column: provided and requested items
          build_item_table{
            parent = tb,
            provided = data.provided_by_stop[stop_id],
            requested = data.requested_by_stop[stop_id],
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
    end
   else
    self:hide(pind)
  end
end

function gcStopTab:event_handler(event, index, data_string)
  return "on_stop_name_clicked"
end

return gcStopTab
