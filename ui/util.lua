local function item2sprite(item, item_type)
  if item_type then
    return item_type .. "/" .. item
  else
    return string.gsub(item, ",", "/")
  end
end
-- display a shipment of items as icons
local function build_item_table(args)
  -- !TODO go over this once more, should be as efficient as possible
  -- !TODO disable assert for release
  --required arguments: parent (without any of provided / requestd / signals an empty frame is produced)
  --optional arguments: provided, requested, signals, columns, enabled, type, no_negate, max_rows


  out.assert(args.parent, "Parent not defined.\nArgs provided:", args)
  -- parse arguments
  local columns, enabled, name
	if args.columns then
    columns = args.columns
  else
    columns = 4
  end
  local type = args.type
  local no_negate = args.no_negate

  -- outer frame
	local frame = args.parent.add{type = "frame", style = "ltnc_slot_table_frame"}
  frame.style.vertically_stretchable = false

	if args.enabled == nil then
		enabled = false
    frame.ignored_by_interaction = true
  else
    enabled = args.enabled
	end
  if args.max_rows then
    frame.style.maximal_height = args.max_rows * 38
    frame = frame.add{type = "scroll-pane", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}---and-reserve-space"}
  end
  -- table for item sprites
	local tble = frame.add{type = "table", column_count = columns, style = "slot_table"}

  local count = 0
  -- add items to table
	if args.provided then
		for item, amount in pairs(args.provided) do
			local test = tble.add{
				type = "sprite-button",
				sprite = item2sprite(item, type),
				number = amount,
				enabled = enabled,
        style = "ltnc_provided_button",
			}
      count = count + 1
		end
	end
  if args.requested then
		for item, amount in pairs(args.requested) do
      if not no_negate then
        amount = -amount -- default to numbers for requests
      end
			tble.add{
				type = "sprite-button",
				sprite = item2sprite(item, type),
				number = amount,
				enabled = enabled,
        style = "ltnc_requested_button",
			}
      count = count + 1
		end
	end
  if args.signals then
		for name, amount in pairs(args.signals) do
			tble.add{
				type = "sprite-button",
				sprite = "virtual-signal/" .. name,
				number = amount,
				enabled = enabled,
        style = "ltnc_empty_button",
			}
      count = count + 1
		end
	end
  while count == 0 or count % columns > 0  do
    tble.add{
      type = "sprite-button",
      sprite = "",
      enabled = enabled,
      style = "ltnc_empty_button",
    }
    count = count + 1
  end
	return frame
end

return {build_item_table = build_item_table}