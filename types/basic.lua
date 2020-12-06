-- Basic types:
-- * "integer": integer number.
-- * "float":   float number.
-- * "char":    single utf8 string character.
return function(var, expected, got)
  if got == "number" then
    if expected == "float" then
      if string.find(var, "%.") then return true end
    end
    if expected == "integer" then
      if not string.find(var, "%.") then return true end
    end
  elseif got == "string" then
    if expected == "char" then
      local utf8 = utf8 or require "utf8"
      if utf8.len(var) == 1 then return true end
    end
  end
  return false
end
