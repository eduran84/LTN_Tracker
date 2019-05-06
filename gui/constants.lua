-- constant definitions
local CONST = {}

-- data_processing.lua
CONST.proc = {
  fluid_tolerance = 0.1,
  stops_per_tick = 20,
  deliveries_per_tick = 20,
  trains_per_tick = 30,
  items_per_tick = 50,
}

-- UI layout
CONST.window = {
  width = 930,
  marker_circle_color = {r = 1, g = 0, b = 0, a = 0.5}
}

CONST.depot_tab = {
  pane_width_left = 355,
	col_width_left = {325, 55, 50, 52, 180},

  --pane_width_right = 580,
	col_width_right = {170, 200, 101},
  -- parked / error / on delivery
  color_dict = {{r=0,g=1,b=0}, {r=1,g=0,b=0}, {r=1,g=1,b=1}},
}

CONST.station_tab = {
  n_columns = 6,
  col_width = {190, 50, 37*5+23, 37*4+23, 37*6+23, 1},
  item_table_col_count = {5, 4, 5},
  item_table_max_rows = {4, 4, 2},
}

CONST.inventory_tab = {
  item_table_column_count = 13,
  item_table_width = 504,
  details_item_tb_col_count = 9,
  details_width = 390,
  summary_number_width = 90,
  details_tb_col_width_stations = {300, 45},
  details_tb_col_width_deliveries = {160, 25, 160}
}

CONST.history_tab = {
  column_width = {200, 200, 50, 80, 90, 210},
	n_columns = 6,
  n_cols_shipment = 6,
}

CONST.alert_tab = {
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
  [ltn.NETWORKID] = "network_id",
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
CONST.ltn = ltn
return CONST