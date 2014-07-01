printf("[gama] init")
local fix = loadstring("function quick_class(classname, super) return class(classname, super) end ")
fix()
JSON = JSON or { }
local cjson = require("cjson")
JSON.stringify = function(value, callback)
  if type(callback) == "function" then
    local status, result = pcall(cjson.encode, var)
    if status then
      callback(nil, result)
    else
      callback("JSON.stringify failed, error:" .. tostring(result))
    end
  else
    return cjson.encode(value)
  end
end
JSON.parse = function(text, callback)
  if type(callback) == "function" then
    local status, result = pcall(cjson.decode, text)
    printf("[init::JSON::parse] status:" .. tostring(status) .. ", result:" .. tostring(result))
    if status then
      callback(nil, result)
    else
      callback("JSON.parse failed, error:" .. tostring(result))
    end
  else
    return cjson.decode(text)
  end
end
gama = gama or { }
gama.VERSION = "0.1.0"
gama.HOST = "127.0.0.1:8080"
if not (gama.http) then
  gama.http = require("gama.http")
end
if not (gama.asset) then
  gama.asset = require("gama.asset")
end
if not (gama.animation) then
  gama.animation = require("gama.animation")
end
