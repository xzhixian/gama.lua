local async = require("async")
local _ = require("underscore")
print("[gama] init")
local spriteFrameCache = cc.SpriteFrameCache:getInstance()
local TextureCache = cc.TextureCache:getInstance()
local fs = cc.FileUtils:getInstance()
fs:addSearchPath("gama/")
local ASSET_ID_TO_TYPE_KV = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local TEXTURE_FIELD_ID = "png_8bit"
local SPF = 0.3 / 8
gama = gama or { }
gama.VERSION = "0.1.0"
gama.getAssetPath = function(id)
  return "assets/" .. tostring(id)
end
gama.readJSON = function(id)
  local path = gama.getAssetPath(id)
  if not (fs:isFileExist(path)) then
    return nil
  end
  local content = fs:getStringFromFile(path)
  return json.decode(content)
end
gama.getTypeById = function(id)
  local type = ASSET_ID_TO_TYPE_KV[id]
  if type then
    return type
  end
  local obj = gama.readJSON(id)
  if not (obj) then
    return nil
  end
  return obj["type"]
end
gama.asset = {
  getTextureById = function(id, callback)
    print("[asset::getTextureById] id:" .. tostring(id))
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    local pathToFile = gama.getAssetPath(id)
    print("[asset::getTextureById] pathToFile:" .. tostring(pathToFile))
    local texture = TextureCache:getTextureForKey(pathToFile)
    if texture then
      print("[asset::getTextureById] texture avilable for id:" .. tostring(id) .. tostring(extname))
      return callback(nil, texture)
    end
    if not (fs:isFileExist(pathToFile)) then
      return callback("missing file at:" .. tostring(pathToFile))
    end
    texture = TextureCache:addImage(pathToFile)
    print("[asset::getTextureById] texture:" .. tostring(texture))
    return callback(nil, texture)
  end
}
gama.animation = {
  getById = function(id, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    local data = gama.readJSON(id)
    if not (data) then
      return callback("fail to parse json data from id:" .. tostring(id))
    end
    local textureIds = (data.texture or EMPTY_TABLE)[TEXTURE_FIELD_ID]
    if type(textureIds) == "string" then
      textureIds = {
        textureIds
      }
    end
    if not (type(textureIds) == "table" and #textureIds > 0) then
      return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXTURE_FIELD_ID))
    end
    local processTexture
    processTexture = function(textureId, next)
      return gama.asset.getTextureById(textureId, function(err, texture2D)
        if err then
          return next(err)
        end
        print("[animation::loadById] texture2D:" .. tostring(texture2D))
        return next(nil, texture2D)
      end)
    end
    async.mapSeries(textureIds, processTexture, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local frames = gama.animation.makeSpriteFrames(id, texture2Ds, data.atlas, data.playback)
      local animation = display.newAnimation(frames, SPF)
      return callback(nil, {
        animation,
        data,
        texture2Ds
      })
    end)
  end,
  makeSpriteFrames = function(assetId, textures, arrangement, playscript)
    local count = 1
    local assetFrames = _.map(arrangement, function(frameInfo)
      local frameName = tostring(assetId) .. "/" .. tostring(count)
      count = count + 1
      print("[animation::buildSpriteFrameCache] frameName:" .. tostring(frameName))
      local frame = sharedSpriteFrameCache:spriteFrameByName(frameName)
      if frame then
        print("[animation::buildSpriteFrameCache] find frame in cache")
        return frame
      else
        print("[animation::buildSpriteFrameCache] build up from json frameInfo:")
        local texture = textures[frameInfo.texture + 1]
        print("[animation::buildSpriteFrameCache] texture:" .. tostring(texture))
        frame = CCSpriteFrame:createWithTexture(texture, CCRect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h))
        sharedSpriteFrameCache:addSpriteFrame(frame, frameName)
        return frame
      end
    end)
    return assetFrames
  end
}
