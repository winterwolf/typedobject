# Typed Object

Another one object-oriented library for lua. Powerful as [middleclass][], but
fast as [oo][].

It has one distinctive feature: when you create a class, you
give it a name, which will be considered a type name. Then you can call the
library's `assert` method, which is designed to compare your types as well as
any other - from lua, LÖVE or whatever (you can always add your own module for
extra types).

So my library provides not just OOP, but also _(optionally, in very simple form,
but)_ **strongly typed** OOP! In addition, when you call the library with the
parameter `production = true`, all the type checking functions in your code will
become dummy, so I can say that type checking does not affect performance at
all!

The main idea here is similar to [ldoc][] tags: use lines of code, from which
you could theoretically build documentation (can't promise, but maybe I'll add
this feature later), which in addition checks the correctness of types in your
functions arguments.

All lua versions >= 5.1 and < 6 (including luajit) are supported.

## Usage

Require library as `Object` with optional table argument:
{ production[bool], extraTypes[table with functions] }.

Use method `Class = Object:extend "ClassName"` to create your class.

Use `Class:init(...)` to define class consructor.

In constructor you can call superclass init method:
`Class.super.init(self, ...)` (don't forget to pass self).

The same way you can create your methods, including metamethods, but remember
that metamethods should be declared with postfix "__" instead of prefix
(after name): `Class:call__()`.

Create subclasses: `SubClass = Class:extend "SubClass"`.

Multiple inheritance and mixins:
`SubClass = Class:extend("SubClass", AnotherClass, {name = "bob"})`.

Use `Object.assert(var, types..., "\nOptional err message")` to describe types.
Error will rise if no one of described types don't match.

Use `Object.asserts` to describe multiply variables.

Use `Object:is` to check types without raising errors. Each type should match
to get `true`.

See [example](example.lua) and [source](typedobject.lua) for more details.

## Installation

Download [typedobject.lua](typedobject.lua) to your project dir and enjoy.

You can also use luarocks: `sudo luarocks install typedobject`.

[middleclass]: https://github.com/kikito/middleclass
[oo]: https://github.com/limadm/lua-oo
[ldoc]: https://stevedonovan.github.io/ldoc/manual/doc.md.html
