data:extend({
	{
		name = "ltnt-show-button",
		setting_type = "runtime-per-user",
		type = "bool-setting",
		default_value = true,
	},
	{
		name = "ltnt-window-height",
		setting_type = "runtime-per-user",
		type = "int-setting",
		default_value = 750,
		minimum_value = 500,
		maximum_value = 2000,
	},
  {
		name = "ltnt-history-limit",
    setting_type = "runtime-global",
		type = "int-setting",
		default_value = 50,
		minimum_value = 5,
		maximum_value = 100,
	},
	{
		name = "ltnt-debug-level",
    setting_type = "runtime-global",
		type = "string-setting",
    default_value = "1",
    allowed_values = {"0", "1", "2"},
	},
	{
		name = "ltnt-debug-print",
    setting_type = "runtime-global",
		type = "bool-setting",
		default_value = false,
	},
})
