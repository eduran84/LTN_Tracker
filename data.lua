require("prototypes.sprites")
require("prototypes.fonts")
require("prototypes.styles")

data:extend({{
	type = "custom-input",
	name = "ltnt-toggle-hotkey",
	key_sequence = "CONTROL + SHIFT + E",
	consuming = "none",
}})

logger.log(data.raw.shortcut["toggle-personal-roboport"])
data:extend({{
  type = "shortcut",
  name = "ltnt-toggle-shortcut",
  --order = "b[blueprints]-g[deconstruction-planner]",
  action = "lua",
  localised_name = {"shortcut.ltnt-toggle"},
  style = "default",
  toggleable = true,
  associated_control_input = "ltnt-toggle-hotkey",
  icon =
  {
    filename = "__LTN_Tracker__/graphics/shortcut_icon_32.png",
    priority = "extra-high-no-scale",
    size = 32,
    scale = 1,
    flags = {"icon"}
  },
  disabled_icon =
  {
    filename = "__LTN_Tracker__/graphics/shortcut_icon_32_white.png",
    priority = "extra-high-no-scale",
    size = 32,
    scale = 1,
    flags = {"icon"}
  },
  small_icon =
  {
    filename = "__LTN_Tracker__/graphics/shortcut_icon_24.png",
    size = 24,
    scale = 1,
    flags = {"icon"}
  },
  disabled_small_icon =
  {
    filename = "__LTN_Tracker__/graphics/shortcut_icon_24_white.png",
    priority = "extra-high-no-scale",
    size = 24,
    scale = 1,
    flags = {"icon"}
  },
}})
