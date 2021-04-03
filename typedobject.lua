---@class __ObjectAssist
---@field __index Object|table
local Assist = {
  extraTypes = {},
  modes = {
    e = "exact",         es = "exacts",
    t = "type",          ts = "types",
    c = "class",         cs = "classes",
    i = "instance",      is = "instances",
    m = "member",        ms = "members",
  }
}

---@class Object
---@field classname string Name of current class.
---@field classmap table Table with all known classes, indexed by their names.
---@field super any Object's super class.
local Object = {
  classname = "Object",
  classmap = setmetatable({}, {__mode = "kv",}),
  super = {}
}


function Assist:isTypeOf(test)
  if test == self then return true end
  local typeOfSelf = type(self)
  if typeOfSelf == test then return true end
  local typeOfThing = type(test)
  if typeOfThing == "string" then typeOfThing = test end
  if typeOfThing == typeOfSelf then return true end
  for _, check in ipairs(Assist.extraTypes) do
    if check(self, typeOfThing, typeOfSelf) then return true end
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


function Assist:modeShortToLong()
  if self == nil then return "member" end
  for short, long in pairs(Assist.modes) do
    if self == short then self = long break end
  end
  return self
end


function Assist:modeOptional()
  if self == nil then return false end
  if string.sub(self, -1) == "?" then return true, string.sub(self, 1, -2) end
  return false, self
end


---Create instance of Object.
---@generic T
---@param self T
---@return T
function Object:new(...)
  local obj_mt = {
    __index = self,
    __tostring = function() return "instance of " .. self.classname end
  }
  local obj = setmetatable({}, obj_mt)
  obj:init(...)
  Assist.applyDefinedMetaFromClasses(self, obj_mt)
  Assist.applyCombinedIndexFromSelf(self, obj_mt)
  return setmetatable(obj, obj_mt)
end


---Constructor method (class initializer).
---@param fields table All `fields` will be applied to `self` by default.
function Object:init(fields)
  local t = type(fields)
  if t ~= "table" then
    error("'Object:init()' expected a table, but got " .. t, 3)
  end
  for key, value in pairs(fields) do self[key] = value end
end


---New class creation method.
---@param classname string Name of the new class.
---@vararg table|Object Extra fields and methods.
---@return Object
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


---Share new methods with a class.
---@vararg table|Object Extra methods.
function Object:implement(...)
  for _, cls in pairs({...}) do
    for key, value in pairs(cls) do
      if self[key] == nil and type(value) == "function" then
        self[key] = value
      end
    end
  end
end


---Check if `self` is `test` in different conditions.
---@param test any
---@param mode? string exact(s)|type(s)|classe(s)|instance(s)|member(s).
---Add `?` at the end of mode if `self` сan be `nil` (optional check).
---@param logic? string any|all|not|none.
---@return boolean
function Object:is(test, mode, logic)
  local optional
  optional, mode = Assist.modeOptional(mode)

  if optional and self == nil then return true end
  mode = Assist.modeShortToLong(mode)

  logic = logic or "any"
  local bool
  if logic == "any" or logic == "all" then bool = true
  elseif logic == "not" or logic == "none" then bool = false
  else
    error("wrong logic: '" .. tostring(logic) .. "'", 3)
  end

  local function logicalCheck(check)
    if logic == "all" or logic == "none" then
      for _, table in ipairs(test) do
        if not check(table) then return false end
      end
      return true
    else
      for _, table in ipairs(test) do
        if check(table) == bool then return true end
      end
      return false
    end
  end

  local function massCheck()
    if type(test) ~= "table" or test.super then
      error("'test' must be a table with 'tests' in mode '" .. mode ..
        "', but it is a '" .. tostring(test) .. "'", 3)
    end

    if mode == "exacts" then
      return logicalCheck(function(table)
        if self == table then return bool end
        return not bool
      end)
    elseif mode == "types" then
      return logicalCheck(function(table)
        if Assist.isTypeOf(self, table) then return bool end
        return not bool
      end)
    else
      return logicalCheck(function(table)
        local member = Assist.isMemberOf(self, table)
        if mode == "classes" and member == "class" then return bool end
        if mode == "instances" and member == "instance" then return bool end
        if mode == "members" and member then return bool end
        return not bool
      end)
    end
  end

  if mode == "exact" then
    if self ~= test then return not bool end
  elseif mode == "type" then
    if not Assist.isTypeOf(self, test) then return not bool end
  elseif mode == "class" or mode == "instance" or mode == "member" then
    local result = Assist.isMemberOf(self, test)
    if result == mode then return bool end
    if mode == "member" and result then return bool end
    return not bool
  elseif
    mode == "exacts" or
    mode == "classes" or
    mode == "instances" or
    mode == "members" or
    mode == "types" then return massCheck()
  else error("incorrect mode: '" .. mode .. "'", 3) end
  return bool
end


---Check if `self` is `test` and throw error if check failed.
---@param test any
---@param mode? string exact(s)|type(s)|classe(s)|instance(s)|member(s).
---Add `?` at the end of mode if `self` сan be `nil` (optional check).
---@param logic? string any|all|not|none.
---@param message? string
function Object:assert(test, mode, logic, message)
  local optional
  optional, mode = Assist.modeOptional(mode)

  if optional and self == nil then return true end
  mode = Assist.modeShortToLong(mode)

  message = message or ""
  if message ~= "" then message = "\n" .. message end
  local level = Assist.level or 2

  if not Object.is(self, test, mode, logic) then
    if logic == "not" or logic == "all" or logic == "none"
      then logic = logic .. " "
      else logic = ""
    end
    error("['" .. tostring(self) .. "' does not match '" ..
      tostring(test) .. "' in mode '" .. tostring(logic) ..
      tostring(mode) .. "']" .. message, level)
  end
end


---Do the same as `Object:assert`
---but `self` must be a table with multiply values.
function Object:asserts(...)
  if type(self) ~= "table" then
    error("method `Object.asserts()` expected `table` as first argument", 2)
  end
  Assist.level = 3
  for _, value in ipairs(self) do Object.assert(value, ...) end
  Assist.level = nil
end


---Disposable method for configuring Object before use.
---@param config? table
---@return Object
function Object.config(config)
  if config then
    if type(config) ~= "table" then error("'config' must be a table", 2) end
    if config.production then
      local do_nothing = function() end
      Object.assert = do_nothing
      Object.asserts = do_nothing
    end
    if config.extraTypes then
      if type(config.extraTypes) ~= "table" then
        error("'config.extraTypes' must be a table", 2)
      end
      for index, value in ipairs(config.extraTypes) do
        if type(value) ~= "function" then config.extraTypes[index] = nil end
      end
      Assist.extraTypes = config.extraTypes
    end
  end
  Object.config = nil
  return Object
end


Object.classmap.Object = Object
return setmetatable(Object, {
  __tostring = function(self) return "class " .. self.classname end,
  __call = Object.new
})
