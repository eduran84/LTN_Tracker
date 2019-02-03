local util = {}

function util.select_entity(pind, entity)
	if entity and entity.valid then
		game.players[pind].opened = entity
	end
end

function util.select_train(pind, train)
  if train then
    local loco = util.get_main_loco(train)
    if loco and loco.valid then
      game.players[pind].opened = loco
    end
  end  
end

-- build string describing train composition
-- !TODO! there must be a better way to do this, currently too convoluted
function util.build_train_composition_string(train)
	local carriages = train.carriages
	local comp_string = ""
	local locos_front = train.locomotives["front_movers"]
	for _,carriage in pairs(carriages) do
		if carriage.type == "locomotive" then
			local faces_forward = false
			for _,loco in ipairs(locos_front) do
				if carriage.unit_number == loco.unit_number then
					faces_forward = true
					break
				end
			end
			if faces_forward then
				comp_string = comp_string.."<L<"
			else
				comp_string = comp_string..">L>"
			end			
		elseif carriage.type == "cargo-wagon" then
			comp_string = comp_string.."C"
		elseif carriage.type == "fluid-wagon" then
			comp_string = comp_string.."F"
		else
			comp_string = comp_string.."?"
		end
	end
	return comp_string
end

-- convert a tick value to a readable string in format "mm:ss"
local floor = math.floor
local format = string.format
local format_string = "%d:%02d"
function util.tick2timestring(tick)
	local total_seconds = tick/60
	local minutes = floor(total_seconds/60)
	local seconds = floor(total_seconds % 60)
	return format(format_string, minutes, seconds)
end

-- copy/paste from Optera's LTN
function util.get_main_loco(train)
  if train.valid and train.locomotives and (#train.locomotives.front_movers > 0 or #train.locomotives.back_movers > 0) then
    return train.locomotives.front_movers and train.locomotives.front_movers[1] or train.locomotives.back_movers[1]
  end
end
-- copy/paste from Optera's LTN-Content-Reader
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
return util