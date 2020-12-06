function love.conf(t) -- Minimal conf
  t.identity =           "TypedClass"
  t.version =                  "11.3"
  t.console =                    true

  t.modules.thread =             true
  t.modules.event =              true
  t.modules.math =               true
  t.modules.system =             true
  t.modules.timer =              true

  t.modules.window =            false
  t.modules.graphics =          false
  t.modules.image =             false
  t.modules.sound =             false
  t.modules.keyboard =          false
  t.modules.mouse =             false
  t.modules.audio =             false
  t.modules.video =             false
  t.modules.physics =           false
  t.modules.joystick =          false
  t.modules.touch =             false
end
