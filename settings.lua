local names = require("defines").settings
data:extend({
------------------------------------------------------------------------------------
-- per-player settings
------------------------------------------------------------------------------------
	{
		name = names.window_location,
    setting_type = "runtime-per-user",
		type = "string-setting",
    default_value = "center",
    allowed_values = {"left", "center"},
    order = "a",
	},
	{
		name = names.window_height,
		setting_type = "runtime-per-user",
		type = "int-setting",
		default_value = 710,
		minimum_value = 400,
		maximum_value = 2000,
    order = "c",
	},
  {
		name = names.station_click_action,
    setting_type = "runtime-per-user",
		type = "string-setting",
    default_value = "2",
    allowed_values = {"1", "3", "2"},
    order = "e",
	},
  {
		name = names.show_alerts,
    setting_type = "runtime-per-user",
		type = "bool-setting",
    default_value = true,
    order = "f",
	},
  {
		name = names.refresh_interval,
		setting_type = "runtime-per-user",
		type = "int-setting",
		default_value = 0,
		minimum_value = 0,
		maximum_value = 30,
    order = "y",
	},
------------------------------------------------------------------------------------
-- global settings
------------------------------------------------------------------------------------
	{
		name = names.disable_underload,
    setting_type = "runtime-global",
		type = "bool-setting",
    default_value = false,
    order = "a",
	},
  {
		name = names.history_limit,
    setting_type = "runtime-global",
		type = "int-setting",
		default_value = 50,
		minimum_value = 5,
		maximum_value = 100,
    order = "c",
	},
	{
		name = names.debug_mode,
    setting_type = "runtime-global",
		type = "bool-setting",
    default_value = false,
    order = "y",
	},
})
