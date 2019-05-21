local egm_defs = require("__GUI_Modules__.defines")
local defs = {
  pathes = {},
}

defs.mod_name = "LTN_Tracker"
defs.mod_prefix = "ltnt"

local mod_prefix = defs.mod_prefix .. "_"
defs.settings = {
  debug_mode = mod_prefix .. "debug_level",
  window_location = mod_prefix .. "window_location",
  window_height = mod_prefix .. "window_height",
  show_alerts = mod_prefix .. "show_alert_popups",
  refresh_interval = mod_prefix .. "refresh_interval",
  fade_timeout = mod_prefix .. "fade_timeout",
  station_click_action = mod_prefix .. "station_click_behavior",
  history_limit = mod_prefix .. "history_limit",
  disable_underload = mod_prefix .. "disable_underload_alert",
}

defs.names = {
  ltn = "LogisticTrainNetwork",
  ltnc = "LTN_Combinator",
  window = mod_prefix .. "main_window",
  sidebar = mod_prefix .. "sidebar",
  alert_popup = mod_prefix .. "alert_popup_window",
}

defs.tabs = {  -- order matters
  depot = "depot_tab",
  station = "station_tab",
  --requests = "request_tab",
  inventory = "inventory_tab",
  history = "history_tab",
  alert = "alert_tab",
  statistics = "statistics_tab",
}

defs.actions = {
  update_tab = "update_single_tab",
  refresh_button = "refresh_button_clicked",
  show_alerts = "open_alert_tab",
  close_popup = "close_alert_popup",

  show_depot_details = "show_depot_details",
  send_to_depot = "send_to_depot",

  show_item_details = "show_item_details",
  filter_items = "filter_items",

  update_filter = "filter_changed",

  clear_history = "clear_history_table",

  clear_alerts = "clear_alert_table",
  clear_single_alert = "clear_single_alert",

  set_stats_item = "set_stats_item",
  set_stats_time = "set_stats_time",

  station_name_clicked = "station_name_clicked",
  select_station_entity = "select_station",
  select_ltnc = "select_combinator",
  select_entity = "select_entity",
}

defs.functions = {
  id_selector_valid = "is_integer",
  depot_row_constructor = "dt_row_constructor",
  depot_sort = "dt_sort_function_col_",
  station_row_constructor = "st_row_constructor",
  station_sort = "st_sort_function_col_",
  requests_row_constructor = "rt_row_constructor",
  hist_row_constructor = "ht_row_constructor",
  hist_sort = "ht_sort_function_col_",
  alert_row_constructor = "alert_row_constructor",
  alert_sort = "at_sort_function_col_",
}

defs.styles = {
  shared = {
    tab_button = egm_defs.style_names.tabbed_pane.button,
    tab_button_red = egm_defs.style_names.tabbed_pane.button_red,
    default_button = mod_prefix .. "default_button",
    no_padding_frame = egm_defs.style_names.shared.no_padding_frame,
    large_close_button = mod_prefix .. "large_close_button",
    slot_table_frame = mod_prefix .. "ltnt_slot_table_frame",
    no_frame_scroll_pane = mod_prefix .. "bare_scroll_pane",
    horizontal_spacer = egm_defs.style_names.shared.horizontal_spacer,
    horizontal_container = egm_defs.style_names.shared.horizontal_container,
    vertical_container = egm_defs.style_names.shared.vertical_container,
    red_button = egm_defs.style_names.item_table.red_button,
    green_button = egm_defs.style_names.item_table.green_button,
    gray_button = egm_defs.style_names.item_table.gray_button,
  },
  depot_tab = {
    depot_selector = mod_prefix .. "depot_selector",
    depot_label = mod_prefix .. "depot_name_label",
    cap_left_1 = mod_prefix .. "bt_caption_1",
    cap_left_2 = mod_prefix .. "bt_caption_2",
    cap_left_3 = mod_prefix .. "bt_caption_3",
    cap_left_4 = mod_prefix .. "bt_caption_4",
    label_col_1 = mod_prefix .. "lb_depot_col1",
    label_col_2 = mod_prefix .. "lb_depot_col2",
    label_col_2_bold = mod_prefix .. "lb_depot_col2_bold",
  },
  inventory_tab = {
    filter_button = mod_prefix .. "filter_button",
    summary_number = mod_prefix .. "summary_number",
    stops_col_1 = mod_prefix .. "lb_inv_stop_1",
    stops_col_2 = mod_prefix .. "lb_inv_stop_2",
    del_col_1 = mod_prefix .. "lb_inv_del_1",
    del_col_2 = mod_prefix .. "lb_inv_del_2",
    del_col_3 = mod_prefix .. "lb_inv_del_3",
  },
  station_tab = {
    station_label = mod_prefix .. "lb_station",
  },
  hist_tab = {
    label_col_1 = mod_prefix .. "lb_hist_col1",
    label_col_2 = mod_prefix .. "lb_hist_col2",
    label_col_3 = mod_prefix .. "lb_hist_col3",
    label_col_4 = mod_prefix .. "lb_hist_col4",
    label_col_4_red = mod_prefix .. "lb_hist_col4_red",
    label_col_5 = mod_prefix .. "lb_hist_col5",
  },
  alert_tab = {
    label_col_1 = mod_prefix .. "lb_alert_col1",
    label_col_2 = mod_prefix .. "lb_alert_col2",
    label_col_2_hover = mod_prefix .. "lb_alert_col2_hover",
    label_col_3 = mod_prefix .. "lb_alert_col3",
    label_col_4 = mod_prefix .. "lb_alert_col4",
  },
  stats_tab = {
    graph_area = mod_prefix .. "graph_area_frame",
    graph_box_green = mod_prefix .. "graph_box_green",
    graph_box_red = mod_prefix .. "graph_box_red",
    time_button = mod_prefix .. "time_button",
  },
  alert_notice = {
    frame = egm_defs.style_names.frame.outer_frame_red_transparent,
    frame_caption = mod_prefix .. "lb_alert_frame_caption",
  },
}

