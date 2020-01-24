local defs = defs
local styles = defs.styles
local egm = egm

local bar_graph = {}

local function signal_to_item(signal_id)
  if signal_id then
    if signal_id.type == "virtual" then return "" end
    return signal_id.type .. "," .. signal_id.name
  else
    return ""
  end
end

local function calculate_bar_heights(bar_graph_obj, item, T0)
  -- statistics :: table: [tick::int] -> [item::string] -> count::int
  T0 = T0 or 60*60*60  -- 1 hour
  local T = T0 / bar_graph_obj.bar_count
  local counts_per_time, N, avg_counts = {}, {}, {}, {}
  local current_tick = game.tick
  local floor = math.floor

  for tick, item_list in pairs(bar_graph_obj.statistics) do
    local index = floor(tick/T)
    N[index] = (N[index] or 0) + 1
    counts_per_time[index] = (counts_per_time[index] or 0) + (item_list[item] or 0)
  end
  local max, min = 0, 0
  local offset = floor((current_tick/T0 -1 )* bar_graph_obj.bar_count) - 1
  for i = 1, bar_graph_obj.bar_count do
    if counts_per_time[i+offset] then
      avg_counts[i] = counts_per_time[i + offset] / N[i + offset]
      max = avg_counts[i] > max and avg_counts[i] or max
      min = avg_counts[i] < min and avg_counts[i] or min
    end
  end
  return avg_counts, max, min
end

function bar_graph.update(bar_graph_obj, item, duration)
  item = item or signal_to_item(bar_graph_obj.selector.elem_value)
  if duration then
    bar_graph_obj.duration = duration
    local min_h = -math.floor(duration / 60 / 60 / 60 * 10) / 10
    bar_graph_obj.x_labels.left.caption = min_h .. " hours"
    min_h = -math.floor(duration / 60 / 60 / 60 / 2 * 10) / 10
    bar_graph_obj.x_labels.center.caption = min_h .. " hours"
  else
    duration = bar_graph_obj.duration
  end
  local counts_over_time, max, min = calculate_bar_heights(bar_graph_obj, item, duration)
  bar_graph_obj.y_labels.top.caption = util.format_number(max)
  bar_graph_obj.y_labels.bottom.caption = util.format_number(min)

  local height_scale = (max - min) / bar_graph_obj.height
  if height_scale > 0 then
    for i = 1, bar_graph_obj.bar_count do
      local y = (counts_over_time[i] or 0) / height_scale
      bar_graph_obj.bars_top[i].style.height = y
      bar_graph_obj.bars_bottom[i].style.height = -y
    end
  else
    for i = 1, bar_graph_obj.bar_count do
      bar_graph_obj.bars_top[i].style.height = 0
      bar_graph_obj.bars_bottom[i].style.height = 0
    end
  end
end

