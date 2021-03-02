# Typed Object

Object-oriented library with type checking.

Version: [2.x](typedobject-2.3-1.rockspec) (rewrited from scratch and still
improving!)

## Overview

- [x] [Perfomance at the first place](#perfomance).
- [x] [OO library writen in OO style](#oo-styled-source).
- [x] [Clean and easy debug](#easy-debug).
- [x] [Well documented](#documentation).
- [x] [Multiply inheritance](#inheritance).
- [x] [Member checking](#objectisthing-mode-logic).
  - [x] Type checking.
  - [x] Class and instance checking.
  - [x] Custom extra types checking.
  - [x] Assertions in Development mode.
- [x] [Metamethods support](#metamethods).
- [x] [Settings](#settings).

... Something is missing? [Request] your features!

[Request]:https://github.com/winterwolf/typedobject/issues

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

Mixing is performed from left to right, so if the arguments contain the same
values, then the left ones will be overwritten by the right ones.

### Class fields and methods

When class create instance, it calls constructor method (`new`) from self or its
closest super-class.

In any class method (including `new`) variable `self` refers to class instance.
Although it can be deliberately tampered with. Look at the example below:
`Rectangle.super.new(self, ...)` - we called `.new(something_else)` there
instead of `:new()`.

Class also can has own fields, which are available from its instance. Usually
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
Point:implement {test = function() return "working" end, nope = true}
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

#### Object:is(thing, mode, logic)

Universal member checking method. It is the most complicated one, but very
userful.

First at all, let me explain, what `mode` and `logic` is.

Both of them are string parameters that changes behavior of the function:

If `mode` is `"exact"` - simply compares `self` with `thing` and return result;

If `mode` is `"type"` - checks if `self` is the same **type** *(not a class)* as
`thing`. When `self` can be only a data to check, `thing` can be also a data or
a type name (string).

If `mode` is `"class"`, `"instance"` or `"member"` - checks if `thing` is a
class, instance, or any kind of member for `self` respectively.

If `mode` is `"exacts"`, `"classes"`, `"instances"`, `"members"` or `"types"`,
then `thing` must be a table with many things.

If `mode` is `"classes"`, `"instances"` or `"members"`, then `self` and `thing`
should be any of:

- Class (extended from Object)
- Class instance (created by calling a class)
- Any known class name (string)*

\* Keep in mind that `Object` should be required once from main script in all
your project to be able to remember all class names! Usually global variables is
not a good practice, but `Object` is exeption if you want to use OOP everywhere.

There are also short versions of `mode` available:

```lua
"e" = "exact"         "es" = "exacts"
"t" = "type"          "ts" = "types"
"c" = "class"         "cs" = "classes"
"i" = "instance"      "is" = "instances"
"m" = "member"        "ms" = "members"
```

Now lets talk about "`logic`". It can be one of four values:

- `"any"` - return **true** when `self` corresponds to `thing`;
- `"not"` - return **true** when `self` **not** corresponds to `thing`;
- `"all"` - return **true** if `thing` is a table with many things and **all**
  of them correspond to `self`;
- `"none"` - return **true** if `thing` is a table with many things and **none**
  of them correspond to `self`.

This function always returns boolean. `mode` and `logic` are optional.

Default `mode` is `"member"` and default `logic` is `"any"`.

Here is the shortest example of `Object:is()`:

```lua
assert(rect:is(Point))
```

More examples see in the next topic.

#### Object:assert(thing, mode, logic, message)

Does absolutely the same as method `Object:is()`, but throws error instead of
returning false and doesn't work in **Production** mode for maximum perfomance.

If `message` is provided, it will be added to default error message.

Destination of `Object.assert()` is not quite the same as usual `assert()`.
It works in a very similar way - makes checks and throws errors,
but the main purpose of this method is to make your code **typed**.

If you get in the habit of checking all the arguments inside each of your
functions, as well as describing the types of all fields inside all class
constructors with this method, then your code will turn into a real strongly
typed code and you will not need to use either emmylua or luadoc, because the
best code documentation is the code itself!

```lua
Object.assert(1, 1, "exact")
Object.assert("Rectangle", Point, "class")

Object.assert(rect, {false, "Rectangle"}, "instances")
rect:assert({false, "Rectangle"}, "is") -- equivalent

Object.assert(1, {2, "text"}, "types") -- is a number
Object.assert("number", {"number", "string"}, "types", "any") -- equivalent

Object.assert(1, {"float", "text"}, "types", "none")

Rectangle:assert(Point)
rect:assert({Point, "Point", Rectangle}, "members", "all")
rect:assert({3, "Point", Rectangle}, "members", "not")
```

#### Object:asserts(thing, mode, logic, message)

Does the same as `Object:assert()`, but `self` must be a table and each value of
this table will be asserted.

```lua
Object.asserts({1, 2, 3}, "number", "type")
```

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

Earlier I tried to implement a syntactic sugar as well for the
`Object.extend()` and `Object.new()`, but later I realized that it only creates
problems and is not compatible with the idea of strong-typing each class field
with `Object.assert()`, so I decided to remove it.

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
`Object.assert` and `Object.asserts` doesn't work there, but assertions still
helps a lot to better undersatand your code!

You can also add a table with extra types here:

```lua
local Object = require "typedobject" {
  production = false,
  extraTypes = {
    require "types.basic", -- Basic types: integer, float, char ...
    require "types.love",  -- LÖVE types: https://love2d.org/wiki/Types
  }
}

Object.assert(3.14, "float", "type")
```

## Conclusions and other thoughts

I'm a big fan of _simplicity_ and I believe that

```lua
if something:is(simple) and something:is(not stupid) then
  something.genious = true
end
```

That's why I prefer lua over any other programming language!

This simplicity gives me superpower to fix any bug you find. Please, feel free
to report any issues or whatever.

Maybe source code of this library is not so simple for everyone, but that's just
because OOP itself is not a simple thing. Atleast it's structured pretty
logical, so I hope, my lib will be a key to simplicity of your code! 😻
