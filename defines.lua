local egm_defs = require("__GUI_Modules__.defines")
local defs = {
  pathes = {},
}

local mod_prefix = "ltnt"

defs.mod_name = "LTN_Tracker"
defs.mod_prefix = mod_prefix
defs.gui_events = {defines.events.on_gui_click, defines.events.on_gui_checked_state_changed, defines.events.on_gui_text_changed} -- events handled by on_gui_event
defs.names = {
  ltn = "LogisticTrainNetwork",
  ltnc = "LTN_Combinator",
}

defs.names.settings = {
  window_height = mod_prefix .. "-window-height",
  debug_level = mod_prefix .. "-debug-level",
}

defs.names.tabs = {
  stations = "station_tab",
  history = "history_tab",
  alert = "alert_tab",
}

defs.names.styles = {
  shared = {
    default_button = mod_prefix .. "_default_button",
    horizontal_spacer = egm_defs.style_names.shared.horizontal_spacer,
    horizontal_container = egm_defs.style_names.shared.horizontal_container,
  },
  station_tab = {
    station_label = mod_prefix .. "_lb_station",
  },
  hist_tab = {
    label_col_1 = mod_prefix .. "_lb_hist_col1",
    label_col_2 = mod_prefix .. "_lb_hist_col2",
    label_col_3 = mod_prefix .. "_lb_hist_col3",
    label_col_4 = mod_prefix .. "_lb_hist_col4",
    label_col_4_red = mod_prefix .. "_lb_hist_col4_red",
    label_col_5 = mod_prefix .. "_lb_hist_col5",
  },
}

defs.names.actions = {
  update_tab = "update_single_tab",
  refresh_button = "refresh_button_clicked",
  filter_input = "filter_changed",
  clear_history = "clear_history_table",
  clear_alerts = "clear_alert_table",
  clear_single_alert = "clear_single_alert",
  station_name_clicked = "station_name_clicked",
  select_station_entity = "select_station",
  select_entity = "select_locomotive",
}

defs.names.functions = {
  station_row_constructor = "st_row_constructor",
  station_sort = "st_sort_function_col_",
  hist_row_constructor = "ht_row_constructor",
  hist_sort = "ht_sort_function_col_",
  alert_row_constructor = "alert_row_constructor",
  alert_sort = "at_sort_function_col_",
}

defs.names.sprites = {
  refresh = mod_prefix .. "_sprite_refresh",
}

local gui_modules = "__GUI_Modules__."
local optera_lib = "__OpteraLib__."
local LTNT = "__LTN_Tracker__."
local ui_rewrite = LTNT .. "ui_rewrite."
defs.pathes.modules = {
  constants = LTNT .. "script.constants",
  olib_logger = optera_lib .. "script.logger",
  olib_misc = optera_lib .. "script.misc",
  olib_train = optera_lib .. "script.train",
  import_egm = gui_modules .. "import",
  data_processing = LTNT .. "script.data_processing",
  gui_ctrl = LTNT .. "script.gui_ctrl",
  util = LTNT .. "script.extended_util",

  gui = ui_rewrite .. "gui",
  station_tab = ui_rewrite .. "station_tab",
  history_tab = ui_rewrite .. "history_tab",
  alert_tab = ui_rewrite .. "alert_tab",
  action_definitions = ui_rewrite .. "action_definitions",
}
return defs