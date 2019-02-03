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
  --optional arguments: provided, requested, signals, columns, enabled, name, type, no_negate
  
  out.assert(args.parent, "Parent not defined.\nArgs provided:", args) 
  -- parse arguments
  local columns, enabled, name
	if args.columns then
    columns = args.columns
  else
    columns = 4
  end
	if args.enabled == nil then
		enabled = false
  else
    enabled = args.enabled
	end
  local params = {}
  if args.name and type(args.name) == "string" then
    params.name = args.name
    out.error("Stop using this shit.") -- !DEBUG
  end
  local type = args.type
  local no_negate = args.no_negate
  -- outer frame
	params.type = "frame"
  params.style = "ltnc_slot_table_frame"
	local frame = args.parent.add(params)
	frame.style.vertically_stretchable = false
	frame.style.horizontally_stretchable = false
	frame.style.minimal_height = 36
  
  -- table for item sprites
	params.type = "table"
  params.column_count = columns
  params.style = "slot_table"
	local tble = frame.add(params)
	tble.style.width = 34*columns
	tble.style.vertically_stretchable = false
  
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
      test.style.vertically_stretchable = false
      count = count + 1
		end
	end
  if args.requested then
		for item, amount in pairs(args.requested) do
      if not no_negate then
        amount = -amount -- default to numbers for requests
      end      
			local test = tble.add{
				type = "sprite-button",
				sprite = item2sprite(item, type),
				number = amount, 
				enabled = enabled,
        style = "ltnc_requested_button",
			}
      test.style.vertically_stretchable = false
      count = count + 1
		end
	end
  if args.signals then
		for _,v in pairs(args.signals) do
			tble.add{
				type = "sprite-button",
				sprite = "virtual-signal/" .. v.name,
				number = v.count,
				enabled = enabled,
        style = "ltnc_empty_button",
			}
      count = count + 1
		end
	end
  
  while count == 0 or count % columns > 0  do
    local test = tble.add{
      type = "sprite-button",
      sprite = "",
      enabled = enabled,
      style = "ltnc_empty_button",
    }
      test.style.vertically_stretchable = false
    count = count + 1
  end
	return frame
end

return {build_item_table = build_item_table}