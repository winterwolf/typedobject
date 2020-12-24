local Object = require "typedobject" {
  production = false,   -- Turn it on to disable all typechecks in your code.
  extraTypes = {          -- Additional mods:
    (require "types.basic"),  -- Basic types: integer, float, char...
    (require "types.love"),   -- LÖVE types: https://love2d.org/wiki/Types
                              -- Create your own if necessary!
  }
}

-- Extend from Object to create a new typed class:
local Point = Object:extend "Point"
Point.scale = 2 -- Create class variable.

-- Class constructor:
function Point:init(x, y)
  -- It is a very good practice to check types of all your functions arguments.
  -- If production mode is enabled, all these function will do nothing,
  -- See `Object.assert` usage bellow, in tests section.
  Object.assert(x, "number")
  Object.assert(y, "number")
  self.x = x or 0
  self.y = y or 0
end

-- All metamethods are supported,
-- but you should use "__" AT THE END of their names!
function Point:call__(msg) return msg .. "!!!" end

function Point:getScaled()
  return self.x * Point.scale, self.y * Point.scale
end

local Rect = Point:extend "Rect"

function Rect:init(x, y, width, height)
  Object.asserts({x, y, width, height}, "number") -- assertS!
  Rect.super.init(self, x, y) -- Initialize superclass.
  self.width = width or 0
  self.height = height or 0
end

function Rect:index__(key)
  if key == "w" then return self.width end
  if key == "h" then return self.height end
  return rawget(self, key)
end

function Rect:newindex__(key, value)
  if key == "w" then self.width = value
    elseif key == "h" then self.height = value
    else rawset(self, key, value)
  end
end

local Super = Object:extend "Super"
Super.scale = 256

local SuperRect = Rect:extend("SuperRect", Super) -- Multiple inheritance.

function SuperRect:tostring__() return "I'm special!" end

local SuperMan = Super:extend{ -- This weird way also supported. 💁
  name__ = "SuperMan", -- In this case you must provide name__.
  name = "Clark",
  age = 15,
  color = "red",
  finish = function(self)
    print "All tests passed."
  end
}

local m = SuperMan{age = 5, name = "Adolf"} -- And this weird way too!
local p = Point(10, 20)
local r = Rect(2, 4, 6, 8)
local s = SuperRect(20, 40, 60, 80)
p.scale = r.scale * 2
s.w = 666

_L = { -- LoveBird export.
  Object = Object,
  Point = Point,
  Rect = Rect,
  Super = Super,
  SuperRect = SuperRect,
  SuperMan = SuperMan,
  p = p,
  r = r,
  s = s,
  m = m,
}

-- Object.assert(var, types..., "\nOptional message") -- \n is important!
Object.assert(3, "integer", "string", "\nUnacceptable!")
if love then -- LÖVE's type
  Object.assert(love.math.newRandomGenerator(), "RandomGenerator")
end
Object.assert(nil, "nil") -- Use quotes to check "nil"!
Object.assert(3, 3)
Object.assert("s", "s")
Object.assert("s", "string")
Object:assert(Object) -- Assert :self.
Object:assert("table")
Point:assert("Point")
Point:assert(Object, "if one is correct, others doesn't matter")
-- "\n!" means returning false instead of throwing errors!
assert(Object.assert(true, false, "\n!") == false)
assert(Object.assert(false, false, true) == true) -- Similar to method `is`.
assert(Object:is(Object, "table")) -- Unlike `assert`, `is` checks EACH type.
assert(Point:is("Point"))
assert(SuperRect:is(Point))
assert(s:is(Point, SuperRect, "Rect"))
assert(p:is(Point, "Point"))
assert(not p:is(Rect))
assert(p.scale == 4)
assert(p:getScaled() == 20, 40)
assert(s.width == 666)
assert(s.w == 666)
assert(r.w == 6)
assert(s.scale == 256)
assert(m.age == 5)
assert(m.color == "red")
assert(s("Ding-Dong") == "Ding-Dong!!!")

m:finish()
