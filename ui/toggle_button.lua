local NAME = "toggle_button"
local GC = require("ui.classes.GuiComposition")

local TB_WITH_ALERT_SPRITE = require("ltnc.const").main_frame.button_sprite_alert
local TB_WITHOUT_ALERT_SPRITE = require("ltnc.const").main_frame.button_sprite_bare

local gcTB = GC(NAME, {
  params = {
		type = "sprite-button",
		sprite = TB_WITHOUT_ALERT_SPRITE,
		tooltip = {"ltng.main-button-tooltip"},
	},
  event = {id = defines.events.on_gui_click, handler = "on_toggle_button_click"}
})

function gcTB:set_alert(pind)
  if global.gui.is_gui_open[pind] == false then
    self:get(pind).sprite = TB_WITH_ALERT_SPRITE  
  end 
end
function gcTB:clear_alert(pind)
  self:get(pind).sprite = TB_WITHOUT_ALERT_SPRITE
end

return gcTB