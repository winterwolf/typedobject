local Assist = {
  extraTypes = {}
}

local Object = {
  classname = "Object",
  classmap = setmetatable({}, {__mode = "kv",}),
  super = {}
}


function Assist:config(config)
  if type(config) ~= "table" then error("'config' must be a table", 2) end

  if config.production then
    Object.assert = function() end
  end
  if config.extraTypes then
    if type(config.extraTypes) ~= "table" then
      error("'config.extraTypes' must be a table", 2)
    end
    Assist.extraTypes = config.extraTypes
  end

  local mt = getmetatable(Object)
  mt.__call = Assist.instance
  setmetatable(Object, mt)
  return Object
end


function Assist:isTypeOf(thing)
  if thing == self then return true end
  local typeOfThing = type(thing)
  local typeOfSelf = type(self)
  if typeOfThing == "string" then typeOfThing = thing end
  if typeOfSelf == "string" then typeOfSelf = self end
  if typeOfThing == typeOfSelf then return true end
  for _, check in ipairs(Assist.extraTypes) do
    if check(self, typeOfThing, typeOfSelf) then return true end
    if check(thing, typeOfSelf, typeOfThing) then return true end
  end
  return false
end


function Assist:isMemberOf(cls)
  if not self or not cls then return false end

  local classname
  local classtype = type(cls)
  if classtype == "string" then classname = cls
  elseif classtype == "table" then classname = cls.classname
  else return false end

  local selftype = type(self)
  if selftype == "string" then self = Object.classmap[self]
  elseif selftype ~= "table" or not self.super then return false end

  if self.classname and not rawget(self, "classname") then
    if classname == self.classname then return "instance" end
  end

  while self.super do
    if self.classname == classname then return "class" end
    self = self.super
  end

  return false
end


function Assist:instance(...)
  local obj_mt = {
    __index = self,
    __tostring = function() return "instance of " .. self.classname end
  }
  local obj = setmetatable({}, obj_mt)
  obj:new(...)
  Assist.applyDefinedMetaFromClasses(self, obj_mt)
  Assist.applyCombinedIndexFromSelf(self, obj_mt)
  return setmetatable(obj, obj_mt)
end


function Assist:applyDefinedMetaFromClasses(apply_here)
  -- Rect > Point > Object
  local applied = {}
  while self.super do
    for key, value in pairs(self) do
      if key:find("__") == 1 then
        if not applied[key] then
          apply_here[key] = value
          applied[key] = true
        end
      end
    end
    self = self.super
  end
end


function Assist:applyCombinedIndexFromSelf(apply_here)
  if self.__index == nil then apply_here.__index = self return end

  apply_here.__index = function(instance, key)
    local definedType = type(self.__index)
    local value
    if definedType == "function" then value = self.__index(instance, key)
      elseif definedType == "table" then value = self.__index[key]
      else error("'__index' must be a function or table", 2)
    end
    if value ~= nil then return value end
    return self[key]
  end
end


function Object:new(args)
  local t = type(args)
  if t ~= "table" then
    error("'Object:new()' expected a table, but got " .. t, 3)
  end
  for key, value in pairs(args) do self[key] = value end
end


function Object:extend(classname, ...)
  if type(classname) ~= "string" then error("class must have a name", 2) end

  if Object.classmap[classname] then
    error("class '" .. classname .. "' already exists", 2)
  end

  local cls, cls_mt = {}, {}
  for key, value in pairs(getmetatable(self)) do cls_mt[key] = value end
  for _, extra in ipairs{...} do
    for key, value in pairs(extra) do cls[key] = value end
  end

  cls.classname = classname
  cls.super = self
  cls_mt.__index = self
  cls_mt.__tostring = function() return "class " .. classname end
  setmetatable(cls, cls_mt)
  Object.classmap[classname] = cls
  return cls
end


function Object:implement(...)
  for _, cls in pairs({...}) do
    for key, value in pairs(cls) do
      if self[key] == nil and type(value) == "function" then
        self[key] = value
      end
    end
  end
end


function Object:is(thing, mode, logic)
  mode = mode or "member"
  if       mode == "e"  then mode = "exact"
    elseif mode == "t"  then mode = "type"
    elseif mode == "c"  then mode = "class"
    elseif mode == "i"  then mode = "instance"
    elseif mode == "m"  then mode = "member"
    elseif mode == "es" then mode = "exacts"
    elseif mode == "ts" then mode = "types"
    elseif mode == "cs" then mode = "classes"
    elseif mode == "is" then mode = "instances"
    elseif mode == "ms" then mode = "members"
  end

  local function logicalCheck(check, bool)
    if logic == "all" then
      for _, table in ipairs(thing) do
        if not check(table) then return false end
      end
      return true
    else
      for _, table in ipairs(thing) do
        if check(table) == bool then return true end
      end
      return false
    end
  end

  local function massCheck()
    if type(thing) ~= "table" or thing.super then
      error("'thing' must be a table with 'things' in mode '" .. mode ..
        "', but it is a '" .. tostring(thing) .. "'", 3)
    end

    logic = logic or "any"
    local bool
    if logic == "any" then bool = true
    elseif logic == "not" then bool = false
    elseif logic ~= "all" then
      error("wrong logic: '" .. tostring(logic) .. "'", 3)
    end

    if mode == "exacts" then
      return logicalCheck(function(table)
        if self == table then return true end
        return false
      end, bool)
    elseif mode == "types" then
      return logicalCheck(function(table)
        if Assist.isTypeOf(self, table) then return true end
        return false
      end, bool)
    else
      return logicalCheck(function(table)
        local member = Assist.isMemberOf(self, table)
        if mode == "classes" and member == "class" then return true end
        if mode == "instances" and member == "instance" then return true end
        if mode == "members" and member then return true end
        return false
      end, bool)
    end
  end

  if mode == "exact" then
    if self ~= thing then return false end
  elseif mode == "type" then
    if not Assist.isTypeOf(self, thing) then return false end
  elseif mode == "class" or mode == "instance" or mode == "member" then
    local result = Assist.isMemberOf(self, thing)
    if result == mode then return true end
    if mode == "member" and result then return true end
    return false
  elseif
    mode == "exacts" or
    mode == "classes" or
    mode == "instances" or
    mode == "members" or
    mode == "types" then return massCheck()
  else error("incorrect mode: '" .. mode .. "'", 2) end
  return true
end


function Object:assert(thing, mode, logic, message)
  message = message or ""
  if message ~= "" then message = "\n" .. message end
  if not Object.is(self, thing, mode, logic) then
    if logic == "not" or logic == "all"
      then logic = logic .. " "
      else logic = ""
    end
    error("['" .. tostring(self) .. "' does not match '" ..
      tostring(thing) .. "' in mode '" .. tostring(logic) ..
      tostring(mode) .. "']" .. message, 2)
  end
end


Object.classmap.Object = Object
return setmetatable(Object, {
  __tostring = function(self) return "class " .. self.classname end,
  __call = Assist.config
})
