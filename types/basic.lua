-- Basic types:
-- * "integer": integer number.
-- * "float":   float number.
-- * "char":    single utf8 string character.

math.type = math.type or function(x)
  if type(x) == "number" then
    if string.find(x, "%.") then return "float"
    else return "integer" end
  end
  return nil
end

return function(var, expected, got)
  if got == "number" then
    if expected == math.type(var) then return true end
  elseif got == "string" then
    if expected == "char" then
      local utf8 = utf8 or require "utf8"
      if utf8.len(var) == 1 then return true end
    end
  end
  return false
end
