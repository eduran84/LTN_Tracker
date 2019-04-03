local class_dict = {
  LuaGuiElement = {
    name = true,
    type = true,
    parent = {"parent", "name"},
    children = true,
  },
  LuaTrain = {
    id = true,
    state = true,
    contents = "get_contents",
    fluid_contents = "get_fluid_contents",
  },
  LuaPlayer = {
    name = true,
    index = true,
    opened = true,
  },
  LuaEntity = {
    backer_name = true,
    name = true,
    type = true,
    position = true,
  },
  LuaCircuitNetwork = {
    entity = true,
    wire_type = true,
    signals = true,
    network_id = true,
    }
}
return class_dict