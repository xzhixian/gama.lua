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
  gama.asset.readById(id, function(err, text)
    if err then
      return callback(err)
    end
    JSON.parse(text, function(err, data)
      local textureIds = (data["texture"] or EMPTY_TABLE)[TEXT_FIELD_ID]
      printf("[animation::loadById] textureIds")
      dump(textureIds)
      if not (type(textureIds) == "table" and #textureIds > 0) then
        return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXT_FIELD_ID))
      end
      local processTexture
      processTexture = function(textureId, next)
        return gama.asset.fetchById(textureId, function(err, id)
          if err then
            return next(err)
          end
          local filepath = gama.asset.getPathToFileById(id)
          printf("[animation::loadById] filepath:" .. tostring(filepath))
          display.addImageAsync(filepath, function() end)
          return next()
        end)
      end
      async.eachSeries(textureIds, processTexture, function(err)
        if err then
          return callback(err)
        end
        return callback()
      end)
    end)
  end)
end
return animation
