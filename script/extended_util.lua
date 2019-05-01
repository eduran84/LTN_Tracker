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
function util.build_item_table(args)
  --required arguments: parent, columns (without any of provided / requested / signals an empty frame is produced)
  --optional arguments: provided, requested, signals, enabled, type, no_negate, max_rows

  -- parse arguments
  local columns = args.columns
  local type = args.type

  -- outer frame
  local frame =  args.parent.add{type = "frame", style = "ltnt_slot_table_frame"}
  if args.max_rows then
    frame.style.maximal_height = args.max_rows * 36 + 18
    frame.style.width = columns * 38 + 18
    frame = frame.add{type = "scroll-pane", style = "ltnt_it_scroll_pane"}
  end
  -- table for item sprites
	local tble = frame.add{type = "table", column_count = columns, style = "slot_table"}
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
	if args.provided then
		for item, amount in pairs(args.provided) do
			tbl_add{
				type = "sprite-button",
				sprite = item2sprite(item, type),
				number = amount,
				enabled = enabled,
        style = "ltnt_provided_button",
			}
      count = count + 1
		end
	end
  if args.requested then
		for item, amount in pairs(args.requested) do
      if not args.no_negate then
        amount = -amount -- default to numbers for requests
      end
			tbl_add{
				type = "sprite-button",
				sprite = item2sprite(item, type),
				number = amount,
				enabled = enabled,
        style = "ltnt_requested_button",
			}
      count = count + 1
		end
	end
  if args.signals then
		for name, amount in pairs(args.signals) do
			tbl_add{
				type = "sprite-button",
				sprite = "virtual-signal/" .. name,
				number = amount,
				enabled = enabled,
        style = "ltnt_empty_button",
			}
      count = count + 1
		end
	end
  while count == 0 or count % columns > 0  do
    tbl_add{
      type = "sprite-button",
      sprite = "",
      enabled = enabled,
      style = "ltnt_empty_button",
    }
    count = count + 1
  end
	return frame
end

util.misc = require(defs.pathes.modules.olib_misc).ticks_to_timestring

return util