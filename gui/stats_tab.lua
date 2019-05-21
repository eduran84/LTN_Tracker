local defs = defs
local egm = egm
local C = C
local styles = defs.styles.stats_tab
local bar_graph = require(defs.pathes.modules.bar_graph)

local function build_stats_tab(window)
  local stats_tab = {}
  local tab_index = defs.tabs.statistics
  local flow = egm.tabs.add_tab(
    window.pane,
    tab_index,
    {caption = {"ltnt.tab_caption_stats"}, direction = "vertical"}
  )
  local button_flow = flow.add{type = "flow", direction = "horizontal"}
  local buttons = {
    button_flow.add{type = "button", caption = "1h", enabled = false, style = defs.styles.stats_tab.time_button},
    button_flow.add{type = "button", caption = "5h", style = defs.styles.stats_tab.time_button},
    button_flow.add{type = "button", caption = "25h", style = defs.styles.stats_tab.time_button},
  }
  egm.manager.register(buttons[1], {action = defs.actions.set_stats_time, super = stats_tab, duration  = 1})
  egm.manager.register(buttons[2], {action = defs.actions.set_stats_time, super = stats_tab, duration  = 5})
  egm.manager.register(buttons[3], {action = defs.actions.set_stats_time, super = stats_tab, duration  = 25})

  local graph_table = flow.add{type = "table", column_count = 2}

  local graph = {}
  for i = 1, 6 do
    graph[i] = bar_graph.build(graph_table, {
      height = 100,
      width = 400,
      bar_count = 40,
      show_selector = true,
      statistics = global.statistics,
      duration = 1 * 60 * 60 * 60,
    })
  end
  stats_tab.root = flow
  stats_tab.buttons = buttons
  stats_tab.graph = graph
  return stats_tab
end

local function update_stats_tab(stats_tab)
  for i = 1, 6 do
    bar_graph.update(stats_tab.graph[i])
  end
end

egm.manager.define_action(defs.actions.set_stats_time,--[[
Triggering elements:
  time buttons @ stats_tab
Event: on_gui_clicked
Data:
  super :: egm_object: The parent object of the clicked button.
]]function(event, data)
    for i, button in pairs(data.super.buttons) do
      button.enabled = true
    end
    event.element.enabled = false
    for i, graph in pairs(data.super.graph) do
      bar_graph.update(graph, nil, data.duration * 60 * 60 * 60)
    end
  end
)

return {
  build = build_stats_tab,
  update = update_stats_tab,
}