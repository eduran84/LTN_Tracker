local defs = defs
local egm = egm
local C = C
local styles = defs.styles.stats_tab
local bar_graph = require(defs.pathes.modules.bar_graph)

local function build_stats_tab(window)
  local tab_index = defs.tabs.statistics
  local flow = egm.tabs.add_tab(
    window.pane,
    tab_index,
    {caption = {"ltnt.tab_caption_stats"}, direction = "vertical"}
  )
  local button_flow = flow.add{type = "flow", direction = "horizontal"}
  local graph_table = flow.add{type = "table", column_count = 2}

  local graph = {}
  for i = 1, 6 do
    graph[i] = bar_graph.build(graph_table, {
      height = 100,
      width = 400,
      show_selector = true,
      statistics = global.statistics,
    })
  end
  return {
    root = flow,
    graph = graph,
  }
end

local function update_stats_tab(stats_tab)
  for i = 1, 6 do
    bar_graph.update(stats_tab.graph[i])
  end
end

return {
  build = build_stats_tab,
  update = update_stats_tab,
}