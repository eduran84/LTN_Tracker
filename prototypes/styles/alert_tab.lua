local names = defs.styles.alert_tab

default[names.label_col_1] = {
  type = "label_style",
  width = C.alert_tab.col_width[1],
}
default[names.label_col_2_hover] = {
  type = "label_style",
  parent = "clickable_label",
  width = C.alert_tab.col_width[2],
}
default[names.label_col_2] = {
  type = "label_style",
  width = C.alert_tab.col_width[2],
}
default[names.label_col_3] = {
	type = "label_style",
	parent = "bold_red_label",
  single_line = false,
  width = C.alert_tab.col_width[3],
}