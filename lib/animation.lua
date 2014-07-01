local async = require("async")
local animation = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local TEXT_FIELD_ID
local _exp_0 = device.platform
if "android" == _exp_0 then
  TEXT_FIELD_ID = "pkm"
elseif "ios" == _exp_0 then
  TEXT_FIELD_ID = "pvrct4"
else
  TEXT_FIELD_ID = "png8"
end
animation.loadById = function(id, callback)
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  local url = gama.getDescUrl(id)
  printf("[animation::loadById] url:" .. tostring(url))
  gama.http.getJSON(url, function(err, data)
    if err then
      return callback(err)
    end
    printf("[animation::loadById] data:")
    dump(data)
    local textureIds = (data["texture"] or EMPTY_TABLE)[TEXT_FIELD_ID]
    if not (type(textureIds) == table and #textureIds > 0) then
      return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXT_FIELD_ID))
    end
    return callback(nil)
  end)
end
return animation
