-- GuiElement styles
local C = require("script.constants")
local default_gui = data.raw["gui-style"].default
local SUMMARY_NUM_WIDTH = 100
-- button styles
do
  -- tab selector at the top of the root frame
  default_gui["ltnt_tab_button"] = {
    type = "button_style",
    font = "ltnt_font_tab_caption",
    horizontal_align = "center",
    vertical_align = "center",
    disabled_font_color = {r=1, g=1, b=1},
    minimal_width = C.main_frame.button_width,
    maximal_width = C.main_frame.button_width,
  }
  -- highlighted alert tab selector at the top of the root frame
  default_gui["ltnt_tab_button_highlight"]  = {
    type = "button_style",
    parent = "ltnt_tab_button",
    default_graphical_set = {
      base = {position = {136, 17}, corner_size = 8},
      shadow = default_dirt
    },
    hovered_graphical_set = {
      base = {position = {170, 17}, corner_size = 8},
      shadow = default_dirt,
      glow = default_glow(default_glow_color, 0.5)
    },
    clicked_vertical_offset = 1, -- text/icon goes down on click
    clicked_graphical_set = {
      base = {position = {187, 17}, corner_size = 8},
      shadow = default_dirt
    },
  }

  -- depot selector button
  default_gui["ltnt_depot_button"]  = {
    type = "button_style",
    parent = "button",
    padding = 0,
    minimal_height = 100,
    maximal_height = 100,
    minimal_width = C.depot_tab.pane_width_left - 20,
    maximal_width = C.depot_tab.pane_width_left - 20,
    default_font_color = C.styles.font_color_black,
    hovered_font_color = C.styles.font_color_black,
    clicked_font_color = C.styles.font_color_black,
  }

  -- item buttons for inventory tab
  default_gui["ltnt_empty_button"] = {
    type = "button_style",
    parent = "slot_button",
    disabled_graphical_set = {
      border = 1,
      filename = "__core__/graphics/gui.png",
      position = {111, 0},
      size = 36,
      scale = 1
    }
  }
  default_gui["ltnt_provided_button"] = {
    type = "button_style",
    parent = "green_slot_button",
    disabled_graphical_set = {
      border = 1,
      filename = "__core__/graphics/gui.png",
      position = {111, 108},
      size = 36,
      scale = 1
    },
  }
  default_gui["ltnt_requested_button"] = {
    type = "button_style",
    parent = "red_slot_button",
    disabled_graphical_set = {
      border = 1,
      filename = "__core__/graphics/gui.png",
      position = {111, 36},
      size = 36,
      scale = 1
    },
  }

  -- sort triangle button in station table header
  default_gui["ltnt_sort_button_on"] = {
    type = "button_style",
    size = {16, 16},
    default_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-active.png",
      size = {16, 16},
      scale = 1
    },
    hovered_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-hover.png",
      size = {16, 16},
      scale = 1
    },
    clicked_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-active.png",
      size = {16, 16},
      scale = 1
    },
    disabled_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
      size = {16, 16},
      scale = 1
    }
  }
  default_gui["ltnt_sort_button_off"] = {
    type = "button_style",
    size = {16, 16},
    default_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
      size = {16, 16},
      scale = 1
    },
    hovered_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-hover.png",
      size = {16, 16},
      scale = 1
    },
    clicked_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
      size = {16, 16},
      scale = 1
    },
    disabled_graphical_set = {
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
      size = {16, 16},
      scale = 1
    }
  }
end

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
  font = "ltnt_font_default",
  hovered_font_color = {
    r = 0.5 * (1 + default_orange_color.r),
    g = 0.5 * (1 + default_orange_color.g),
    b = 0.5 * (1 + default_orange_color.b)
  },
  vertical_align = "center"
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