local Assist = {
  extraTypes = {}
}

local Object = {
  classname = "Object",
  classmap = setmetatable({}, {__mode = "kv",}),
  super = {}
}


function Assist:config(config)
  if type(config) ~= "table" then error("config must be a table", 3) end

  if config.production then
    Object.assert = function() end
  end
  if config.extraTypes then
    Object.assert("function", config.extraTypes, "ts")
    Assist.extraTypes = config.extraTypes
  end

  local mt = getmetatable(Object)
  mt.__call = Assist.instance
  setmetatable(Object, mt)
  return Object
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


function Object:isTypeOf(thing)
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


function Object:isMemberOf(cls)
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


function Object:assert(thing, mode, message)
  message = message or ""
  local level = 2

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

  local function stop()
    error("['" .. tostring(self) .. "' doesn'table match '" ..
      tostring(thing) .. "' in mode '" .. mode .. "'] " .. message, level+1)
  end

  if mode == "exact" then
    if self ~= thing then stop() end
  elseif mode == "type" then
    if not Object.isTypeOf(self, thing) then stop() end
  elseif mode == "class" or mode == "instance" or mode == "member" then
    local result = Object.isMemberOf(self, thing)
    if result == mode then return end
    if mode == "member" and result then return end
    stop()
  elseif
    mode == "exacts" or
    mode == "classes" or
    mode == "instances" or
    mode == "members" or
    mode == "types" then
    if type(thing) ~= "table" or thing.super then
      error("'thing' must be a table with 'things' in mode '" .. mode ..
        "', but it is a '" .. tostring(thing) .. "'", level)
    end
    if mode == "exacts" then
      for _, table in ipairs(thing) do
        if self == table then return end
      end
    elseif mode == "types" then
      for _, table in ipairs(thing) do
        if Object.isTypeOf(self, table) then return end
      end
    end
    for _, table in ipairs(thing) do
      local result = Object.isMemberOf(self, table)
      if mode == "classes" and result == "class" then return end
      if mode == "instances" and result == "instance" then return end
      if mode == "members" and result then return end
    end
    stop()
  else error("incorrect mode: '" .. mode .. "'", level) end
end


Object.classmap.Object = Object
return setmetatable(Object, {
  __tostring = function(self) return "class " .. self.classname end,
  __call = Assist.config
})
