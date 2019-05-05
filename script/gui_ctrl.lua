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

script.on_event(defines.events.on_train_alert, ui.on_new_alert)

return {
  on_new_alert = on_new_alert,
  clear_station_filter = clear_station_filter,
}