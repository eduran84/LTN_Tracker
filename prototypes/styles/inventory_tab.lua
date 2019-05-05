local names = defs.styles.inventory_tab


default[names.stops_col_1] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  width = C.inventory_tab.details_tb_col_width_stations[1],
  single_line = false
}
default[names.stops_col_2] = {
  type = "label_style",
  parent = names.stops_col_1,
  width = C.inventory_tab.details_tb_col_width_stations[2],
}

default[names.del_col_1] = {
  type = "label_style",
  parent = names.stops_col_1,
  width = C.inventory_tab.details_tb_col_width_deliveries[1],
}
default[names.del_col_2] = {
  type = "label_style",
  width = C.inventory_tab.details_tb_col_width_deliveries[2],
}
default[names.del_col_3] = {
  type = "label_style",
  parent = names.stops_col_1,
  width = C.inventory_tab.details_tb_col_width_deliveries[3],
}

default[names.summary_number] = {
  type = "label_style",
	parent = "bold_label",
  font = "ltnt_font_default",
	horizontal_align = "right",
	width = C.inventory_tab.summary_number_width,
}