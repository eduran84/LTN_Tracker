



script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.players[event.player_index]
    if
      event.gui_type == defines.gui_type.entity
      and event.entity.type == "inserter"
      and not global.bobmods.inserters.blacklist[event.entity.name]
    then
      global.bobmods.inserters[event.player_index].position = "left"
      bobmods.inserters.open_gui(event.entity, player)
    else
      bobmods.inserters.delete_gui(event.player_index)
    end
end)


script.on_event(defines.events.on_gui_closed, function(event)
  if global.bobmods.inserters[event.player_index].position == "left" then
    bobmods.inserters.delete_gui(event.player_index)
  end
end)