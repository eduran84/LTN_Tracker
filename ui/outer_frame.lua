local GC = require("ui.classes.GuiComposition")
local N_TABS = require("ltnc.const").main_frame.n_tabs
local BUTTON_WIDTH = require("ltnc.const").main_frame.button_width
local HIGHLIGHT_STYLE = require("ltnc.const").main_frame.button_highlight_style
local DEFAULT_STYLE = require("ltnc.const").main_frame.button_default_style
local name = "outer_frame"

local gcOuterFrame = GC(name)
do -- for code folding

gcOuterFrame:add{
  name = "root",
  params = {
		type = "frame",
		direction = "vertical",
    name = "ltnc_main_frame"
	},
	style = {height = 500, top_padding = 10},
}

-- flow for title and refresh button
gcOuterFrame:add{
  name = "title_flow",
  parent_name = "root",
  params = {type = "flow", direction = "horizontal"},
}
gcOuterFrame:add{
  name = "title_lb",
  parent_name = "title_flow",
  params = {type = "label", caption = {"ltng.ltn_companion"}},
  style = {font = "ltnc_font_frame_caption"},
}
gcOuterFrame:add{
  name = "spacer_flow",
  parent_name = "title_flow",
  params = {type = "flow", direction = "horizontal"},
  style = {horizontally_stretchable = true},
}
gcOuterFrame:add{
  name = "refresh_bt",
  parent_name = "title_flow",
  params = {
    type = "sprite-button",
    sprite = "ltnc_sprite_refresh",
    tooltip = {"ltng.refresh-bt"},
  },
  event = {id = defines.events.on_gui_click, handler = "on_refresh_bt_click"},
}

-- flow for tab selector buttons
gcOuterFrame:add{
  name = "button_flow",
  parent_name = "root",
  params = {
    type="flow",
    direction="horizontal"
  },
}
for i = 1, N_TABS do
	gcOuterFrame:add{
    name= "tabbutton_" .. i,
    parent_name = "button_flow",
    params = {
      type="button",
      caption={"ltng.tab"..i.."-caption"},
      style = "ltnc_tab_button"
    },
    style = {width = BUTTON_WIDTH},
    event = {
      id = defines.events.on_gui_click,
      data = i,
      handler = "on_tab_changed",
    }
  }
end
gcOuterFrame:element_by_name("tabbutton_1").params.enabled = false
--[[gcOuterFrame:add{
  name = "alert_sprite",
  parent_name = "tabbutton_5",
  params = {type = "sprite", sprite = "ltnc_warning_sign_sprite"}
}--]]

end --do

-- overloaded methods
function gcOuterFrame:build(parent, pind)
	GC.build(self, parent, pind)
	self:get(pind).style.height = settings.get_player_settings(game.players[pind])["ltnc-window-height"].value
end

function gcOuterFrame:toggle(pind)
	local new_state = GC.toggle(self, pind)
	if new_state then
		game.players[pind].opened = self:get(pind)
  else
		game.players[pind].opened = nil
	end
  global.gui.is_gui_open[pind] = new_state
	return new_state
end

function gcOuterFrame:hide(pind)
	GC.hide(self, pind)
	game.players[pind].opened = nil
  global.gui.is_gui_open[pind] = false
end

function gcOuterFrame:show(pind)
	if self:get(pind) then
		self:get(pind).style.visible = true
		game.players[pind].opened = self:get(pind)
    global.gui.is_gui_open[pind] = true
	end
end

function gcOuterFrame:set_alert(pind)
  if global.gui.active_tab ~= 5 then
    local bt = self:get_el(pind, "tabbutton_5")
    bt.style = HIGHLIGHT_STYLE
    bt.style.width = BUTTON_WIDTH
  end
end

function gcOuterFrame:clear_alert(pind)
  local bt = self:get_el(pind, "tabbutton_5")
  bt.style = DEFAULT_STYLE
  bt.style.width = BUTTON_WIDTH
end
-- additional methods
function gcOuterFrame:update_buttons(pind, new_tab)
	local tab_buttons = self:get_buttons(pind)
	for i = 1, N_TABS do
		tab_buttons[i].enabled = true
	end
	tab_buttons[new_tab].enabled = false
  global.gui.active_tab[pind] = new_tab
  if new_tab == 5 then
    self:clear_alert(pind)
  end
end

function gcOuterFrame:get_buttons(pind)
	local buttons = {}
	for i = 1, N_TABS do
		buttons[i] = self:get_el(pind, "tabbutton_"..i)
	end
	return buttons
end

return gcOuterFrame