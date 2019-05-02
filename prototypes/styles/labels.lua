local style_names = defs.names.styles

local default_orange_color = {r = 0.98, g = 0.66, b = 0.22}
local bright_red = {r = 1, g = 0, b = 0}
local SUMMARY_NUM_WIDTH = 100

add_style("ltnt_label_default", {
  type = "label_style",
  font = "ltnt_font_default",
  vertical_align = "center"
})

add_style("ltnt_summary_label", {
  type = "label_style",
	parent = "bold_label",
  font = "ltnt_font_bold",
  vertical_align = "center"
})

add_style("ltnt_summary_number", {
  type = "label_style",
	parent = "bold_label",
  font = "ltnt_font_default",
	horizontal_align = "right",
	width = SUMMARY_NUM_WIDTH,
  vertical_align = "center"
})

add_style("ltnt_number_label", {
  type = "label_style",
  font = "ltnt_font_depot_value",
})

add_style("ltnt_depot_caption", {
  type = "label_style",
  font = "ltnt_font_depot_caption",
  font_color = {},
})

add_style("ltnt_hoverable_label", {
  type = "label_style",
  parent = "clickable_label",
  vertical_align = "center",
})

add_style("ltnt_hover_bold_label", {
  type = "label_style",
  font = "ltnt_font_bold",
  hovered_font_color = {
    r = 0.5 * (1 + default_orange_color.r),
    g = 0.5 * (1 + default_orange_color.g),
    b = 0.5 * (1 + default_orange_color.b)
  },
  vertical_align = "center"
})

add_style("ltnt_column_header", {
	type = "label_style",
	parent = "caption_label",
  font = "ltnt_font_bold"
})

add_style("ltnt_hover_column_header", {
	type = "label_style",
	parent = "ltnt_hover_bold_label",
  font_color = default_orange_color
})

add_style("ltnt_error_label", {
	type = "label_style",
	parent = "ltnt_label_default",
  font = "ltnt_font_bold",
  font_color = bright_red,
  single_line = false
})

add_style("ltnt_lb_inv_station_name", {
  type = "label_style",
  parent = "ltnt_hoverable_label",
  maximal_width = C.station_tab.station_col_width,
  minimal_width = C.station_tab.station_col_width,
  single_line = false,
})

-- station tab
local st_names = style_names.station_tab
default[st_names.station_label] = {
  type = "label_style",
  parent = "ltnt_hoverable_label",
  maximal_width = C.station_tab.col_width[1],
  minimal_width = C.station_tab.col_width[1],
  single_line = false,
}

-- history tab
local ht_names = style_names.hist_tab
for i = 1, 5 do
  local parent = "ltnt_label_default"
  if i == 2 then
    parent = "ltnt_hoverable_label"
  end
  default[ht_names["label_col_"..i]] = {
    type = "label_style",
    parent = parent,
    maximal_width = C.history_tab.column_width[i],
    minimal_width = C.history_tab.column_width[i],
  }
end
default[ht_names.label_col_3].horizontal_align = "right"
default[ht_names.label_col_4].horizontal_align = "right"
default[ht_names.label_col_5].horizontal_align = "right"
default[ht_names.label_col_4_red] = {
  type = "label_style",
  parent = ht_names.label_col_4,
  font_color = bright_red,
}