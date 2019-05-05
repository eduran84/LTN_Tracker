default = data.raw["gui-style"].default
local shared_styles = defs.styles.shared

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
default[shared_styles.large_close_button] = {
  type = "button_style",
  parent = "red_icon_button",
  maximal_height = 22,
  minimal_height = 22,
  maximal_width = 22,
  minimal_width = 22,
  padding = 0,
}
default[shared_styles.slot_table_frame] = {
  type = "frame_style",
  parent = "frame",
  padding = 0,
  vertical_align = "center",
  minimal_height = 38,
  vertically_stretchable = "off",
	horizontally_stretchable = "off",
}

-- alert notifier
default[defs.styles.alert_notice.frame_caption] = {
  type = "label_style",
  parent = "heading_1_label",
  font_color = {},
  top_padding = 0,
  bottom_padding = 0,
  width = 90
}

-- station tab
default[defs.styles.station_tab.station_label] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  maximal_width = C.station_tab.col_width[1],
  minimal_width = C.station_tab.col_width[1],
  single_line = false,
}

-- history tab
local ht_names = defs.styles.hist_tab
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

-- alert tab
local at_styles = defs.styles.alert_tab
default[at_styles.label_col_1] = {
  type = "label_style",
  width = C.alert_tab.col_width[1],
}
default[at_styles.label_col_2_hover] = {
  type = "label_style",
  parent = "clickable_label",
  width = C.alert_tab.col_width[2],
}
default[at_styles.label_col_2] = {
  type = "label_style",
  width = C.alert_tab.col_width[2],
}
default[at_styles.label_col_3] = {
  type = "label_style",
  width = C.alert_tab.col_width[3],
  horizontal_align = "right",
  right_padding = 4,
}
default[at_styles.label_col_4] = {
	type = "label_style",
	parent = "bold_red_label",
  single_line = false,
  width = C.alert_tab.col_width[4],
}

require("prototypes.styles.depot_tab")
require("prototypes.styles.inventory_tab")