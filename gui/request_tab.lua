local defs = defs
local egm = egm
local C = C

local item2sprite = util.item2sprite
egm.stored_functions[defs.functions.requests_row_constructor] = function(egm_table, data)
  local parent = egm_table.content
  local stop = data.stop
  local label = parent.add{
    type = "label",
    style = "hoverable_bold_label",
    caption = stop.name,
  }
  egm.manager.register(
    label, {
      action = defs.actions.select_stop_entity,
      stop_entity = stop.entity,
    }
  )
  local button = parent.add{
    type = "sprite-button",
    style = "slot_button",
    sprite = item2sprite(data.item),
    number = data.count,
    enabled = false,
  }
  label = parent.add{
    type = "label",
    caption = "0:00",
  }
  label = parent.add{
    type = "label",
    caption = stop.network_id,
  }
  local caption
  if stop.minTraincars ~= 0 and stop.maxTraincars ~= 0 then
    caption = stop.minTraincars .. " <= length <= " .. stop.maxTraincars
  elseif stop.maxTraincars ~= 0 then
    caption = "length <= " .. stop.maxTraincars
  elseif stop.minTraincars ~= 0 then
    caption = stop.minTraincars .. " <= length"
  else
    caption = "not set"
  end
  label = parent.add{
    type = "label",
    caption = caption,
  }


  label = parent.add{
    type = "label",
    caption = "this went wrong",
  }
end

local function build_request_tab(window)
  local tab_index = defs.tabs.requests
  local flow = egm.tabs.add_tab(
    window.pane,
    tab_index, {caption = {"ltnt.request_tab_caption"}},
    defs.functions.request_row_constructor
  )

  local request_table = egm.table.build(flow, {column_count = 6, caption = "Open Requests"}, defs.functions.requests_row_constructor)
  for i = 1, 6 do
    egm.table.add_column_header(request_table, {
      width = 86,
      caption = {"requests.header-col-" .. i},
      tooltip = {"requests.header-col-" .. i .. "-tt"},
    })
  end

  return request_table
end

local function update_request_tab(request_tab)
  local stops = global.data.stops
  local requests = global.data.requested_by_stop
  local providers = {}
  egm.table.clear(request_tab)
  for stop_id, request in pairs(requests) do
    if stops[stop_id] then
      for item, count in pairs(request) do
        providers[item] = providers[item] or {}
        for k, stop_id in pairs(global.data.item2stop[item]) do
          if global.data.provided_by_stop[stop_id] then providers[item] = nil end
        end
        egm.table.add_row(request_tab, {stop = stops[stop_id], item = item, count = count})
      end
    end
  end
end

return {build_request_tab, update_request_tab}
