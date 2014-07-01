--- 这个模块：
--  1. 是一个单例
--  2. 对应 gama 网站上的动画功能

async = require "async"

animation = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXT_FIELD_ID = switch device.platform
  when "android"
    "pkm"
  when "ios"
    "pvrct4"
  else
    "png8"

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

  gama.asset.readById id, (err, text)->
    return callback err if err

    JSON.parse text, (err, data)->

      -- work out required texture ids
      textureIds = (data["texture"] or EMPTY_TABLE)[TEXT_FIELD_ID]

      printf "[animation::loadById] textureIds"
      dump textureIds

      unless type(textureIds) == "table" and #textureIds > 0
        return callback "invalid textureIds:#{textureIds}, field:#{TEXT_FIELD_ID}"

      -- fetch texture assets
      processTexture = (textureId, next)->
        gama.asset.fetchById textureId, (err, id)->
          return next err if err
          filepath = gama.asset.getPathToFileById id
          printf "[animation::loadById] filepath:#{filepath}"
          display.addImageAsync filepath, ->
          return next!

      async.eachSeries textureIds, processTexture, (err)->
        return callback err if err
        return callback!

      return
    return
  return

return animation


