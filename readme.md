# Typed Object

Object-oriented library with type checking.

Version: 2.0 (rewrited from scratch!)

## Overview

- [x] [Perfomance at the first place](#perfomance).
- [x] [OO library writen in OO style](#oo-styled-source).
- [x] [Clean and easy debug](#easy-debug).
- [x] [Well documented](#documentation).
- [x] [Multiply inheritance](#inheritance).
- [x] [Member checking](#member-checking).
  - [x] Type checking.
  - [x] Class and instance checking.
  - [x] Custom extra types checking.
  - [x] Assertions in Development mode.
- [ ] [Syntactic sugar](#syntactic-sugar).
- [x] [Metamethods support](#metamethods).
- [x] [Settings](#settings).

... Something is missing? Request your features!

## Features

### Perfomance

I am always very sensitive to performance and memory consumption, so as soon as
all features will be thoroughly debugged and tested, I will begin to research my
code, looking for any smallest details that can be optimized.

### OO styled source

The source code is OOP-styled, so (I hope) even total noobs will be able to read
it and understand its strucrure without unnecessary comments.

### Easy debug

The library stores all metadata in metatables without cluttering regular tables
all sorts of *"__junk"*. Thus, during debugging, you will only see variables
that you have personally declared:

![debug example](https://imgur.com/K3RrC0W.png)

## Documentation

### First steps

Install script using luarocks: `sudo luarocks install typedobject`
or simply download it from this repository.

Now let's require it:

```lua
local Object = require "typedobject" ()
```

Please note that the parentheses at the end are important. `Object` must be
called once in order to configure themself.

### Inheritance

To create your class, simply extend from Object:

```lua
local Animal = Object:extend "Animal"
```

And now you can extend from your own class to create a subclass:

```lua
local Cat = Animal:extend "Cat"
```

You can mix other classes or just a simple tables when extend a class:

```lua
local Lion = Animal:extend("Lion", Cat, { strength = 100 })
```

Mixing is performed from left to right, so if the arguments contain the same values, then the left ones will be overwritten by the right ones.

### Class fields and methods

When class create instance, it calls constructor method (`new`) from self or its
closest super-class.

In any class method (including `new`) variable `self` refers to class instance.
Although it can be deliberately tampered with. Look at the example below:
`Rectangle.super.new(self, ...)` - we called `.new(something_else)` there
instead of `:new()`.

Class also can has own fields, which are available from its instanse. Usually
they used to store some constants in libs, for example: `Math.pi = 3.14`.

Okay, let's create some example class instance with fields and methods:

```lua
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

local Rectangle = Point:extend "Rectangle"

function Rectangle:new(x, y, w, h)
  Rectangle.super.new(self, x, y) -- Initialize Point first!
  self.w = w or 0
  self.h = h or 0
end

function Rectangle:resize()
  Rectangle.super.resize(self) -- Extend Point's `resize()` method.
  self.w = self.w * self.scale
  self.h = self.h * self.scale
end

local rect = Rectangle(2, 4, 6, 8)

rect:resize()

assert(rect.x, rect.y, rect.w, rect.h == 4, 8, 12, 16)
```

### Object's fields and methods

Here is a list of fields and methods that will be accessible from any of your
class and instance:

#### Object.classname

Name of current class (string).

```lua
assert(Object.classname == "Object")
assert(rect.classname == "Rectangle")
```

#### Object.super

Link to super class of the current class. For Object is empty table.

```lua
assert(type(Object.super) == "table" and #Object.super == 0)
assert(Rectangle.super.classname == "Point")
```

#### Object:implement(...)

Copy all methods/functions from provided classes/tables to `self`.

Everything that is not a function will be ignored.

```lua
Point:implement { ["test"] = function() return "working" end, nope = true }
assert(rect:test() == "working" and not rect.nope)
```

#### Object.classmap

Table with all known classes, indexed by their names.

Classes are automatically added to this table when you create them and are
automatically removed from it by the garbage collector if they are not used
anywhere.

```lua
assert(Object.classmap.Point.classname == "Point")
```

### Member checking

In addition to the list above, here I list the verification methods:

#### Object:isTypeOf(thing)

Checks if `self` is the same **type** *(not a class)* as `thing`.

Arguments can be a type names (strings) or anything else.

```lua
assert(Rectangle:isTypeOf(Point))
assert(Point:isTypeOf(Rectangle))
assert(Object:isTypeOf("table"))
assert(Object.isTypeOf("table", Object))
assert(Object.isTypeOf("number", 1))
assert(Object.isTypeOf(1, 2))
```

#### Object:isMemberOf(cls)

Checks if `self` is member of `cls` (or this class inself).

Arguments can be any of:

- Class (extended from Object)
- Class instance (created by calling a class)
- Any known class name (string)*

If `self` is member of `cls`, returns string `"instance"` or `"class"`.
Else returns `false`.

```lua
assert(Point:isMemberOf(Point) == "class")
assert(Rectangle:isMemberOf(Point))
assert(not Point:isMemberOf(Rectangle))
assert(rect:isMemberOf(Rectangle))
assert(rect:isMemberOf("Point") == "instance")
assert(Object.isMemberOf("Rectangle", "Object"))
```

\* Keep in mind that `Object` should be required once from main script in all
your project to be able to remember all class names! Usually global variables is
not a good practice, but `Object` is exeption if you want to use OOP everywhere.

#### Object:assert(thing, mode, message)

This one is the most complicated, but very userful.

If `mode` is `"exact"` - simply compares `self` with `thing` and throw error if
got false;

If `mode` is `"type"` - do `Object:isTypeOf(thing)` and throw error if got
false;

If `mode` is `"class"`, `"instance"` or `"member"` - do
`Object:isMemberOf(thing)` and throw error if `mode` does not match the result
("member" means - no matter class or instance).

If `mode` is `"exacts"`, `"classes"`, `"instances"`, `"members"` or `"types"`,
then `thing` must be a table with many things and error will be thrown if no one
of them doesn't match the `self`.

There is also short versions of `mode` available:

`"e"`, `"t"`, `"c"`, `"i"`, `"m"` and

`"es"`, `"ts"`, `"cs"`, `"is"`, `"ms"`.

If `message` is provided, it will be added to default error message.

```lua
Object.assert(1, 1, "exact")
Object.assert("Rectangle", Point, "class")

Object.assert(rect, {false, "Rectangle"}, "instances")
rect:assert({false, "Rectangle"}, "is") -- equivalent

Object.assert(1, {2, "text"}, "types") -- is a number
Object.assert(1, {"number", "string"}, "types") -- equivalent
```

Appointment of `Object.assert` is not quite the same as usual `assert`.
It works in a very similar way - makes checks and throw errors,
but the main purpose of this method is to make your code typed.

If you get in the habit of checking all the arguments inside each of your
functions, as well as describing the types of all fields inside all class
constructors with this method, then your code will turn into a real strongly
typed code and you will not need to use either emmylua or luadoc, because the
best code documentation is the code itself!

In addition, you don't have to worry about performance degradation due to the
huge number of asserts, because in **Production** mode all of them are replaced
with dummies.

That's why `Object.assert(1, 1, "exact")` is better than `assert(1 == 1)`.

### Syntactic sugar

As I said above, when class create instance, it calls constructor method (`new`)
from self or its closest super-class. Now you should know that `Object`'s
constructor is not nil. If you didn't define this method in your classes, then
by default it will take a table and apply all its fields to `self`.

```lua
local Test = Object:extend "Test"

local test = Test {
  x = 123,
  test = function(self)
    return self.x
  end
}

assert(test:test() == 123)
```

**!!!WARNING!!!** THIS FEATURE ISN'T READY YET !!!

You can also initialize your classes with constructors a little bit simplier.

Instead of this:

```lua
local Rectangle = Point:extend "Rectangle"

function Rectangle:new(x, y, w, h)
  Point.new(self, x, y)
  self.w = 6
  self.h = 8
end
```

You can use such syntax:

```lua
local Rectangle = Point:extend {
  classname = "Rectangle", w = 6, h = 8,
  new = function(self, x, y)
    Point.new(self, x, y)
  end
}
```

Maybe in this example it doesn't look much better, but sometimes we are faced
with a situation when we need to initialize a class with a large number of
fields, and in this case it's much easier to pass a table with these fields than
to assign each one via `self`.

### Metamethods

If your class method has a name starting with "__", it will be assigned as a
metamethod for the class instance. Just like other methods, metamethods can be
inherited through super classes.

```lua
function Point:__call()
  print "called"
end

function Rectangle:__index(key)
  if key == "width" then return self.w end
  if key == "height" then return self.h end
end

function Rectangle:__newindex(key, value)
  if key == "width" then self.w = value
    elseif key == "height" then self.h = value
  end
end

rect() -- "called"

rect.width = 666

assert(rect.w == 666)
assert(rect.height == 16)
```

### Settings

By default `Object` works in **Development** mode. This means that it will try
to help you as it can, giving convenient hints for debugging. But in theory this
can reduce performance, so before the release of your project it makes sense to
switch `Object` to **Production** mode:

```lua
local Object = require "typedobject" { production = true }
```

The most important thing you should know about **Production** mode is that
`Object.assert` doesn't nothing there, but assertions still helps a lot to
better undersatand your code!

You can also add a table with extra types here:

```lua
local Object = require "typedobject" {
  production = false,
  extraTypes = {
    require "types.basic", -- Basic types: integer, float, char ...
    require "types.love",  -- LÖVE types: https://love2d.org/wiki/Types
  }
}

assert(Object.isTypeOf(3.14, "float"))
assert(Object.isTypeOf("integer", 3))
```

## Conclusions and other thoughts

I'm a big fan of _simplicity_ and I believe that

```lua
if something_simple:is(not stupid) then
  self.genious = true
end
```

That's why I prefer lua over any other programming language!

This simplicity gives me superpower to fix any bug you find. Please, feel free
to report any issues or whatever.

Maybe source code of this library is not so simple for everyone, but that's just
because OOP itself is not a simple thing. Atleast it's structured pretty
logical, so I hope, my lib will be a key to simplicity of your code! 😻
