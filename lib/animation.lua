local async = require("async")
local _ = require("underscore")
local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()
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
        return gama.asset.getTextureById(textureId, EXTNAME, function(err, texture2D)
          if err then
            return next(err)
          end
          printf("[animation::loadById] texture2D:" .. tostring(texture2D))
          return next(nil, texture2D)
        end)
      end
      async.mapSeries(textureIds, processTexture, function(err, textures)
        if err then
          return callback(err)
        end
        printf("[animation::loadById] after texture processed, textures:")
        dump(textures)
        local frames = animation.makeSpriteFrames(id, textures, data["arrangment"])
        printf("[animation::loadById] after texture processed, frames:")
        dump(frames)
        animation = display.newAnimation(frames, 0.3 / 8)
        return callback(nil, animation)
      end)
    end)
  end)
end
animation.makeSpriteFrames = function(assetId, textures, arrangement)
  local count = 1
  return _.map(arrangement, function(frameInfo)
    local frameName = tostring(assetId) .. "/" .. tostring(count)
    count = count + 1
    printf("[animation::buildSpriteFrameCache] frameName:" .. tostring(frameName))
    local frame = sharedSpriteFrameCache:spriteFrameByName(frameName)
    if frame then
      printf("[animation::buildSpriteFrameCache] find frame in cache")
      return frame
    else
      printf("[animation::buildSpriteFrameCache] build up from json frameInfo:")
      local texture = textures[frameInfo.texture + 1]
      printf("[animation::buildSpriteFrameCache] texture:" .. tostring(texture))
      frame = CCSpriteFrame:createWithTexture(texture, CCRect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h))
      sharedSpriteFrameCache:addSpriteFrame(frame, frameName)
      return frame
    end
  end)
end
return animation
