-- LÖVE types: https://love2d.org/wiki/Types
return function(var, expected, got)
  if got ~= "userdata" or not var.type then return false end
  local vartype = var.type()
  if expected == vartype then return true end
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
    if Drawable[vartype] then return true end
  end
  return false
end
