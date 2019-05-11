local function item_sort_function(a, b)
  if a.order_group ~= b.order_group then
    return a.order_group < b.order_group
  elseif a.order_subgroub ~= b.order_subgroub then
    return a.order_subgroub < b.order_subgroub
  else
    return a.order < b.order
  end
end

return
  function(item_groups)
    -- delete all entries to keep reference alive
    for k in pairs(item_groups) do
      item_groups[k] = nil
    end
    local group_index = {}
    local group_count = 0
    for name, prototype in pairs(game.item_prototypes) do
      local is_hidden = prototype.flags and prototype.flags.hidden
          or defs.item_display_blacklist[prototype.type]
      if not is_hidden then
        local group = prototype.group
        local index
        if group_index[group.name] then
          index = group_index[group.name]
        else
          group_count = group_count + 1
          index = group_count
          group_index[group.name] = index
          item_groups[group_count] = {
            name = group.name,
            localised_name = group.localised_name,
            sprite = group.type .. "/" .. group.name,
            order = group.order,
            item_data = {},
          }
        end
        local key = "item," .. name
        item_groups[index].item_data[key] = {
          name = prototype.name,
          sprite = "item/" .. name,
          localised_name = prototype.localised_name,
          order_group = group.order,
          order_subgroub = prototype.subgroup.order,
          order = prototype.order,
        }
      end
    end
    for name, prototype in pairs(game.fluid_prototypes) do
      local group = prototype.group
      local index
      if group_index[group.name] then
        index = group_index[group.name]
      else
        group_count = group_count + 1
        index = group_count
        group_index[group.name] = index
        item_groups[group_count] = {
          name = group.name,
          sprite = group.type .. "/" .. group.name,
          order = group.order,
          item_data = {},
        }
      end
      local key = "fluid," .. name
      item_groups[index].item_data[key] = {
        name = prototype.name,
        sprite = "fluid/" .. name,
        localised_name = prototype.localised_name,
        order_group = group.order,
        order_subgroub = prototype.subgroup.order,
        order = prototype.order,
      }
    end

    table.sort(item_groups, function(a, b) return a.order < b.order end)
    for _, group in pairs(item_groups) do
      group.item_data = util.sort(group.item_data, item_sort_function)
    end
  end