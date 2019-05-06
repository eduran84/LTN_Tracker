logger.settings.class_dictionary.LuaGroup = {
  name = true,
  type = true,
  group = true,
  subgroups = true,
  order = true,
}

local type_blacklist = {
  ["blueprint-book"] = true,
  ["selection-tool"] = true,
  ["blueprint"] = true,
  ["copy-paste-tool"] = true,
  ["deconstruction-item"] = true,
  ["upgrade-item"] = true,
  ["rail-planner"] = true,
}

return
  function(item_groups, item_data)
    for k in pairs(item_groups) do
      item_groups[k] = nil
    end
    for k in pairs(item_groups) do
      item_data[k] = nil
    end
    local group_index = {}
    local group_count = 0
    for name, prototype in pairs(game.item_prototypes) do
      local is_hidden = prototype.flags and prototype.flags.hidden
          or type_blacklist[prototype.type]
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
        item_data[key] = item_groups[index].item_data[key]
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
      item_data[key] = item_groups[index].item_data[key]
    end
    table.sort(item_groups, function(a, b) return a.order < b.order end)

    for _, group in pairs(item_groups) do
      table.sort(group.item_data, function(a, b)
        if a.order_group ~= b.order_group then
          return a.order_group < b.order_group
        elseif a.order_subgroub ~= b.order_subgroub then
          return a.order_subgroub < b.order_subgroub
        else
          return a.order < b.order
        end
      end)
    end
    return item_groups, item_data
  end

