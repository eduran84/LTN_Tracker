default = data.raw["gui-style"].default
local shared_styles = defs.styles.shared

function add_style(name, style_definition)
  default[name] = style_definition
end
local default_gui = data.raw["gui-style"].default
-- table styles
do
default_gui["ltnt_table_default"] = {
  type = "table_style",
	parent = "table_with_selection",
}

default_gui["ltnt_shipment_table"] =
{
  type = "table_style",
  parent = "slot_table",
  vertical_align = "center",
  horizontal_align = "center",
  width = 34,
}
end

-- pane styles
default_gui["ltnt_sp_vertical"] =
{
  type = "scroll_pane_style",
  parent = "scroll_pane",
  vertical_scroll_policy = "auto",
  horizontal_scroll_policy = "never",
}

default_gui["ltnt_it_scroll_pane"] =
{
  type = "scroll_pane_style",
  vertical_scroll_policy = "auto-and-reserve-space",
  horizontal_scroll_policy = "never",
  vertical_align = "center",
}

default[shared_styles.no_frame_scroll_pane] = {
  type = "scroll_pane_style",
  parent = egm_defs.style_names.table.scroll_pane,
  padding = 0,
  horizontally_stretchable = "off",
}

default[shared_styles.default_button] = {
  type = "button_style",
  maximal_height = 32,
  minimal_height = 32,
  maximal_width = 32,
  minimal_width = 32,
  padding = 0,
}

-- frame styles
default_gui["ltnt_slot_table_frame"] =
{
  type = "frame_style",
  parent = "frame",
  padding = 0,
  vertical_align = "center",
  minimal_height = 38,
  vertically_stretchable = "off",
	horizontally_stretchable = "off",
}

require("prototypes.styles.buttons")
require("prototypes.styles.labels")
require("prototypes.styles.depot_tab")
require("prototypes.styles.inventory_tab")
require("prototypes.styles.alert_tab")