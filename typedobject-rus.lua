--------------------------------------------------------------------------------
-- Typed Object
--------------------------------------------------------------------------------
-- version: 1.0.0 (with russian comments).
-- license: MIT.
-- Inspired by minimalism of lua-oo (https://github.com/limadm/lua-oo)
-- and functionality of middleclass (https://github.com/kikito/middleclass).
-- Предоставляет "объект", позволяющий реализовать полноценное ООП с
-- относительно строгой типизацией. В будущем я хотел бы прикрутить
-- к тайпчеку ещё и генератор документации, основанный на нём,
-- но это не самая простая задача 🤨.

local errorLevelDefault = 2
local errorLevel = errorLevelDefault

-- Заглушка для режима "production",
-- заменяющая собой функции, которые для этого режима не актуальны.
local function doNothing(...) return ... end

-- Первородный тип.
-- При вызове 🧺Object как функции, ему можно передать таблицу с настройками:
-- * production [false]: режим максимальной производительности
--   и минимального функционала.
local Object = {init = doNothing}

-- Приватный контейнер со всей иерархией типов.
local types = {[Object] = {[Object] = true}}

-- Приватный контейнер со всеми типами и их именами в качестве ключей.
local typesByNames = {["Object"] = Object}

-- Дополнительные типы, которые можно подключать в настройках объекта.
local extraTypes = {}

-- Проверка типа объекта.
local function objectTypesCheck(var, expected, got)
  if got ~= "table" then return false end
  got = types[var] -- Перезапись!
  if not got then return false end
  if type(expected) == "table" and got[expected] then return true
  elseif type(expected) == "string" and got[typesByNames[expected]] then
    return true
  end
  return false
end

-- Выполняет функцию применительно к себе и всем своим супер-классам.
local function superCall(self, func, ...)
  func(self, ...)
  if self.super then superCall(self.super, func, ...) end
end

-- Ищет у себя поля с "__" в конце.
-- Добавляет в таблицу mt все эти поля, но c "__" в начале.
-- Не меняет mt если в mt уже есть такое поле и "__" был найден в начале.
-- Не обрабатывает index.
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

-- Проверяет, является ли переменная типом или подтипом указанного множества.
-- Аргументы могут быть именами (строками) либо сущностями типов.
-- В случае успешной проверки возвращает true.
-- Если ни один тип не совпадает, вызывает ошибку.
-- Если последний аргумент начинается с символа переноса стоки (`\n`),
-- то он рассматривается не как тип, а как дополнение к сообщению об ошибке.
-- Аналогично, если последний аргумент false, то вместо ошибки возвращает false.
-- В режиме production заменяется на doNothing.
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

-- Проверяет, является ли переменная типом или подтипом указанного множества.
-- Аргументы могут быть именами (строками) либо сущностями типов.
-- В случае успешной проверки возвращает true.
-- Если хотя бы один тип не совпадает, возвращает false.
-- В режиме production продолжает функционировать, так что не злоупотребляйте.
local function is(var, ...)
  for _, expected in ipairs({...}) do
    if not typeAssert(var, expected, "\n!") then return false end
  end
  return true
end

-- Создаёт 🎁obj: экземпляр 📜self.
-- 📜self становится прототипом метатаблицы для 🎁obj
-- (но они не идентичны и реализовать метод is через их сравнение нельзя).
local function new(self, param, ...)
  local obj
  local mt = {
    __tostring = function() return "🎁" .. getmetatable(self).typename end
  }
  -- Добавляем пользовательский index при необходимости.
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

-- Вспомогательная функция для проверки типов внутри extend.
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

-- Создаёт 📜sub: подкласс 📜base.
-- Опционально принимает и подмешивает дополнительные таблицы,
-- позволяя реализовать множественное наследование.
-- В случае конфликта атрибутов, будет применено последнее подмешивание.
local function extend(base, name, ...)
  if type(name) == "table" then
    local name__ = name.name__
    name.name__ = nil
    return extend(base, name__, name)
  end
  checksInExtend(base, name)
  local sub = {init = base.init}
  -- Объявляем суперклассы и имя для 📜sub.
  types[sub] = {[sub] = true}
  if typesByNames[name] then
    error("type name `" .. name .. "` already existed", 2)
  end
  typesByNames[name] = sub
  for t in pairs(types[base]) do types[sub][t] = true end
  -- Подмешиваем значения в 📜sub.
  for _, extra in ipairs{...} do
    types[sub][extra] = true
    for k, v in pairs(extra) do sub[k] = v end
  end
  -- Создаём ссылки в 📜sub.
  sub.super    = base   -- Ссылаемся на 📜base как на суперкласс.
  sub.extend   = extend -- Добавляем метод наследования.
  sub.__index  = sub    -- Для 🎁sub метаиндексом будет 📜sub.
  -- Позволяем 📜sub проверять, принадлежит ли он классу или подклассу.
  function sub:is(...) return is(sub, ...) end
  local mt = {
    __call  = new, -- При вызове 📜sub создаёт свой экземпляр.
    __index = base, -- Метаиндекс 📜sub это его суперкласс.
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
    if opt.extraTypes then extraTypes = opt.extraTypes end
    return self
  end,
})

return Object