defs.locale = {
  provided_requested = {"station.header-col-4"},
  scheduled_deliveries = {"station.header-col-5"},
  control_signals = {"station.header-col-6"},
  n_trains = {"depot.header-col-2"},
  capacity = {"depot.header-col-3"},
}

defs.controls = {
  toggle_hotkey = mod_prefix .. "toggle_hotkey",
  refresh_hotkey = mod_prefix .. "refresh_hotkey",
  toggle_filter = mod_prefix .. "toggle_filter",
  shortcut = mod_prefix .. "toggle_shortcut",
}

defs.remote = {
  ltn = "logistic-train-network",
  ltn_stop_update = "on_stops_updated",
  ltn_dispatcher_update = "on_dispatcher_updated",
  ltn_pickup_complete = "on_delivery_pickup_complete",
  ltn_delivery_failed = "on_delivery_failed",
  ltn_delivery_completed = "on_delivery_completed",
  ltnc_interface = "ltn-combinator",
  ltnc_close = "close_ltn_combinator",
}

defs.errors = {
  residuals = {
    caption = {"error.train-leftover-cargo"},
    tooltip = {"error.train-leftover-cargo-tt"},
  },
  incorrect_cargo = {
    caption = {"error.train-incorrect-cargo"},
    tooltip = {"error.train-incorrect-cargo-tt"},
  },
  incorrect_cargo = {
    caption = {"error.train-incorrect-cargo"},
    tooltip = {"error.train-incorrect-cargo-tt"},
  },
  timeout_post = {
    caption = {"error.train-timeout-post-pickup"},
    tooltip = {"error.train-timeout-post-pickup-tt"},
  },
  timeout_pre = {
    caption = {"error.train-timeout-pre-pickup"},
    tooltip = {"error.train-timeout-pre-pickup-tt"},
  },
  train_invalid = {
    caption = {"error.train-invalid"},
    tooltip = {"error.train-invalid-tt"},
  },
}

defs.signals = {
  network_id = "virtual-signal/ltn-network-id",
}
local gui_modules = "__GUI_Modules__/"
local optera_lib = "__OpteraLib__/script/"
local LTNT = "__LTN_Tracker_beta__/"
local script = LTNT .. "script/"
local gui = LTNT .. "gui/"
defs.pathes.modules = {
  olib_logger = optera_lib .. "logger",
  olib_misc = optera_lib .. "misc",
  olib_train = optera_lib .. "train",
  import_egm = gui_modules .. "import",

  util = script .. "extended_util",
  data_processing = script .. "data_processing",
  state_handlers = script .. "state_handlers",
  cache_item_data = script .. "functions/cache_item_data",

  gui_main = gui .. "main_window",
  gui_sidebar = gui .. "sidebar_window",
  constants = gui .. "constants",
  depot_tab = gui .. "depot_tab",
  inventory_tab = gui .. "inventory_tab",
  request_tab = gui .. "request_tab",
  station_tab = gui .. "station_tab",
  history_tab = gui .. "history_tab",
  alert_tab = gui .. "alert_tab",
  statistics_tab = gui .. "stats_tab",

  build_item_table = gui .. "functions/build_item_table",
  build_depot_button = gui .. "functions/build_depot_button",
  bar_graph = gui .. "functions/bar_graph",
}

defs.pathes.sprites = {
  gui_spritesheet = gui_modules .. "graphics/gui.png",
  shortcut_icon_32 = LTNT .. "graphics/shortcut_x32.png",
  shortcut_icon_24 = LTNT .. "graphics/shortcut_x24.png",
  shortcut_icon_24_white = LTNT .. "graphics/shortcut_x24_white.png",
}

defs.item_display_blacklist = {
  ["blueprint-book"] = true,
  ["selection-tool"] = true,
  ["blueprint"] = true,
  ["copy-paste-tool"] = true,
  ["deconstruction-item"] = true,
  ["upgrade-item"] = true,
  ["rail-planner"] = true,
}
return defs