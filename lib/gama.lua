local async = require("async")
print("[gama] init")
local SpriteFrameCache = cc.SpriteFrameCache:getInstance()
local TextureCache = cc.Director:getInstance():getTextureCache()
local AnimationCache = cc.AnimationCache:getInstance()
local fs = cc.FileUtils:getInstance()
fs:addSearchPath("gama/")
local ASSET_ID_TO_TYPE_KV = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local TEXTURE_FIELD_ID = "png_8bit"
local SPF = 1 / 15
local GamaAnimation
do
  local _base_0 = {
    playOnSprite = function(self, sprite)
      local animate = cc.Animate:create(self.ccAnimation)
      local action = cc.RepeatForever:create(animate)
      sprite:runAction(action)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, texture, ccAnimation)
      self.texture = texture
      self.ccAnimation = ccAnimation
    end,
    __base = _base_0,
    __name = "GamaAnimation"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GamaAnimation = _class_0
end
gama = {
  VERSION = "0.1.0",
  getAssetPath = function(id)
    return "assets/" .. tostring(id)
  end,
  readJSON = function(id)
    local path = "assets/" .. tostring(id) .. ".csx"
    print("[gama::readJSON] path:" .. tostring(path))
    if not (fs:isFileExist(path)) then
      print("[gama::readJSON] file not found:" .. tostring(path))
      return nil
    end
    local content = fs:getStringFromFile(path)
    return json.decode(content)
  end,
  getTypeById = function(id)
    local type = ASSET_ID_TO_TYPE_KV[id]
    if type then
      return type
    end
    local obj = gama.readJSON(id)
    if not (obj) then
      return nil
    end
    type = obj["type"]
    ASSET_ID_TO_TYPE_KV[id] = type
    print("[gama::getTypeById] type:" .. tostring(type))
    return type
  end
}
gama.texture2D = {
  getById = function(id, callback)
    print("[gama::Texture2D::getById] id:" .. tostring(id))
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    local pathToFile = gama.getAssetPath(id)
    local texture = TextureCache:getTextureForKey(pathToFile)
    if texture then
      print("[gama::Texture2D::getById] texture avilable for id:" .. tostring(id) .. tostring(extname))
      return callback(nil, texture)
    end
    if not (fs:isFileExist(pathToFile)) then
      return callback("missing file at:" .. tostring(pathToFile))
    end
    texture = TextureCache:addImage(pathToFile)
    return callback(nil, texture)
  end,
  getFromJSON = function(data, callback)
    local textureIds = (data.texture or EMPTY_TABLE)[TEXTURE_FIELD_ID]
    if type(textureIds) == "string" then
      textureIds = {
        textureIds
      }
    end
    if not (type(textureIds) == "table" and #textureIds > 0) then
      return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXTURE_FIELD_ID))
    end
    async.mapSeries(textureIds, gama.texture2D.getById, callback)
  end
}
gama.animation = {
  getById = function(id, callback)
    print("[gama::animation::getById] id:" .. tostring(id))
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    local data = gama.readJSON(id)
    if not (data) then
      return callback("fail to parse json data from id:" .. tostring(id))
    end
    gama.texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local animation = AnimationCache:getAnimation(id)
      if not (animation) then
        local assetFrames = gama.animation.makeSpriteFrames(id, texture2Ds[1], data.atlas)
        local playframes = { }
        local _list_0 = data.playframes
        for _index_0 = 1, #_list_0 do
          local assetId = _list_0[_index_0]
          table.insert(playframes, (assetFrames[assetId + 1] or assetFrames[1]))
        end
        animation = cc.Animation:createWithSpriteFrames(playframes, SPF)
        AnimationCache:addAnimation(animation, id)
      end
      local gamaAnimation = GamaAnimation(texture2Ds[1], animation)
      return callback(nil, gamaAnimation)
    end)
  end,
  makeSpriteFrames = function(assetId, texture, arrangement)
    local count = 1
    local assetFrames = { }
    for _index_0 = 1, #arrangement do
      local frameInfo = arrangement[_index_0]
      local frameName = tostring(assetId) .. "/" .. tostring(count)
      count = count + 1
      local frame = SpriteFrameCache:getSpriteFrame(frameName)
      if frame then
        table.insert(assetFrames, frame)
      else
        local rect = cc.rect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h)
        frame = cc.SpriteFrame:createWithTexture(texture, rect)
        frame:setOriginalSizeInPixels(cc.size(512, 512))
        frame:setOffset(cc.p(frameInfo.ox, frameInfo.oy))
        SpriteFrameCache:addSpriteFrame(frame, frameName)
        table.insert(assetFrames, frame)
      end
    end
    return assetFrames
  end
}
gama.tilemap = {
  getById = function(id, callback)
    print("[gama::tilemap::getById] id:" .. tostring(id))
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    local data = gama.readJSON(id)
    if not (data) then
      return callback("fail to parse json data from id:" .. tostring(id))
    end
    gama.texture2D.getFromJSON(data, function(err, texture2Ds) end)
  end
}
