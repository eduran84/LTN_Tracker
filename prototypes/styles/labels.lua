local style_names = defs.styles

local default_orange_color = {r = 0.98, g = 0.66, b = 0.22}
local bright_red = {r = 1, g = 0, b = 0}
local SUMMARY_NUM_WIDTH = 100

add_style("ltnt_summary_number", {
  type = "label_style",
	parent = "bold_label",
  font = "ltnt_font_default",
	horizontal_align = "right",
	width = SUMMARY_NUM_WIDTH,
  vertical_align = "center"
})

add_style("ltnt_column_header", {
	type = "label_style",
	parent = "caption_label",
  font = "ltnt_font_bold"
})

-- station tab
local st_names = style_names.station_tab
default[st_names.station_label] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  maximal_width = C.station_tab.col_width[1],
  minimal_width = C.station_tab.col_width[1],
  single_line = false,
}
-- history tab
local ht_names = style_names.hist_tab
for i = 1, 5 do
  local parent = "label"
  if i == 2 then
    parent = "clickable_label"
  end
  default[ht_names["label_col_"..i]] = {
    type = "label_style",
    parent = parent,
    maximal_width = C.history_tab.column_width[i],
    minimal_width = C.history_tab.column_width[i],
    right_padding = 4,
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