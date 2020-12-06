# Typed Object

Another one object-oriented library for lua. Powerful as [middleclass][], but
fast as [oo][].

It has one distinctive feature: When you create a class, you
give it a name, which will be considered a type name. Then you can call the
library's `assert` method, which is designed to compare your types as well as
any other - from lua, LÖVE or whatever, you can always add your own module for
extra types.

So my library provides not just OOP, but also _(optionally)_
**strongly typed** OOP! In addition, when you call the library with the
parameter `production = true`, all the type checking functions in your code will
become dummy, so I can say that type checking does not affect performance at
all!

Currently I tested my lib only on lua version 5.1 (luajit), but I'll port it to
all newer ones soon.

## Usage

See [example.lua](example.lua).

## Installation

Download [typedobject.lua](typedobject.lua) to your project dir and enjoy.

[middleclass]: https://github.com/kikito/middleclass
[oo]: https://github.com/limadm/lua-oo
