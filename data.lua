defs = require("defines")
egm_defs = require("__GUI_Modules__.defines")
C = require(defs.pathes.modules.constants)
log2 = require(defs.pathes.modules.olib_logger).log

require("prototypes.sprites")
require("prototypes.fonts")
require("prototypes.styles")

data:extend({
  {
    type = "custom-input",
    name = defs.controls.toggle_hotkey,
    key_sequence = "CONTROL + SHIFT + E",
    consuming = "none",
  },
  {
    type = "shortcut",
    name = defs.controls.shortcut,
    order = "a[ltnt-toggle-shortcut]",
    action = "lua",
    localised_name = {"shortcut.ltnt_toggle"},
    style = "default",
    technology_to_unlock = "logistic-train-network",
    toggleable = true,
    associated_control_input = defs.controls.toggle_hotkey,
    icon =
    {
      filename = defs.pathes.sprites.shortcut_icon_32,
      priority = "extra-high-no-scale",
      size = 32,
      scale = 1,
      flags = {"icon"}
    },
    disabled_icon =
    {
      filename = defs.pathes.sprites.shortcut_icon_32_white,
      priority = "extra-high-no-scale",
      size = 32,
      scale = 1,
      flags = {"icon"}
    },
    small_icon =
    {
      filename = defs.pathes.sprites.shortcut_icon_24,
      size = 24,
      scale = 1,
      flags = {"icon"}
    },
    disabled_small_icon =
    {
      filename = defs.pathes.sprites.shortcut_icon_24_white,
      priority = "extra-high-no-scale",
      size = 24,
      scale = 1,
      flags = {"icon"}
    },
  }
})
