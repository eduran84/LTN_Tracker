local defs = defs
local egm = egm
local C = C

local tonumber = tonumber

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
    if debug_log then log2("station_name_clicked", event, data) end

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
  defs.names.actions.clear_history,
  function(event, data)
    global.data.delivery_hist = {}
    global.data.newest_history_index = 1
    egm.table.clear(data.egm_table)
  end
)

local n_cols_shipment = C.history_tab.n_cols_shipment
local build_item_table = util.build_item_table
local styles = defs.names.styles.hist_tab
egm.stored_functions[defs.names.functions.hist_row_constructor] = function(parent, data)
  local delivery = data.delivery
  parent.add{
    type = "label",
    caption = delivery.depot,
    style = styles.label_col_1
  }
  local flow = parent.add{type = "flow", direction = "vertical"}
  local label_from = flow.add{
    type = "label",
    caption = delivery.from,
    style = styles.label_col_2
  }
  egm.manager.register(label_from, {action = defs.names.actions.station_name_clicked, name = delivery.from})
  local label_to = flow.add{
    type = "label",
    caption = delivery.to,
    style = styles.label_col_2
  }
  egm.manager.register(label_to, {action = defs.names.actions.station_name_clicked, name = delivery.to})
  -- network id
  parent.add{
    type = "label",
    caption = delivery.networkID,
    style = styles.label_col_3
  }
  -- runtime, possibly with time-out warning
  if delivery.timed_out then
    parent.add{
      type = "label",
      caption = data.time[1],
      tooltip = {"error.train-timeout"},
    style = styles.label_col_4_red
    }
  else
    parent.add{
      type = "label",
      caption = data.time[1],
    style = styles.label_col_4
    }
  end
  -- time this delivery finished at
  parent.add{
    type = "label",
    caption = data.time[2],
    style = styles.label_col_5
  }
  -- shipement and residual items, if any
  if delivery.residuals then
    local tb = parent.add{type = "table", column_count = 1, style = "slot_table"}
    build_item_table{
      parent = tb,
      provided = delivery.shipment,
      columns = n_cols_shipment
    }
    build_item_table{
      parent = tb,
      requested = delivery.residuals[2],
      columns = n_cols_shipment,
      type = delivery.residuals[1],
      no_negate = true,
    }
  else
    build_item_table{
      parent = parent,
      provided = delivery.shipment,
      columns = n_cols_shipment
    }
  end -- if delivery.residuals then
end

egm.stored_functions[defs.names.functions.hist_sort .. 1] = function(a, b) return a.delivery.depot < b.delivery.depot end
egm.stored_functions[defs.names.functions.hist_sort .. 2] = function(a, b) return a.delivery.from < b.delivery.from end
egm.stored_functions[defs.names.functions.hist_sort .. 3] = function(a, b) return a.delivery.networkID < b.delivery.networkID end
egm.stored_functions[defs.names.functions.hist_sort .. 4] = function(a, b) return a.delivery.finished < b.delivery.finished end
egm.stored_functions[defs.names.functions.hist_sort .. 5] = function(a, b) return a.delivery.finished < b.delivery.finished end

local function build_history_tab(window, tab_index)
  local flow = egm.tabs.add_tab(window.pane, tab_index, {caption = {"ltnt.tab4-caption"}})
  local table = egm.table.build(
    flow,
    {column_count = C.history_tab.n_columns},
    defs.names.functions.hist_row_constructor
  )
  for i = 1, C.history_tab.n_columns - 1 do
    egm.table.add_column_header(table, {
        sortable = true,
        width = C.history_tab.column_width[i],
        caption = {"history.header-col-"..i},
        tooltip = {"history.header-col-"..i.."-tt"},
      },
      defs.names.functions.hist_sort .. i
    )
  end
  egm.table.add_column_header(table, {
    width = C.history_tab.column_width[C.history_tab.n_columns],
    caption = {"history.header-col-"..C.history_tab.n_columns},
    tooltip = {"history.header-col-"..C.history_tab.n_columns.."-tt"},
  })
  local button = table.root.children[1].add{
    type = "sprite-button",
    style = defs.names.styles.shared.default_button,
    sprite = "utility/remove",
    tooltip = {"history.delete-tt"},
  }
  egm.manager.register(button, {action = defs.names.actions.clear_history, egm_table = table})
  window.tabs = {[tab_index] = table}
end

local w = {}
function w.build(parent)
  local pind = parent.player_index
  local window_height = settings.get_player_settings(game.players[pind])[defs.names.settings.window_height].value
  local window = egm.window.build(parent, {
    caption = {"ltnt.mod-name"},
    height = window_height,
    width = C.window.width,
    direction = "vertical",
  })
  window.root.visible = false
  egm.window.add_button(window, {
    type = "sprite-button",
    sprite = defs.names.sprites.refresh,
    tooltip = {"ltnt.refresh-bt"},
  },
  {action = defs.names.actions.refresh_button})

  local pane = egm.tabs.build(window.content, {direction = "vertical"})
  window.pane = pane
  egm.tabs.add_tab(pane, 1, {caption = {"ltnt.tab1-caption"}})
  egm.tabs.add_tab(pane, 2, {caption = {"ltnt.tab2-caption"}})
  egm.tabs.add_tab(pane, 3, {caption = {"ltnt.tab3-caption"}})

  local history_table = build_history_tab(window, defs.names.tabs.hist_tab)
  egm.tabs.add_tab(pane, 5, {caption = {"ltnt.tab5-caption"}})
  return window, pane
end

return w