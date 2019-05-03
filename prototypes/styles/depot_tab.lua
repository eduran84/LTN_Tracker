local names = defs.names.styles.depot_tab

default[names.label_col_1] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  width = C.depot_tab.col_width_right[1],
}

default[names.label_col_2] = {
  type = "label_style",
  width = C.depot_tab.col_width_right[2],
}

default[names.label_col_2_bold] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  width = C.depot_tab.col_width_right[2],
}

-- depot selector button
default[names.depot_selector] = {
  type = "button_style",
  parent = "button",
  padding = 0,
  minimal_height = 100,
  maximal_height = 100,
  minimal_width = C.depot_tab.pane_width_left - 20,
  maximal_width = C.depot_tab.pane_width_left - 20,
}

default[names.bt_inner_flow] = {
  type = "vertical_flow_style",
  vertical_spacing = 0,
  ignored_by_interaction = true,
}
default[names.depot_label] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  ignored_by_interaction = true,
  width = C.depot_tab.col_width_left[1]
}
default[names.cap_left_1] = {
  type = "label_style",
  font = "ltnt_font_depot_caption",
  font_color = {},
  ignored_by_interaction = true,
  width = C.depot_tab.col_width_left[2]
}
default[names.cap_left_2] = {
  type = "label_style",
  font = "ltnt_font_depot_value",
  ignored_by_interaction = true,
  width = C.depot_tab.col_width_left[3]
}
default[names.cap_left_3] = {
  type = "label_style",
  font = "ltnt_font_depot_caption",
  font_color = {},
  ignored_by_interaction = true,
  width = C.depot_tab.col_width_left[4]
}


