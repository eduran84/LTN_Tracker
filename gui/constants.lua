-- gui constant definitions
local C = {}

C.elements = {
  flow_vertical_container = {
    type = "flow",
    style = defs.styles.vertical_container,
    direction = "vertical"
  },
  flow_horizontal_container = {
    type = "flow",
    style = defs.styles.horizontal_container,
    direction = "horizontal"
  },
  no_frame_scroll_pane = {
    type = "scroll-pane",
    style = defs.styles.shared.no_frame_scroll_pane,
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space",
  },
}

C.colors = {
  heading_default = {r = 1, g = 0.902, b = 0.752},
  red = {r = 1, g = 0, b = 0},
}

-- data_processing.lua
C.proc = {
  stops_per_tick = 20,
  deliveries_per_tick = 20,
  trains_per_tick = 30,
  items_per_tick = 50,
}

-- UI layout
C.window = {
  width = 930,
  marker_circle_color = {r = 1, g = 0, b = 0, a = 0.5},
}

C.sidebar = {
  width = 281,
  label_width = 120,
  mini_width = 25,
}

C.depot_tab = {
  pane_width_left = 355,
	col_width_left = {325, 55, 50, 52, 180},

  --pane_width_right = 580,
	col_width_right = {170, 200, 101},
  -- parked / error / on delivery
  color_dict = {{r=0,g=1,b=0}, {r=1,g=0,b=0}, {r=1,g=1,b=1}},
}

C.station_tab = {
  n_columns = 7,
  col_width = {190, 37, 50, 37*5+23, 37*4+23, 37*5+23, 1},
  item_table_col_count = {5, 4, 4},
  item_table_max_rows = {4, 4, 2},
}

C.inventory_tab = {
  item_table_column_count = 13,
  item_table_width = 504,
  details_item_tb_col_count = 9,
  details_width = 390,
  summary_number_width = 90,
  details_tb_col_width_stations = {300, 45},
  details_tb_col_width_deliveries = {160, 25, 160}
}

C.history_tab = {
  column_width = {200, 200, 50, 80, 90, 210},
	n_columns = 6,
  n_cols_shipment = 6,
}

C.alert_tab = {
  n_columns = 6,
	col_width = {160, 165, 75, 160, 245},
}

-- LTN definitions, copied from LTN's control.lua
local ltn = {
  ISDEPOT = "ltn-depot",
  NETWORKID = "ltn-network-id",
  MINTRAINLENGTH = "ltn-min-train-length",
  MAXTRAINLENGTH = "ltn-max-train-length",
  MAXTRAINS = "ltn-max-trains",
  REQUESTED_THRESHOLD = "ltn-requester-threshold",
  REQUESTED_STACK_THRESHOLD = "ltn-requester-stack-threshold",
  REQUESTED_PRIORITY = "ltn-requester-priority",
  NOWARN = "ltn-disable-warnings",
  PROVIDED_THRESHOLD = "ltn-provider-threshold",
  PROVIDED_STACK_THRESHOLD = "ltn-provider-stack-threshold",
  PROVIDED_PRIORITY = "ltn-provider-priority",
  LOCKEDSLOTS = "ltn-locked-slots",
}
ltn.ctrl_signal_var_name_bool = {
  [ltn.ISDEPOT] = "isDepot",
  [ltn.NOWARN] = "noWarnings",
}
ltn.ctrl_signal_var_name_num = {
  --[ltn.NETWORKID] = "network_id",
  [ltn.MINTRAINLENGTH] = "minTraincars",
  [ltn.MAXTRAINLENGTH] = "maxTraincars",
  [ltn.MAXTRAINS] = "trainLimit",
  [ltn.REQUESTED_THRESHOLD] = "requestThreshold",
  [ltn.REQUESTED_STACK_THRESHOLD] = "requestStackThreshold",
  [ltn.REQUESTED_PRIORITY] = "requestPriority",
  [ltn.PROVIDED_THRESHOLD] = "provideThreshold",
  [ltn.PROVIDED_STACK_THRESHOLD] = "provideStackThreshold",
  [ltn.PROVIDED_PRIORITY] = "providePriority",
  [ltn.LOCKEDSLOTS] = "lockedSlots",
}
ltn.error_color_lookup = {
  [-1]= "signal-white",
  [0] = "signal-white", -- this is a modification, used when entity becomes invalid
  [1] = "signal-red",
  [2] = "signal-pink",
}
ltn.error_string_lookup = {
  [-1] = {"error.stop-no-init"},
  [0] = {"error.stop-invalid"},
  [1] = {"error.stop-disabled"},
  [2] = {"error.stop-duplicate"},
}
C.ltn = ltn
return C