-- LÖVE types: https://love2d.org/wiki/Types
return function(var, expected, got)
  if got ~= "userdata" then return false end
  if var.type and expected == var.type() then return true end
  if expected == "Drawable" then
    local Drawable = {
      Canvas = true,
      Framebuffer = true,
      Image = true,
      Mesh = true,
      ParticleSystem = true,
      SpriteBatch = true,
      Text = true,
      Texture = true,
      Video = true,
    }
    if Drawable[expected] then return true end
  end
  return false
end
