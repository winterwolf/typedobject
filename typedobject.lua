--------------------------------------------------------------------------------
-- Typed Object
--------------------------------------------------------------------------------
-- version: 1.0.0.
-- license: Unlicense.
-- Inspired by minimalism of lua-oo (https://github.com/limadm/lua-oo)
-- and functionality of middleclass (https://github.com/kikito/middleclass).
-- Provides an "Object" that allows you to implement full-fledged OOP with
-- relatively strong typing. In the future, I would like to attach a
-- documentation generator based on typecheck, but this is not an easy task 🤨.

local errorLevelDefault = 2
local errorLevel = errorLevelDefault

-- Stub for "production" mode, replacing functions that are not relevant there.
local function doNothing(...) return ... end

-- The original root type.
-- When calling 🧺Object as a function, you can pass a table with settings:
-- * production [false]: mode of maximum performance and minimum functionality.
local Object = {init = doNothing}

-- A private container with the entire type hierarchy.
local types = {[Object] = {[Object] = true}}

-- A private container with all types and their names as keys.
local typesByNames = {["Object"] = Object}

-- Additional types that can be connected in the object settings.
local extraTypes = {}

local function objectTypesCheck(var, expected, got)
  if got ~= "table" then return false end
  got = types[var] -- Rewrite!
  if not got then return false end
  if type(expected) == "table" and got[expected] then return true
  elseif type(expected) == "string" and got[typesByNames[expected]] then
    return true
  end
  return false
end

-- Call a function in relation to self and all super-classes.
local function superCall(self, func, ...)
  func(self, ...)
  if self.super then superCall(self.super, func, ...) end
end

-- Looks for fields with "__" at the end.
-- Adds all these fields to table mt, but with "__" at the beginning.
-- Doesn't change mt if mt already has such a field
-- and "__" was found at the beginning.
-- Doesn't handle index.
local function replace__methods(self, mt)
  for k, v in pairs(self) do
    local found = k:find("__")
    if found == #k-1 then
      local name = k:sub(1, #k-2)
      if name ~= "index" then mt["__" .. name] = v end
    elseif found == 1 then
      mt[k] = mt[k] or v
    end
  end
end

-- Checks if a variable is a type or a subtype of the specified set.
-- Arguments can be names (strings) or type entities.
-- Returns true if successful.
-- Raises an error if none of the types match.
-- If the last argument starts with a new line character (`\n`),
-- it is considered not as a type, but as addition to the error message.
-- Similarly, if the last argument is false, it returns false instead of error.
-- Replaced with `doNothing` in production mode.
local function typeAssert(var, ...)
  local checks = {...}
  local lastCheckIndex = #checks
  local got = type(var)
  local message = ""
  local lastCheck = checks[lastCheckIndex]
  local emptyMsg = "Empty assertion detected!"
  if lastCheck == "\n!" then
    message = false
    checks[lastCheckIndex] = nil
  elseif type(lastCheck) == "string" and
    string.sub(lastCheck, 1, 1) == "\n" then
    message = lastCheck
    checks[lastCheckIndex] = nil
  end
  if #checks == 0 then
    error(emptyMsg, errorLevel)
  end
  for _, expected in ipairs(checks) do
    if expected == got or expected == var then return true end
    if objectTypesCheck(var, expected, got) then return true end
    for _, check in ipairs(extraTypes) do
      if check(var, expected, got) then return true end
    end
  end
  if not message then return false end
  for i, check in ipairs(checks) do
    if type(check) == "table" then
      checks[i] = getmetatable(check).typename
    end
  end
  local expected
  for index, value in ipairs(checks) do checks[index] = tostring(value) end
  expected = table.concat(checks, " or ")
  if expected == "" or var == nil then
    error(emptyMsg .. message, errorLevel)
  end
  local value = tostring(var)
  error(expected .. " expected, got " .. got ..
  ": " .. value .. message, errorLevel)
end

-- Checks if a variable is a type or a subtype of the specified set.
-- Arguments can be names (strings) or type entities.
-- Returns true if successful.
-- Returns false if at least one type does not match.
-- It continues to function in production mode, so don't abuse it.
local function is(var, ...)
  for _, expected in ipairs({...}) do
    if not typeAssert(var, expected, "\n!") then return false end
  end
  return true
end

-- Creates 🎁obj: an instance of 📜self.
-- 📜self becomes the metatable prototype for 🎁obj.
local function new(self, param, ...)
  local obj
  local mt = {
    __tostring = function() return "🎁" .. getmetatable(self).typename end
  }
  -- Add custom index if needed.
  if self.index__ then
    self.__index = function(this, key)
      -- print("DEBUG", self, this, key)
      return self.index__(this, key) or self[key] or rawget(this, key)
    end
  end
  superCall(self, replace__methods, mt)
  if not ... and type(param) == "table" then
    obj = setmetatable(param, mt)
    obj:init()
  else
    obj = setmetatable({}, mt)
    obj:init(param, ...)
  end
  return obj
end

-- Helper function for type checking inside extend method.
local function checksInExtend(base, name)
  local errorNoName = "Please provide a name for the new type!"
  if not name then
    errorLevel = errorLevelDefault + 2
    typeAssert(base, Object,
      "\nMake sure you are using `Object:extend`, not `Object.extend`!")
    error(errorNoName, errorLevelDefault + 1)
  end
  typeAssert(name, "string", "table", "\n" .. errorNoName)
  errorLevel = errorLevelDefault
end

-- Creates 📜sub: a subclass of 📜base.
-- Optionally accepts and mixes additional tables,
-- allowing to implement multiple inheritance.
-- In case of a conflict of attributes, the last mixin will be applied.
local function extend(base, name, ...)
  if type(name) == "table" then
    local name__ = name.name__
    name.name__ = nil
    return extend(base, name__, name)
  end
  checksInExtend(base, name)
  local sub = {init = base.init}
  -- Declares superclasses and a name for 📜sub.
  types[sub] = {[sub] = true}
  if typesByNames[name] then
    error("type name `" .. name .. "` already existed", 2)
  end
  typesByNames[name] = sub
  for t in pairs(types[base]) do types[sub][t] = true end
  -- Mixes the values in 📜sub.
  for _, extra in ipairs{...} do
    types[sub][extra] = true
    for k, v in pairs(extra) do sub[k] = v end
  end
  -- Creates links in 📜sub.
  sub.super    = base   -- Refers to 📜base as a superclass.
  sub.extend   = extend -- Add an inheritance method.
  sub.__index  = sub    -- For 🎁sub, the meta-index is 📜sub.
  -- Let 📜sub check if it belongs to a class or a subclass.
  function sub:is(...) return is(sub, ...) end
  local mt = {
    __call  = new, -- When 📜sub is called, it creates its own instance.
    __index = base, -- The meta-index 📜sub is its superclass.
    __tostring = function() return "📜" .. name end,
    typename = name,
  }
  return setmetatable(sub, mt)
end

Object.is = is
Object.extend = extend
Object.assert = typeAssert
Object.asserts = function(vars, ...)
  for _, var in ipairs(vars) do typeAssert(var, ...) end
end


setmetatable(Object, {
  __tostring = function() return "🧺Object" end,
  __call = function(self, opt)
    opt = opt or {}
    if opt.production then
      self.assert    = doNothing
      self.asserts   = doNothing
      checksInExtend = doNothing
    end
    if opt.extraTypes then
      for _, extype in ipairs(opt.extraTypes) do
        if type(extype) == "function" then table.insert(extraTypes, extype) end
      end
    end
    return self
  end,
})

return Object
