local defs = defs
local egm = egm
local gui = gui

egm.manager.define_action(
  defs.actions.update_tab,
  function(event, data)
    gui.update_tab(event)
  end
)

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
  defs.actions.station_name_clicked,
  function(event, data)
    if debug_mode then log2("station_name_clicked", event, data) end

    local stop = global.data.stops[tonumber(global.data.name2id[data.name])]
    if stop and stop.entity and stop.entity.valid then
      local pind = event.player_index
      local player = game.players[pind]
      local entity = stop.entity
      if global.gui_data.station_select_mode[pind] < 3  then
        player.opened = entity
      end
      if global.gui_data.station_select_mode[pind] > 1 then
        player.zoom_to_world({entity.position.x+40, entity.position.y+0}, 0.4)
        render_arguments.target = entity
        render_arguments.players = {pind}
        draw_circle(render_arguments)
      end
    end
  end
)
egm.manager.define_action(
  defs.actions.select_station_entity,
  function(event, data)
    if debug_mode then log2("select_station_entity", event, data) end
    local stop_entity = data.stop_entity
    if stop_entity and stop_entity.valid then
      local pind = event.player_index
      if global.gui_data.station_select_mode[pind] < 3  then
        game.players[pind].opened = stop_entity
      end
      if global.gui_data.station_select_mode[pind] > 1 then
        game.players[pind].zoom_to_world({stop_entity.position.x+40, stop_entity.position.y+0}, 0.4)
        render_arguments.target = stop_entity
        render_arguments.players = {pind}
        draw_circle(render_arguments)
      end
    end
  end
)
egm.manager.define_action(
  defs.actions.select_ltnc,
  function(event, data)
    local pind = event.player_index
    local lamp_entity = data.lamp_entity
    if lamp_entity.valid then
      if remote.call("ltn-combinator", "open_ltn_combinator", pind, lamp_entity, false) then
        global.gui_data.is_ltnc_open = {[pind] = true}
      else
        local player = game.players[pind]
        player.surface.create_entity{
          name = "flying-text",
          position = player.position,
          text = {"ltnt.no-ltnc-found-msg"},
          color = {r=1,g=0,b=0}
        }
      end
    end
  end
)
egm.manager.define_action(
  defs.actions.select_entity,
  function(event, data)
    local player = game.players[event.player_index]
    if data.entity.valid and player then
      player.opened = data.entity
    end
  end
)

local function trim(s)
  local from = s:match("^%s*()")
  return from > #s and "" or s:match(".*%S", from)
end
egm.manager.define_action(
  defs.actions.update_filter,
  function(event, data)
    if event.name ~= defines.events.on_gui_text_changed then return end
    local elem = event.element
    if elem.text then
      local input = trim(elem.text)
      if input:len() == 0 then
        data.filter.current = nil
      else
        data.filter.current = input
      end
    end
    gui.update_tab(event)
  end
)

egm.manager.define_action(
  defs.actions.clear_history,
  function(event, data)
    global.data.delivery_hist = {}
    global.data.newest_history_index = 1
    egm.table.clear(data.egm_table)
  end
)
egm.manager.define_action(
  defs.actions.clear_alerts,
  function(event, data)
    global.data.trains_error = {}
    global.data.train_error_count = 1
    egm.table.clear(data.egm_table)
  end
)
egm.manager.define_action(
  defs.actions.clear_single_alert,
  function(event, data)
    global.data.trains_error[data.row_data.error_id] = nil
    egm.table.delete_row(data.egm_table, data.row_data.row_index)
  end
)