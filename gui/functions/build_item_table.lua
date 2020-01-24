-- display a shipment of items as icons
local shared_styles = defs.styles.shared
local pairs = pairs
local elements = {
  outer_frame = {type = "frame", style = shared_styles.slot_table_frame},
  outer_flow = {type = "flow", style = shared_styles.vertical_container, direction = "vertical"},
  pane = C.elements.no_frame_scroll_pane,
  table = {type = "table", column_count = 0, style = "slot_table"},
  icon = {
    type = "sprite-button",
    sprite = "",
    number = 0,
    enabled = false,
    style = shared_styles.green_button,
  },
}

return
  function(args)
  --required arguments: parent, columns (without any of provided / requested / signals an empty frame is produced)
  --optional arguments: provided, requested, signals, enabled, no_negate, max_rows

  local column_count = args.columns
  -- outer frame
  local frame = args.parent.add(elements.outer_flow)
  if args.max_rows then
    frame.style.maximal_height = args.max_rows * 36 + 18
    frame.style.width = column_count * 38 + 12
    frame = frame.add(elements.pane)
  end
  -- table for item sprites
  elements.table.column_count = column_count
	local tble = frame.add(elements.table)
  local enabled
	if args.enabled then
    enabled = args.enabled
  else
		enabled = false
    tble.ignored_by_interaction = true
	end
  local count = 0
  -- add items to table
  local get_item_sprite = util.get_item_sprite
  local tbl_add = tble.add
  local button_args = elements.icon
  button_args.enabled = enabled
	if args.provided then
    button_args.style = shared_styles.green_button
		for item, amount in pairs(args.provided) do
      button_args.sprite = get_item_sprite(item)
      button_args.number = amount
			tbl_add(button_args)
      count = count + 1
		end
	end
  if args.requested then
    button_args.style = shared_styles.red_button
		for item, amount in pairs(args.requested) do
      button_args.sprite = get_item_sprite(item)
      button_args.number = args.no_negate and amount or -amount
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