function bar_graph.build(parent, args)
  local bar_graph_obj = {}

  args = args or {}
  local width = args.width or 330
  local height = args.height or 70
  local bar_count = args.bar_count or 30
  local bar_width = math.floor(width / bar_count)
  local duration = args.duration or 60 * 60 * 60

  local outer_frame = parent.add{
    type = "frame",
    direction = "vertical",
    style = args.frame_style or styles.shared.no_padding_frame
  }
  local title_flow = outer_frame.add{
    type = "flow",
    direction = "horizontal",
    style = styles.shared.horizontal_container
  }
  local selector, title_label
  if args.show_selector then
    selector = title_flow.add{type = "choose-elem-button", elem_type = "signal"}
    egm.manager.register(selector, {action = "set_stats_item", graph = bar_graph_obj})
    title_label = title_flow.add{type = "label", style = "heading_2_label"}
    title_label.style.left_padding = 10
  end
  local content = outer_frame.add{
    type = "flow",
    direction = "horizontal",
    style = styles.shared.horizontal_container
  }
  local graph_flow = content.add{
    type = "flow",
    direction = "vertical",
    style = styles.shared.vertical_container
  }
  graph_flow.style.height = height + 20
  graph_flow.style.vertical_align = "bottom"
  local graph_area = graph_flow.add{
    type = "frame",
    direction = "vertical",
    style = styles.stats_tab.graph_area
  }
  graph_area.style.height = height
  local flow_top = graph_area.add{
    type = "flow",
    direction = "horizontal",
    style = styles.shared.horizontal_container
  }
  flow_top.style.vertical_align = "bottom"
  flow_top.style.width = width
  local bars_top = {}
  for i = 1, bar_count do
    bars_top[i] = flow_top.add{
      type = "frame",
      style = styles.stats_tab.graph_box_green,
    }
    bars_top[i].style.width = bar_width
    bars_top[i].style.height = 0
  end
  local flow_bottom = graph_area.add{
    type = "flow",
    direction = "horizontal",
    style = styles.shared.horizontal_container
  }
  flow_bottom.style.vertical_align = "top"
  flow_bottom.style.width = width
  local bars_bottom = {}
  for i = 1, bar_count do
    bars_bottom[i] = flow_bottom.add{
      type = "frame",
      style = styles.stats_tab.graph_box_red,
    }
    bars_bottom[i].style.width = bar_width
    bars_bottom[i].style.height = 0
  end

  local flow_x_axis = graph_flow.add{
    type = "flow",
    direction = "horizontal",
    style = styles.shared.horizontal_container
  }
  flow_x_axis.style.width = width

  width = math.floor(width /3)
  local min_h = -math.floor(duration / 60 / 60 / 60 * 10) / 10
  local label = flow_x_axis.add{type = "label", caption  = min_h .. " hours"}
  label.style.width = width
  label.style.horizontal_align = "left"
  local x_labels = {left = label}

  min_h = -math.floor(duration / 60 / 60 / 60 / 2 * 10) / 10
  label = flow_x_axis.add{type = "label", caption  = min_h .. " hours"}
  label.style.width = width
  x_labels.center = label
  label.style.horizontal_align = "center"
  label = flow_x_axis.add{type = "label", caption  = "now"}
  label.style.width = width
  label.style.horizontal_align = "right"
  x_labels.right = label

  local flow_y_axis = content.add{
    type = "flow",
    direction = "vertical",
    style = styles.shared.vertical_container
  }
  flow_y_axis.style.top_padding = -6
  label = flow_y_axis.add{type = "label", caption  = ""}
  label.style.width = 35
  label.style.height = math.floor((height+20)/2)
  label.style.horizontal_align = "left"
  label.style.vertical_align = "top"
  egm.util.set_padding(label, 0)
  label.style.left_padding = 2
  local y_labels = {["top"] = label}

  label = flow_y_axis.add{type = "label", caption  = ""}
  label.style.width = 35
  label.style.height = math.floor((height+20)/2)
  label.style.horizontal_align = "left"
  label.style.vertical_align = "bottom"
  egm.util.set_padding(label, 0)
  label.style.left_padding = 2
  y_labels.bottom = label

  bar_graph_obj.root = outer_frame
  bar_graph_obj.selector = selector
  bar_graph_obj.title_label = title_label
  bar_graph_obj.bars_top = bars_top
  bar_graph_obj.bars_bottom = bars_bottom
  bar_graph_obj.bar_count = bar_count
  bar_graph_obj.duration = duration
  bar_graph_obj.height = height
  bar_graph_obj.y_labels = y_labels
  bar_graph_obj.x_labels = x_labels
  bar_graph_obj.statistics = args.statistics or global.statistics
  return bar_graph_obj
end

egm.manager.define_action(defs.actions.set_stats_item,--[[
Triggering elements:
  choose_elem buttons @ bar_graph
Event: on_gui_elem_changed
Data:
  graph :: egm_bar_graph
]]function(event, data)
    if event.name ~= defines.events.on_gui_elem_changed then return end
    local item = signal_to_item(event.element.elem_value)
    data.graph.title_label.caption = util.get_item_name(item)
    bar_graph.update(data.graph, item)
  end
)

return bar_graph