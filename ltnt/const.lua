-- constant definitions
local CONST = {}

CONST.settings = {
  ui = {
    ["ltnt-show-button"] = true,
    ["ltnt-window-height"] = true,
    ["ltnt-refresh-interval"] = true,
  },
  proc = {["ltnt-history-limit"] = true},
  debug = {
    ["ltnt-debug-print"] = true,
    ["ltnt-debug-level"] = true,
  },
}

CONST.global = {
  mod_name = "LTN_Tracker", -- preliminary name
  mod_prefix = "ltnt",
  gui_events = {defines.events.on_gui_click, defines.events.on_gui_checked_state_changed, defines.events.on_gui_text_changed}, -- events handled by on_gui_event
  mod_name_ltn = "LogisticTrainNetwork",
  minimal_version_ltn = "01.10.0",
  current_version_ltn = "01.10.0",
}

-- ui_ctrl.lua
CONST.ui_ctrl = {
  refresh_delay = 60, -- shortest time in ticks between consecutive ui refreshes
}

-- data_processing.lua
CONST.proc = {
  stops_per_tick = 20,
  deliveries_per_tick = 20,
  trains_per_tick = 30,
  items_per_tick = 50,
}

-- UI layout
CONST.main_frame = {
	n_tabs = 5,
  button_width = 185,
  button_sprite_bare = "ltnt_bt_sprite",
  button_sprite_alert = "ltnt_bt_alert_sprite",
  button_highlight_style = "ltnt_tab_button_highlight",
  button_default_style =  "ltnt_tab_button"
}

CONST.depot_tab = {
	tab_index = 1,
  pane_width_left = 355,
	col_width_left = {325, 50, 50, 53, 170},

  pane_width_right = 580,
	col_width_right = {160, 190, 101},
  -- parked / error / on delivery
  color_dict = {{r=0,g=1,b=0}, {r=1,g=0,b=0}, {r=1,g=1,b=1}},
}

CONST.station_tab = {
	tab_index = 2,
  header_col_width = {207, 29, 40*5+27, 40*4+21, 40*6},
  station_col_width = 195,
  item_table_col_count = {5, 4, 7},
  item_table_max_rows = {4, 4, 1},
}

CONST.inventory_tab = {
	tab_index = 3,
  item_table_column_count = 14,
  details_item_tb_col_count = 9,
  details_width = 380,
  details_tb_col_width_stations = {290, 45},
  details_tb_col_width_deliveries = {150, 25, 150}
}

CONST.history_tab = {
	tab_index = 4,
	header_col_width = {180, 180, 180, 35, 50, 140},
	col_width = {180, 180, 180, 40, 40, 150},
	n_columns = 6,
  n_cols_shipment = 5,
}

CONST.alert_tab = {
	tab_index = 5,
  frame_width = {385, 500},
  n_columns = {3, 4},
	col_width_l = {150, 20, 149},
	col_width_r = {120, 119, 140, 0},
}

-- misc stuff

CONST.train_error_state_dict = {
  ["residuals"] = {"error.train-residual-cargo"},
  ["timeout"] = {"error.train-timeout"},
}

-- LTN definitions, copied from LTN's control.lua
local ltn = {
  ISDEPOT = "ltn-depot",
  NETWORKID = "ltn-network-id",
  MINTRAINLENGTH = "ltn-min-train-length",
  MAXTRAINLENGTH = "ltn-max-train-length",
  MAXTRAINS = "ltn-max-trains",
  MINREQUESTED = "ltn-requester-threshold",
  REQPRIORITY = "ltn-requester-priority",
  NOWARN = "ltn-disable-warnings",
  MINPROVIDED = "ltn-provider-threshold",
  PROVPRIORITY = "ltn-provider-priority",
  LOCKEDSLOTS = "ltn-locked-slots",
}
ltn.is_control_signal = {
  [ltn.ISDEPOT] = true,
  [ltn.NETWORKID] = true,
  [ltn.MINTRAINLENGTH] = true,
  [ltn.MAXTRAINLENGTH] = true,
  [ltn.MAXTRAINS] = true,
  [ltn.MINREQUESTED] = true,
  [ltn.REQPRIORITY] = true,
  [ltn.NOWARN] = true,
  [ltn.MINPROVIDED] = true,
  [ltn.PROVPRIORITY] = true,
  [ltn.LOCKEDSLOTS] = true,
}
ltn.ctrl_signal_var_name_bool = {
  [ltn.ISDEPOT] = "isDepot",
  [ltn.NOWARN] = "noWarnings",
}
ltn.ctrl_signal_var_name_num = {
  [ltn.NETWORKID] = "network_id",
  [ltn.MINTRAINLENGTH] = "minTraincars",
  [ltn.MAXTRAINLENGTH] = "maxTraincars",
  [ltn.MAXTRAINS] = "trainLimit",
  [ltn.MINREQUESTED] = "minRequested",
  [ltn.REQPRIORITY] = "requestPriority",
  [ltn.MINPROVIDED] = "minProvided",
  [ltn.PROVPRIORITY] = "providePriority",
  [ltn.LOCKEDSLOTS] = "lockedSlots",
}
ltn.error_color_lookup = {
  [-1]= "signal-white",
  [0] = "signal-white", -- this is a modification, used when entity became invalid
  [1] = "signal-red",
  [2] = "signal-pink",
}
ltn.error_string_lookup = {
  [-1] = {"error.stop-no-init"},
  [0] = {"error.stop-invalid"},
  [1] = {"error.stop-disabled"},
  [2] = {"error.stop-duplicate"},
}
CONST.ltn = ltn
return CONST