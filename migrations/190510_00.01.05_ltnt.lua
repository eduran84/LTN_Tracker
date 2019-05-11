global.raw = {}
global.proc = {
  state = "idle",
  underload_is_alert = util.get_setting(defs.settings.disable_underload),
  state_data = {
    update_depots = {},
    update_deliveries = {},
  }
}
global.data = {
  stops = {},
  depots = {},
  trains_error = {},
  train_error_count = 1,
  provided = {},
  requested = {},
  in_transit = {},
  deliveries = {},
  delivery_hist ={},
  newest_history_index = 1,
  name2id = {},
  item2stop = {},
  item2delivery = {},
  history_limit = util.get_setting(defs.settings.history_limit),
}

global.gui_sidebar = {
  windows = {},
}