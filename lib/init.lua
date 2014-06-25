printf("[init::gama]")
local fix = loadstring("function quick_class(classname, super) return class(classname, super) end ")
fix()
gama = gama or { }
gama.VERSION = "0.1.0"
gama.HOST = "localhost:8080"
gama.getAssetUrl = function(id)
  return "http://" .. tostring(gama.HOST) .. "/" .. tostring(id)
end
gama.getDescUrl = function(id)
  return "http://" .. tostring(gama.HOST) .. "/" .. tostring(id) .. ".json"
end
if not (gama.animation) then
  gama.animation = require("gama.animation")
end
