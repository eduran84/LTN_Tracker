local util = require("util")

local btest = bit32.btest
function util.get_items_in_network(ltn_item_list, selected_networkID)
	local items = {}
	for networkID, item_data in pairs(ltn_item_list) do
		if btest(selected_networkID, networkID) then
			for item, count in pairs(item_data) do
				items[item] = (items[item] or 0) + count
			end
		end
  end
	return items
end

local match = string.match
local function item2sprite(iname, itype)
  if not itype then
    itype, iname= match(iname, "(.+),(.+)")
  end
  if iname and (game.item_prototypes[iname] or game.fluid_prototypes[iname]) then
    return itype .. "/" .. iname
  else
    return nil
  end
end
util.item2sprite = item2sprite

-- display a shipment of items as icons
local shared_styles = defs.styles.shared
function util.build_item_table(args)
  --required arguments: parent, columns (without any of provided / requested / signals an empty frame is produced)
  --optional arguments: provided, requested, signals, enabled, type, no_negate, max_rows

  -- parse arguments
  local column_count = args.columns
  local type = args.type

  -- outer frame
  local frame =  args.parent.add{type = "frame", style = "ltnt_slot_table_frame"}
  if args.max_rows then
    frame.style.maximal_height = args.max_rows * 36 + 18
    frame.style.width = column_count * 38 + 18
    frame = frame.add{type = "scroll-pane", style = "ltnt_it_scroll_pane"}
  end
  -- table for item sprites
	local tble = frame.add{type = "table", column_count = column_count, style = "slot_table"}
  local enabled
	if args.enabled then
    enabled = args.enabled
  else
		enabled = false
    tble.ignored_by_interaction = true
	end
  local count = 0
  -- add items to table
  local tbl_add = tble.add
  local button_args = {
    type = "sprite-button",
    sprite = "",
    number = 0,
    enabled = enabled,
    style = shared_styles.green_button,
  }
	if args.provided then
		for item, amount in pairs(args.provided) do
      button_args.sprite = item2sprite(item, type)
      button_args.number = amount
			tbl_add(button_args)
      count = count + 1
		end
	end
  if args.requested then
    button_args.style = shared_styles.red_button
		for item, amount in pairs(args.requested) do
      button_args.sprite = item2sprite(item, type)
      button_args.number = args.no_negate and -amount or amount
			tbl_add(button_args)
      count = count + 1
		end
	end
  button_args.style = shared_styles.gray_button
  if args.signals then
		for name, amount in pairs(args.signals) do
      button_args.sprite = "virtual-signal/" .. name
      button_args.number = amount
			tbl_add(button_args)
      count = count + 1
		end
	end
  button_args.sprite = ""
  button_args.number = nil
  button_args.enabled = false
  while count % column_count > 0 or count == 0 do
    tbl_add(button_args)
    count = count + 1
  end
	return frame
end

util.ticks_to_timestring = require(defs.pathes.modules.olib_misc).ticks_to_timestring
util.train = require(defs.pathes.modules.olib_train)

return util