local function clear_station_filter()
  -- hacky way to force reset of cached filter results
  GC.stop_tab.mystorage.last_filter = {}
end

-- handler for on_new_alert custom event
local function on_new_alert(event)
  if event and event.type then
    for pind in pairs(game.players) do
      -- GC.toggle_button:set_alert(pind)
      -- GC.outer_frame:set_alert(pind)
    end
  end
end

script.on_event(custom_events.on_train_alert, ui.on_new_alert)
local handlers = {}
function handlers.on_refresh_bt_click(event, data_string)
  local pind = event.player_index
  if global.gui.last_refresh_tick[pind] + global.gui.refresh_interval[pind] < game.tick  then
    global.gui.last_refresh_tick[pind] = game.tick
    update_tab(event)
  end
end

function handlers.on_item_clicked(event, data_string)
  -- item name and amount is encoded in data_string
  GC.inv_tab:on_item_clicked(event.player_index, data_string)
end


return {
  on_new_alert = on_new_alert,
  clear_station_filter = clear_station_filter,
}