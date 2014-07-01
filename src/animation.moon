--- 这个模块：
--  1. 是一个单例
--  2. 对应 gama 网站上的动画功能

async = require "async"

animation = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

EXTNAME = ".png"

TEXT_FIELD_ID = "png8"

-- TODO:
-- cocos2dx/addImageAsync doens't support etc or pvrct4,
-- only texture2D have sync method: initWithETCFile, initWithPVRCTFile
-- so need a custom patch on addImageAsync

--TEXT_FIELD_ID = switch device.platform
  --when "android"
    --"pkm"
  --when "ios"
    --"pvrct4"
  --else
    --"png8"

--- loadById
-- 根据给定的 id 载入动画
-- @param id asset id
-- @param callback, callback method, signature: callback(err, animation)
animation.loadById = (id, callback)->

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  -- read the asset config json
  gama.asset.readById id, (err, text)->
    return callback err if err

    JSON.parse text, (err, data)->

      -- work out required texture ids
      textureIds = (data["texture"] or EMPTY_TABLE)[TEXT_FIELD_ID]

      unless type(textureIds) == "table" and #textureIds > 0
        return callback "invalid textureIds:#{textureIds}, field:#{TEXT_FIELD_ID}"

      -- fetch texture assets
      processTexture = (textureId, next)->
        gama.asset.fetchById textureId, EXTNAME, (err, filepath)->
          return next err if err
          printf "[animation::loadById] filepath:#{filepath}"
          display.addImageAsync filepath, (funcname, texture)->
            printf "[animation::processTexture] texture init:#{texture}"
            return
          return next!

      async.eachSeries textureIds, processTexture, (err)->
        return callback err if err
        return callback!

      return
    return
  return

return animation


