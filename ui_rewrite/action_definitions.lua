local defs = defs
local egm = egm

local draw_circle = rendering.draw_circle
local render_arguments = {
  color = C.ui_ctrl.marker_circle_color,
  radius = 3,
  width = 10,
  surface = "nauvis",
  filled = false,
  target = {},
  target_offset  = {-1, -1},
  time_to_live = 300,
  players = {0},
}
egm.manager.define_action(
  defs.names.actions.station_name_clicked,
  function(event, data)
    if debug_mode then log2("station_name_clicked", event, data) end

    local stop = global.data.stops[tonumber(global.data.name2id[data.name])]
    local pind = event.player_index
    local player = game.players[pind]
    if stop and stop.entity and stop.entity.valid then
      --close_gui(pind)
      local entity = stop.entity
      if global.gui.station_select_mode[pind] < 3  then
        player.opened = entity
      end
      if global.gui.station_select_mode[pind] > 1 then
        player.zoom_to_world({entity.position.x+40, entity.position.y+0}, 0.4)
        render_arguments.target = entity
        render_arguments.players = {pind}
        draw_circle(render_arguments)
      end
    end
  end
)
egm.manager.define_action(
  defs.names.actions.select_entity,
  function(event, data)
    local player = game.players[event.player_index]
    if data.entity.valid and player then
      player.opened = data.entity
    end
  end
)

egm.manager.define_action(
  defs.names.actions.clear_history,
  function(event, data)
    global.data.delivery_hist = {}
    global.data.newest_history_index = 1
    egm.table.clear(data.egm_table)
  end
)
egm.manager.define_action(
  defs.names.actions.clear_alerts,
  function(event, data)
    global.data.trains_error = {}
    global.data.train_error_count = 1
    egm.table.clear(data.egm_table)
  end
)
egm.manager.define_action(
  defs.names.actions.clear_single_alert,
  function(event, data)
    global.data.trains_error[data.row_data.error_id] = nil
    egm.table.delete_row(data.egm_table, data.row_data.row_index)
  end
)