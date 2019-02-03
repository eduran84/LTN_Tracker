-- constant definitions
local CONST = {}

CONST.global = {
  mod_name = "LTNCompanion", -- preliminary name
  mod_prefix = "ltnc",
  gui_events = {defines.events.on_gui_click, defines.events.on_gui_checked_state_changed, defines.events.on_gui_text_changed}, -- events handled by on_gui_event
  mod_name_ltn = "LogisticTrainNetwork",
  minimal_version_ltn = "01.09.02",
  current_version_ltn = "01.09.07",
}

-- ui_ctrl.lua
CONST.ui_ctrl = {
  refresh_delay = 60, -- shortest time in ticks between consecutive ui refreshes
}

-- data_processing.lua
CONST.proc = {
  history_limit = 100, -- maximum number of entries in history table
  stops_per_tick = 20,
  deliveries_per_tick = 20,
  trains_per_tick = 40,
  items_per_tick = 100
}

-- UI layout
CONST.main_frame = {
	n_tabs = 5,
  button_width = 165,
  button_sprite_bare = "ltnc_bt_sprite",
  button_sprite_alert = "ltnc_bt_alert_sprite",
  button_highlight_style = "ltnc_tab_button_highlight",
  button_default_style =  "ltnc_tab_button"
}

CONST.depot_tab = {
	tab_index = 1,
  pane_width_left = 354,
  pane_width_right = 491,
	col_width_left = {108, 30, 210},
	col_width_header_left = {110, 65, 190},
	col_width_right = {140, 160, 101},
  -- parked / error / on delivery
  color_dict = {{r=0,g=1,b=0}, {r=1,g=0,b=0}, {r=1,g=1,b=1}},
  depot_msg_dict = {[0] = "parked at depot", [2] = "returning to depot"},
  --loading / unloading / moving to pick up / moving to drop off
  delivery_msg_dict = {"Loading at:", "Unloading at:", "Fetching from:", "Delivering to:"}, 
}

CONST.station_tab = {
	tab_index = 2,
  header_col_width = {137, 48, 34*5+7, 34*5+7, 34*7+6},
  station_col_width = 150,
  item_table_col_count = {5, 5, 7},
}

CONST.inventory_tab = {
	tab_index = 3,
  details_width = 327,
  details_tb_col_width = {107, 40, 150},
}

CONST.history_tab = {
	tab_index = 4,
	header_col_width = {150, 150, 160, 80, 160},
	col_width = {150, 150, 150,  60, 150},
	n_columns = 5,
}

CONST.alert_tab = {
	tab_index = 5,
  frame_width = {375, 470},
  n_columns = {3, 4},
	col_width_l = {150, 20, 149},
	col_width_r = {110, 109, 130, 0},
}

-- misc stuff
CONST.train_state_dict = { -- dont't ask why +1 is missing...
  [defines.train_state.wait_station]    = {code = 0, msg = "parked at station"},
  [defines.train_state.on_the_path]     = {code = 2, msg = "running"},
  [defines.train_state.arrive_signal]   = {code = 2, msg = "running"},
  [defines.train_state.wait_signal]     = {code = 2, msg = "running"},
  [defines.train_state.arrive_station]  = {code = 2, msg = "running"},
  [defines.train_state.path_lost]       = {code =-1, msg = "no path"},
  [defines.train_state.no_schedule]     = {code =-1, msg = "no schedule"},
  [defines.train_state.no_path]         = {code =-1, msg = "no path"},
  [defines.train_state.manual_control_stop]={code=-1,msg = "manual control"},
  [defines.train_state.manual_control]  = {code =-1, msg = "manual control"},  
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
ltn.ctrl_signal_var_name = {
  [ltn.ISDEPOT] = "isDepot",
  [ltn.NETWORKID] = "network_id",
  [ltn.MINTRAINLENGTH] = "minTraincars",
  [ltn.MAXTRAINLENGTH] = "maxTraincars",
  [ltn.MAXTRAINS] = "trainLimit",
  [ltn.MINREQUESTED] = "minRequested",
  [ltn.REQPRIORITY] = "reqestPriority",
  [ltn.NOWARN] = "noWarnings",
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
  [-1] = {"ltnc.error-no-init"},
  [0] = {"ltnc.error-invalid"},
  [1] = {"ltnc.error-disabled"},
  [2] = {"ltnc.error-duplicate"},
}
CONST.ltn = ltn
return CONST