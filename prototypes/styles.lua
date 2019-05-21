default = data.raw["gui-style"].default

local function default_glow(tint_value, scale_value)  -- because some moronic mods out there overwrite this function...
  return
  {
    position = {200, 128},
    corner_size = 8,
    tint = tint_value,
    scale = scale_value,
    draw_type = "outer"
  }
end

------------------------------------------------------------------------------------
-- shared
------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------
-- alert popup
------------------------------------------------------------------------------------
default[defs.styles.alert_notice.frame_caption] = {
  type = "label_style",
  parent = "heading_1_label",
  font_color = {},
  top_padding = 0,
  bottom_padding = 0,
  width = 90
}

------------------------------------------------------------------------------------
-- depot tab
------------------------------------------------------------------------------------
local names = defs.styles.depot_tab
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
default[names.depot_selector] = {
  type = "button_style",
  parent = "button",
  padding = 0,
  minimal_height = 100,
  maximal_height = 100,
  minimal_width = C.depot_tab.pane_width_left - 20,
  maximal_width = C.depot_tab.pane_width_left - 20,
}
default[names.depot_label] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  width = C.depot_tab.col_width_left[1]
}
default[names.cap_left_1] = {
  type = "label_style",
  font = "ltnt_font_depot_caption",
  font_color = {},
  width = C.depot_tab.col_width_left[2]
}
default[names.cap_left_2] = {
  type = "label_style",
  font = "ltnt_font_depot_value",
  width = C.depot_tab.col_width_left[3]
}
default[names.cap_left_3] = {
  type = "label_style",
  font = "ltnt_font_depot_caption",
  font_color = {},
  width = C.depot_tab.col_width_left[4]
}

------------------------------------------------------------------------------------
-- station tab
------------------------------------------------------------------------------------
default[defs.styles.station_tab.station_label] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  maximal_width = C.station_tab.col_width[1],
  minimal_width = C.station_tab.col_width[1],
  single_line = false,
}

------------------------------------------------------------------------------------
-- inventory tab
------------------------------------------------------------------------------------
names = defs.styles.inventory_tab
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
	horizontal_align = "right",
	width = C.inventory_tab.summary_number_width,
}

default[names.filter_button] = {
  type = "button_style",
	parent = "tool_button",
  padding = -2,
  disabled_graphical_set = {
    base = {
      corner_size = 8,
      position = {225, 17},
    },
  }
}

------------------------------------------------------------------------------------
-- history tab
------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------
-- alert tab
------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------
-- stats tab
------------------------------------------------------------------------------------

local st_styles = defs.styles.stats_tab
default[st_styles.time_button] = {
  type = "button_style",
  disabled_font_color = default["button"].selected_font_color,
  disabled_graphical_set = default["button"].selected_graphical_set,
}
default[st_styles.graph_area] = {
  type = "frame_style",
  parent = defs.styles.shared.no_padding_frame,
  flow_style = {
    type = "flow_style",
    vertical_spacing = 0,
    padding = 0,
    horizontal_spacing = 0,
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    parent = defs.styles.shared.vertical_container,
    vertical_spacing = 0,
  },
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    parent = defs.styles.shared.horizontal_container,
    vertical_align = "bottom",
  },
  graphical_set = {
    base = {},
    shadow = default_glow({0.7, 0.7, 0.7}, 0.5),
  },
}
default[st_styles.graph_box_green] = {
  type = "frame_style",
  parent = defs.styles.shared.no_padding_frame,
  graphical_set = {
    base = {center = {position = {439, 56}, size = {1, 1}}},
    shadow = default_dirt,
  }
}
default[st_styles.graph_box_red] = {
  type = "frame_style",
  parent = defs.styles.shared.no_padding_frame,
  graphical_set = {
    base = {center = {position = {388, 56}, size = {1, 1}}},
    shadow = default_dirt,
  }
}