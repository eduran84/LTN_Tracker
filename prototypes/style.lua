-- fonts and sprites
data:extend({
  {
    type = "font",
    name = "ltnt_font_default",
    from = "default",
    size = 14
  },
  {
    type = "font",
    name = "ltnt_font_bold",
    from = "default-bold",
    size = 14
    },
  {
    type = "font",
    name = "ltnt_font_tab_caption",
    from = "default-semibold",
    size = 18
  },
  {
    type = "font",
    name = "ltnt_font_frame_caption",
    from = "default-semibold",
    size = 20
  },
  {
    type = "font",
    name = "ltnt_font_subheading",
    from = "default",
    size = 18
  },
  {
    type = "sprite",
    name = "ltnt_sprite_refresh",
    filename = "__core__/graphics/reset.png",
    priority = "high",
    width = 128,
    height = 128,
    scale = 0.25,
  },
  {
    type = "sprite",
    name = "ltnt_sprite_delete",
    filename = "__core__/graphics/remove-icon.png",
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = "ltnt_sprite_enter",
    filename = "__core__/graphics/enter-icon.png",
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = "ltnt_sprite_search",
    filename = "__core__/graphics/search-icon.png",
    priority = "high",
    width = 32,
    height = 32,
  },
  {
    type = "sprite",
    name = "ltnt_bt_alert_sprite",
    filename = "__LTN_Tracker__/graphics/bt_with_alert.png",
    priority = "high",
    width = 128,
    height = 128,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = "ltnt_bt_sprite",
    filename = "__base__/graphics/technology/railway.png",
    priority = "high",
    width = 128,
    height = 128,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = "ltnt_warning_sign_sprite",
    filename = "__core__/graphics/warning-icon.png",
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
})

-- GuiElement styles
local C = require("ltnt.const")
local default_gui = data.raw["gui-style"].default
local SUMMARY_NUM_WIDTH = 100

-- button styles
do
default_gui["ltnt_button_default"] =
{
    type = "button_style",
    font = "ltnt_font_default",
    align = "center",
    vertical_align = "center"
}
default_gui["ltnt_tab_button"] =
{
  type = "button_style",
  font = "ltnt_font_tab_caption",
  align = "center",
  vertical_align = "middle-center",
  disabled_font_color = {r=1, g=1, b=1},
  disabled_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 40}
  },
  hovered_font_color = {r=0.5, g=0.5, b=0.5},
  hovered_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 16}
  },
}
default_gui["ltnt_tab_button_highlight"]  =
{
  type = "button_style",
  font = "ltnt_font_tab_caption",
  align = "middle-center",
  padding = 5,
  hovered_font_color = {r=0, g=0, b=0},
  hovered_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 8}
  },
  default_font_color = {r=1, g=1, b=1},
  default_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 8}
  },
  disabled_font_color = {r=1, g=1, b=1},
  disabled_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 40}
  },
  clicked_font_color = {r=0.5, g=0.5, b=0.5},
  clicked_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 16}
  },
}

default_gui["ltnt_depot_button"]  =
{
  type = "button_style",
  parent = "button",
  padding = 0,
  minimal_height = 100,
  maximal_height = 100,
  hovered_font_color = {r=0.5, g=0.5, b=0.5},
  hovered_graphical_set =
  {
    type = "composition",
    filename = "__core__/graphics/gui.png",
    priority = "extra-high-no-scale",
    load_in_minimal_mode = true,
    corner_size = {3, 3},
    position = {0, 16}
  },
}

default_gui["ltnt_empty_button"] =
{
  type = "button_style",
  parent = "slot_button",
  disabled_graphical_set =
  {
    type = "monolith",
    monolith_border = 1,
    monolith_image =
    {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 36,
      height = 36,
      x = 111
    }
  }
}

default_gui["ltnt_provided_button"] =
{
  type = "button_style",
  parent = "green_slot_button",
  disabled_graphical_set =
  {
    type = "monolith",
    monolith_border = 1,
    monolith_image =
    {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 36,
      height = 36,
      x = 111,
      y = 108
    }
  },
}

default_gui["ltnt_requested_button"] =
{
  type = "button_style",
  parent = "red_slot_button",
  disabled_graphical_set =
  {
    type = "monolith",
    monolith_border = 1,
    monolith_image = {
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      width = 36,
      height = 36,
      x = 111,
      y = 36
    }
  },
}

default_gui["ltnt_sort_button_on"] =
{
  type = "button_style",
  width = 22,
  height = 12,
  default_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/indication-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  },
  hovered_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/indication-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  },
  clicked_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/indication-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  },
  disabled_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/indication-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  }
}

default_gui["ltnt_sort_button_off"] =
{
  type = "button_style",
  width = 22,
  height = 12,
  default_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/inactive-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  },
  hovered_graphical_set =
  {
    type = "monolith",
    onolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/inactive-arrow-gui-descending-hovered.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  },
  clicked_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/inactive-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
  },
  disabled_graphical_set =
  {
    type = "monolith",
    monolith_border = 0,
    monolith_image =
    {
      filename = "__core__/graphics/arrows/inactive-arrow-gui-descending.png",
      priority = "extra-high-no-scale",
      width = 44,
      height = 24
    }
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
	align = "right",
	width = SUMMARY_NUM_WIDTH,
  vertical_align = "center"
}

default_gui["ltnt_number_label"] = {
  type = "label_style",
  font = "ltnt_font_default",
  font_color = default_orange_color,
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
  align = "right",
}
default_gui["ltnt_lb_hist_col5_red"] = {
  type = "label_style",
  parent = "ltnt_label_default",
  font_color = {r = 1, g = 0, b = 0},
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
  align = "center",
  width = 34,
}
end

-- pane styles
default_gui["ltnt_sp_vertical"] =
{
  type = "scroll_pane_style",
  parent = "scroll_pane",
  vertical_scroll_policy = "auto-and-reserve-space",
  horizontal_scroll_policy = "never",
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