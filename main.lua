local lovebird = require("lib.lovebird")

function love.update()
  lovebird.update()
end

function love.load()
  require "example"
  print("Debug is available at http://127.0.0.1:" .. lovebird.port .. ".")
end
