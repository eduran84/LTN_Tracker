for k, v in pairs(global.raw) do
  global.raw[k] = nil
end

global.proc = global.proc or {}
global.proc.state = "idle"
global.proc.underload_is_alert = not util.get_setting(defs.settings.disable_underload)
global.proc.state_data = {
  update_depots = {},
  update_deliveries = {},
}

global.data = global.data or {}
global.data.stops = {}
global.data.depots = {}
global.data.trains_error = {}
global.data.train_error_count = 1
global.data.provided = {}
global.data.requested = {}
global.data.in_transit = {}
global.data.deliveries = {}
global.data.delivery_hist = {}
global.data.newest_history_index = 1
global.data.name2id = {}
global.data.item2stop = {}
global.data.item2delivery = {}
global.data.history_limit = util.get_setting(defs.settings.history_limit)

global.gui_sidebar = global.gui_sidebar or {}
global.gui_sidebar.windows = {}
global.gui_sidebar.currently_opened = {}

global.temp_stats = global.temp_stats or {}
global.statistics = global.statistics or {}
global.archive = nil
