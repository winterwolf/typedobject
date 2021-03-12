-- Use VSCode with lua-language-server extension
-- to see each variable in details!
-- https://code.visualstudio.com
-- https://marketplace.visualstudio.com/items?itemName=sumneko.lua


local Object = require("typedobject").config {
  production = false,
  extraTypes = {
    require "types.basic", -- Basic types: integer, float, char ...
    require "types.love",  -- LÖVE types: https://love2d.org/wiki/Types
  }
}

---@class Point:Object
local Point = Object:extend "Point"

Point.scale = 2 -- Class field!

function Point:new(x, y)
  self.x = x or 0
  self.y = y or 0
end

function Point:resize()
  self.x = self.x * self.scale
  self.y = self.y * self.scale
end

---@class Rectangle:Point
---@field super Point
local Rectangle = Point:extend "Rectangle"

function Rectangle:resize()
  Rectangle.super.resize(self) -- Extend Point's `resize()` method.
  self.w = self.w * self.scale
  self.h = self.h * self.scale
end

function Rectangle:new(x, y, w, h)
  Rectangle.super.new(self, x, y) -- Initialize Point first!
  self.w = w or 0
  self.h = h or 0
end

---@type Rectangle
local rect = Rectangle(2, 4, 6, 8)

Object.assert(1, "integer", "type")
Object.assert("Rectangle", Point, "class")

Object.assert(rect, {false, "Rectangle"}, "instances")
rect:assert({false, "Rectangle"}, "is") -- equivalent

Object.assert(1, {2, "text"}, "types") -- is a number
Object.assert("number", {"number", "string"}, "types", "any") -- equivalent

Object.assert(1, {"float", "text"}, "types", "none")

Rectangle:assert(Point)
rect:assert({Point, "Point", Rectangle}, "members", "all")
rect:assert({3, "Point", Rectangle}, "members", "not")

Object.assert(nil, 3, "e?") -- optional check

print "No errors!"
