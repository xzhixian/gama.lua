--- 这个模块：
--  1. 是一个单例
--  2. 对应 gama 网站上的动画功能

async = require "async"

_ = require "underscore"

sharedSpriteFrameCache = CCSpriteFrameCache\sharedSpriteFrameCache!

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

        gama.asset.getTextureById textureId, EXTNAME, (err, texture2D)->
          return next err if err
          printf "[animation::loadById] texture2D:#{texture2D}"
          return next(nil, texture2D)

      async.mapSeries textureIds, processTexture, (err, textures)->
        return callback err if err

        printf "[animation::loadById] after texture processed, textures:"
        dump textures

        frames = animation.makeSpriteFrames(id, textures, data["arrangment"])

        printf "[animation::loadById] after texture processed, frames:"
        dump frames

        animation = display.newAnimation(frames, 0.3 / 8)

        callback nil, animation
      return
    return
  return

animation.makeSpriteFrames = (assetId, textures, arrangement)->

  count = 1
  return _.map arrangement, (frameInfo)->

    frameName = "#{assetId}/#{count}"

    printf "[animation::buildSpriteFrameCache] frameName:#{frameName}"

    --frame = sharedSpriteFrameCache/spriteFrameByName(frameName)
    frame = sharedSpriteFrameCache\spriteFrameByName(frameName)

    if frame
      printf "[animation::buildSpriteFrameCache] find frame in cache"
      return frame

    else

      printf "[animation::buildSpriteFrameCache] build up from json frameInfo:"
      dump frameInfo

      -- NOTE: frameInfo.texture is 0-based
      texture = textures[frameInfo.texture + 1]

      printf "[animation::buildSpriteFrameCache] texture:#{texture}"
      frame = CCSpriteFrame\createWithTexture(texture, CCRect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h))

      -- push the frame into cache
      sharedSpriteFrameCache\addSpriteFrame frame, frameName

      return frame

return animation


