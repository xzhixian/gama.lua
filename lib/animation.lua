local async = require("async")
local animation = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local EXTNAME = ".png"
local TEXT_FIELD_ID = "png8"
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
      if not (type(textureIds) == "table" and #textureIds > 0) then
        return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXT_FIELD_ID))
      end
      local processTexture
      processTexture = function(textureId, next)
        return gama.asset.fetchById(textureId, EXTNAME, function(err, filepath)
          if err then
            return next(err)
          end
          printf("[animation::loadById] filepath:" .. tostring(filepath))
          display.addImageAsync(filepath, function(funcname, texture)
            printf("[animation::processTexture] texture init:" .. tostring(texture))
          end)
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
