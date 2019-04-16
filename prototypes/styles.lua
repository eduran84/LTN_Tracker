-- GuiElement styles
C = require("script.constants")
function add_style(name, style_definition)
  data.raw["gui-style"].default[name] = style_definition
end
require("prototypes.styles.buttons")



local default_gui = data.raw["gui-style"].default
local SUMMARY_NUM_WIDTH = 100
-- label styles
local default_orange_color = {r = 0.98, g = 0.66, b = 0.22}
local bright_red = {r = 1, g = 0, b = 0}
do
default_gui["ltnt_label_default"] = {
  type = "label_style",
  font = "ltnt_font_default",
  vertical_align = "center"
}

default_gui["ltnt_summary_label"] = {
  type = "label_style",
	parent = "bold_label",
  font = "ltnt_font_bold",
  vertical_align = "center"
}

default_gui["ltnt_summary_number"] = {
  type = "label_style",
	parent = "bold_label",
  font = "ltnt_font_default",
	horizontal_align = "right",
	width = SUMMARY_NUM_WIDTH,
  vertical_align = "center"
}

default_gui["ltnt_number_label"] = {
  type = "label_style",
  font = "ltnt_font_depot_value",
}

default_gui["ltnt_depot_caption"] = {
  type = "label_style",
  font = "ltnt_font_depot_caption",
  font_color = {},
}

default_gui["ltnt_hoverable_label"] = {
  type = "label_style",
  parent = "clickable_label",
  vertical_align = "center",
}

default_gui["ltnt_hover_bold_label"] = {
  type = "label_style",
  font = "ltnt_font_bold",
  hovered_font_color = {
    r = 0.5 * (1 + default_orange_color.r),
    g = 0.5 * (1 + default_orange_color.g),
    b = 0.5 * (1 + default_orange_color.b)
  },
  vertical_align = "center"
}

default_gui["ltnt_column_header"] = {
	type = "label_style",
	parent = "caption_label",
  font = "ltnt_font_bold"
}

default_gui["ltnt_hover_column_header"] = {
	type = "label_style",
	parent = "ltnt_hover_bold_label",
  font_color = default_orange_color
}

default_gui["ltnt_error_label"] = {
	type = "label_style",
	parent = "ltnt_label_default",
  font = "ltnt_font_bold",
  font_color = bright_red,
  single_line = false
}

default_gui["ltnt_lb_inv_station_name"] = {
  type = "label_style",
  parent = "ltnt_hoverable_label",
  maximal_width = C.station_tab.station_col_width,
  minimal_width = C.station_tab.station_col_width,
  single_line = false,
}
for i = 1, 4 do
default_gui["ltnt_lb_hist_col"..i] = {
  type = "label_style",
  parent = "ltnt_label_default",
  maximal_width = C.history_tab.col_width[i],
  minimal_width = C.history_tab.col_width[i],
}
end
default_gui["ltnt_lb_hist_col5"] = {
  type = "label_style",
  parent = "ltnt_label_default",
  maximal_width = C.history_tab.col_width[5],
  minimal_width = C.history_tab.col_width[5],
  horizontal_align = "right",
}
default_gui["ltnt_lb_hist_col5_red"] = {
  type = "label_style",
  parent = "ltnt_label_default",
  font_color = {r = 1, g = 0, b = 0},
  horizontal_align = "right",
  maximal_width = C.history_tab.col_width[5],
  minimal_width = C.history_tab.col_width[5],
}
end
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

-- textbox styles

default_gui["ltnt_invalid_value_tf"] =
{
  type = "textbox_style",
  default_background =
  {
    filename = "__core__/graphics/gui.png",
    corner_size = 3,
    position = {16, 16},
    scale = 1
  },
  active_background =
  {
    filename = "__core__/graphics/gui.png",
    corner_size = 3,
    position = {16, 16},
    scale = 1
  }
}