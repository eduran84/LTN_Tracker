-- only ever create or modify GuiComposition objects during control.lua initialization
-- as defined by https://lua-api.factorio.com/latest/Data-Lifecycle.html
-- creating new objects, using the .add method or modifying any properties
-- during later phases will result in desyncs

-- helper functions
local format = string.format

---------------------------------
-- class setup and constructor --
---------------------------------
local GuiComposition = {}
do -- 
GuiComposition.__index = GuiComposition
setmetatable(GuiComposition, {
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function GuiComposition:_init(name, args)
  if game then out.error("Forbidden at runtime.") end  
  out.assert(
    type(name) == "string" and name == name:match("[%w_]+"),
    "Name must be a valid lua variable name, i.e. a string consisting of only letters, digits and underscores.\nname=", name, "args=", args
  )   
  self.name = name
  self.elem = {}   -- stores UI element definitions in an indexed array
  self.n2i = {}    -- name -> index lookup table
  self.sub_gc = {} -- if other GC objects are nested into this one, they are stored here
  self.events = {} -- events registered by elements
  for _,eid in pairs(GUI_EVENTS) do
    self.events[eid] = {}
  end  
  self._fstring1 = format("%s_%s%%03d_%%s", MOD_PREFIX, self.name)
  self._fstring2 = format("%s_%s%%03d", MOD_PREFIX, self.name)
  if args then
    args.name = "root"
    self:add(args)
  end  
end
end

function GuiComposition:add(args) -- parent_name, name, params, style, event
  if game then out.error("Forbidden at runtime.") end 
  -- lengthy input check, because I suck at using my own code
  out.assert(args, ":add method called without input arguments or with a dot instead of a colon.")
  out.assert(args.name, "Name missing.\nargs =", args)
  out.assert(
    type(args.name) == "string" and args.name == args.name:match("[%w_]+"),
    "Name must be a valid lua variable name, i.e. a string consisting of only letters, digits and underscores.\nargs =", args
  )
  local name = args.name  
  if name ~= "root" then
    out.assert(args.parent_name and type(args.parent_name) == "string", "Invalid parent name or parent_name missing.\nargs =", args)
    out.assert(
      self.elem[self.n2i[args.parent_name]],
      "Parent", args.parent_name, "does not exist in GuiComposition", self.name, ".\nself:", self
    )    
  end   
  local parent_name = args.parent_name
  if self.n2i[name] then
    out.error("Element with name", name, "does already exist and cannot be added again.")
  end 
  
  if args.gui_composition then
    -- for GCs: store GC and register as child with the correct parent element
    self.sub_gc[name] = args.gui_composition
    local chn = self.elem[self.n2i[parent_name]].children_index
    chn[#chn+1] = name     
  else
    -- some additional input checks for normal elements
    if not (args.params and args.params.type) then
      out.error("The following parameter list is invalid:", args and args.params)
    end  
    if args.style then
      out.assert(type(args.style) == "table", "Style argument has to be a table. Provided style argument:", args.style)
    end 
    
    local path, myindex = {}, #self.elem + 1
    local next_index, data = nil, nil 
    -- store events first, they can modify the name
    if args.event then
      local eid = args.event.id 
      self.events[eid][myindex] = args.event.handler     
      if args.event.data then
        data = args.event.data
      end 
    end 
    args.params.name = self:_create_name(myindex, data)
    -- figure out path relative to root element
    if name ~= "root" then
      next_index = self.n2i[parent_name]
      local chn = self.elem[next_index].children_index
      chn[#chn+1] = myindex  
      while self.elem[next_index].parent_index do
        path[#path+1] = self.elem[next_index].params.name
        next_index =  self.elem[next_index].parent_index
      end
    end 
    -- store everything
    self.elem[myindex] = {
      parent_index = self.n2i[parent_name],
      params = args.params,
      style = args.style,
      events = args.events,
      path = path,
      children_index = {},
    }
    self.n2i[name] = myindex
  end -- if args.gui_composition then
end

----------------------
-- on_init, on_load --
----------------------

function GuiComposition:on_init(storage_tb)
  storage_tb[self.name] =  storage_tb[self.name] or {}
  storage_tb[self.name].root = storage_tb[self.name].root or {}
  self.mystorage = storage_tb[self.name]
  for _,gc in pairs(self.sub_gc) do
    gc:on_init(storage_tb)
  end
end
function GuiComposition:on_load(storage_tb)
  self.mystorage = storage_tb[self.name]
  for _,gc in pairs(self.sub_gc) do
    gc:on_load(storage_tb)
  end
end

---------------------
-- RUNTIME METHODS --
---------------------
-- the following methods are (fingers crossed) safe to use at runtime
-- :build must be called for each player in on_init and on_player_created

function GuiComposition:build(parent, pind)
  out.assert(self.elem[1], "Root not set for GuiComposition", self.name)
  self:destroy(pind)
  --out.info("GuiComposition:build", "Pre-build status:\n", self)
  out.assert(parent and parent.valid, "Invalid parent specified when calling build method of GuiComposition object with name", self.name)  
  self.mystorage.root[pind] = self:_build_single_element(1, parent, pind)
end


-- !TODO: disable asserts for release version in following methods

function GuiComposition:get(pind)
  out.assert(self.mystorage, "GuiComposition object", self.name, "has not been initialized.")
  out.assert(type(pind) == "number", "Argument has to be a player index. Argument received:", pind)
  return self.mystorage.root[pind]
end

function GuiComposition:get_el(pind, element_name)
  local element_index = self.n2i[element_name]  
  -- !TODO: disable asserts for release version
  out.assert(self.mystorage, "GuiComposition object", self.name, "has not been initialized.")
  if not (element_name and self.elem[element_index]) then
    if debug_level > 0 then
      out.warn("GC object", self.name, "does not have an element with name", element_name)
    end    
    return nil
  else    
    local element = self:get(pind)
    local path = self.elem[element_index].path
    for i = #path,1,-1 do
      element = element[path[i]]
    end
    element = element[self.elem[element_index].params.name]
    return element
  end  
end

function GuiComposition:destroy(pind)
  if self:get(pind) then
    self:get(pind).destroy()
    self.mystorage.root[pind] = nil
    return true
  else
    return false
  end  
end

function GuiComposition:show(pind)
  if self:get(pind) then
    self:get(pind).style.visible = true
  end  
end

function GuiComposition:hide(pind)
  if self:get(pind) then
    self:get(pind).style.visible = false
  end  
end

function GuiComposition:is_visible(pind)
  return self:get(pind).style.visible
end

function GuiComposition:toggle(pind)
  local root = self:get(pind)
  if root then
   root.style.visible = not root.style.visible
   return root.style.visible
 else
   return nil
 end
end

function GuiComposition:get_event_handler(event, index, data_string)
  local eid = event.name
  local pind = event.player_index
  if index <= #self.elem then
    local handler = self.events[eid][index]
    if not handler then
      return nil
    elseif type(handler) == "string" then
      return handler      
    elseif type(handler) == "function" then
      handler(event, index, data_string)
      return nil
    else
      self[handler[1]](self, event, index, data_string)
    end    
  else
    return self:event_handler(event, index, data_string)
  end
end

function GuiComposition:event_handler(event, index, data_string)
  -- to be implemented in object or subclass if needed
  return nil
end

-- helper methods, not meant to be called directly
  
function GuiComposition:_build_single_element(element_id, parent, pind)
  if type(element_id) == "number" then -- build regular element
    local element = self.elem[element_id]
    local gui_element = parent.add(element.params)
    if element.style then
      for style_key, value in pairs(element.style) do
        gui_element.style[style_key] = value
      end
    end  
    if element.children_index then
      for _, child_id in pairs(element.children_index) do
        self:_build_single_element(child_id, gui_element, pind)
      end
    end
    return gui_element
  else -- call build for nested GuiComposition objects
    local gc = self.sub_gc[element_id]
    gc:build(parent, pind)
  end  
end

local _tostring = tostring
function GuiComposition:_create_name(index, data)
  if data then
    return format(self._fstring1, index, _tostring(data))
  else    
    return format(self._fstring2, index)
  end  
end

function GuiComposition:element_by_name(name)
  return self.elem[self.n2i[name]]
end

return GuiComposition