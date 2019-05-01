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
  hist_tab = "history_tab",
}

defs.names.styles = {
  shared = {
    default_button = mod_prefix .. "default_button",
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
  refresh_button = "refresh_button_clicked",
  clear_history = "clear_history_table",
  station_name_clicked = "station_name_clicked",
}

defs.names.functions = {
  hist_row_constructor = "ht_row_constructor",
  hist_sort = "ht_sort_function_col_",
}

defs.names.sprites = {
  refresh = mod_prefix .. "_sprite_refresh",
}

local gui_modules = "__GUI_Modules__."
local optera_lib = "__OpteraLib__."
local LTNT = "__LTN_Tracker__."
defs.pathes.modules = {
  constants = LTNT .. "script.constants",
  logger = optera_lib .. "script.logger",
  import_egm = gui_modules .. "import",
  data_processing = LTNT .. "script.data_processing",
  gui_ctrl = LTNT .. "script.gui_ctrl",
  util = LTNT .. "script.extended_util",
}
return defs