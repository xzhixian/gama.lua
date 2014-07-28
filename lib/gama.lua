local async = require("async")
local cjson = require("cjson")
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
local TEXTURE_FIELD_ID_1 = "png_8bit"
local TEXTURE_FIELD_ID_2 = "jpg"
local SPF = 1 / 15
local DIRECTION_TO_FLIPX = {
  n = false,
  ne = false,
  e = false,
  se = false,
  s = false,
  sw = true,
  w = true,
  nw = true
}
local GamaAnimation
do
  local _base_0 = {
    playOnSprite = function(self, sprite)
      assert(sprite, "invalid sprite")
      sprite:cleanup()
      local animate = cc.Animate:create(self.ccAnimation)
      local action = cc.RepeatForever:create(animate)
      sprite:runAction(action)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, ccAnimation)
      assert(id, "missing animation id")
      assert(ccAnimation, "missing ccAnimation")
      self.id = id
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
local GamaFigure
do
  local _base_0 = {
    getId = function(self)
      return self.id
    end,
    setDefaultMotion = function(self, value)
      self.defaultMotion = value
    end,
    setDefaultDirection = function(self, value)
      self.defaultDirection = value
    end,
    getMotions = function(self)
      return self.motions
    end,
    playOnSprite = function(self, sprite, motionName, direction)
      print("[GamaFigure::playOnSprite] sprite:" .. tostring(sprite) .. ", motionName:" .. tostring(motionName) .. ", direction:" .. tostring(direction))
      assert(sprite, "invalid sprite")
      local animationName = tostring(self.id) .. "/" .. tostring(motionName) .. "/" .. tostring(direction or self.defaultDirection)
      local animation = AnimationCache:getAnimation(animationName)
      if not (animation) then
        print("[GamaFigure(" .. tostring(playOnSprite) .. ")::playOnSprite] missing animation for motionName:" .. tostring(motionName) .. ", direction:" .. tostring(direction) .. ", use defaults")
        animation = AnimationCache:getAnimation(tostring(self.id) .. "/" .. tostring(self.defaultMotion) .. "/" .. tostring(self.defaultDirection))
        if not (animation) then
          print("[GamaFigure(" .. tostring(playOnSprite) .. ")::playOnSprite] no default animation")
          return 
        end
      end
      sprite:cleanup()
      local animate = cc.Animate:create(animation)
      local action = cc.RepeatForever:create(animate)
      sprite:runAction(action)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, data, defaultMotion, defaultDirection)
      assert(id, "missing figure id")
      assert(data, "missing figure data")
      self.id = id
      self.data = data
      self.defaultMotion = defaultMotion
      self.defaultDirection = defaultDirection
      self.motions = { }
      for motionName in pairs(data) do
        table.insert(self.motions, motionName)
      end
    end,
    __base = _base_0,
    __name = "GamaFigure"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GamaFigure = _class_0
end
local GamaCharacter
do
  local _base_0 = {
    getId = function(self)
      return self.id
    end,
    getCurDirection = function(self)
      return self.curDirection
    end,
    getCurMotion = function(self)
      return self.getCurMotion
    end,
    applyChange = function(self)
      self.sprite:setFlippedX(DIRECTION_TO_FLIPX[self.curDirection])
      return self.figure:playOnSprite(self.sprite, self.curMotion, self.curDirection)
    end,
    setDirection = function(self, value)
      if self.curDirection == value then
        return 
      end
      self.curDirection = value
      self:applyChange()
    end,
    setMotion = function(self, value)
      if self.curMotion == value then
        return 
      end
      self.curMotion = value
      self:applyChange()
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, gamaFigure, sprite)
      self.id = id
      self.figure = gamaFigure
      self.motions = gamaFigure.getMotions
      self.sprite = sprite
      self.curDirection = "s"
      self.curMotion = "idl"
      return self:applyChange()
    end,
    __base = _base_0,
    __name = "GamaCharacter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GamaCharacter = _class_0
end
local GamaTilemap
do
  local _base_0 = {
    bindToSprite = function(self, sprite)
      assert(sprite, "invalid sprite")
      sprite:cleanup()
      self.container = sprite
      self.container:setAnchorPoint(0, 1)
      for tileId = 1, self.tileCount do
        local textureId = math.ceil(tileId / self.numOfTilePerTexture)
        local texture = self.texture2Ds[textureId]
        sprite = cc.Sprite:createWithTexture(texture)
        local x = (tileId - 1) % self.tileWidth * self.pixelTileSize
        local y = -(math.floor(tileId / self.tileWidth) * self.pixelTileSize)
        sprite:setAnchorPoint(0, 1)
        console.log("[GamaTilemap::bindToSprite] tileId:" .. tostring(tileId) .. ", x:" .. tostring(x) .. ", y:" .. tostring(y))
        local tileIdInTexture = tileId % self.numOfTilePerTexture
        local rectX = tileIdInTexture % self.numOfTilePerRow * self.pixelTileSize
        local rectY = math.floor(tileIdInTexture / self.numOfTilePerRow) * self.pixelTileSize
        sprite:setTextureRect(cc.rect(rectX, rectY, self.pixelTileSize, self.pixelTileSize))
        sprite:setPosition(x, y)
        self.container:addChild(sprite)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, texture2Ds, pixelWidth, pixelHeight, pixelTileSize)
      pixelWidth = tonumber(pixelWidth) or 0
      pixelHeight = tonumber(pixelHeight) or 0
      pixelTileSize = tonumber(pixelTileSize) or 0
      assert(pixelWidth > 0, "invalid pixelWidth:" .. tostring(pixelWidth))
      assert(pixelHeight > 0, "invalid pixelWidth:" .. tostring(pixelHeight))
      assert(pixelTileSize > 0, "invalid pixelWidth:" .. tostring(pixelTileSize))
      local PIXEL_TEXTURE_SIZE = 1024
      self.id = id
      self.texture2Ds = texture2Ds
      self.pixelWidth = pixelWidth
      self.pixelHeight = pixelHeight
      self.pixelTileSize = pixelTileSize
      self.tileWidth = math.ceil(pixelWidth / pixelTileSize)
      self.tileHeight = math.ceil(pixelHeight / pixelTileSize)
      self.tileCount = self.tileWidth * self.tileHeight
      self.numOfTilePerRow = PIXEL_TEXTURE_SIZE / pixelTileSize
      self.numOfTilePerTexture = self.numOfTilePerRow * self.numOfTilePerRow
      local winSize = cc.Director:getInstance():getWinSize()
      self.windowHeigth = winSize.height
      self.windowWidth = winSize.width
    end,
    __base = _base_0,
    __name = "GamaTilemap"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GamaTilemap = _class_0
end
gama = {
  VERSION = "0.1.0",
  getAssetPath = function(id)
    return tostring(id)
  end,
  readJSON = function(id)
    local path = tostring(id) .. ".csx"
    print("[gama::readJSON] path:" .. tostring(path))
    if not (fs:isFileExist(path)) then
      print("[gama::readJSON] file not found:" .. tostring(path))
      return nil
    end
    local content = fs:getStringFromFile(path)
    return cjson.decode(content)
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
  end,
  createCharacterWithSprite = function(id, gamaFigure, sprite)
    assert(id)
    assert(gamaFigure)
    assert(sprite)
    return GamaCharacter(id, gamaFigure, sprite)
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
    texture = TextureCache:addImageAsync(pathToFile, function(texture2D)
      if not (texture2D) then
        return callback("addImageAsync return nil")
      end
      return callback(nil, texture2D)
    end)
  end,
  getFromJSON = function(data, callback)
    if not (type(data.texture) == "table") then
      return callback("missing texture decleration")
    end
    local textureIds = data.texture[TEXTURE_FIELD_ID_1] or data.texture[TEXTURE_FIELD_ID_2]
    if type(textureIds) == "string" then
      textureIds = {
        textureIds
      }
    end
    if not (type(textureIds) == "table" and #textureIds > 0) then
      return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXTURE_FIELD_ID_1) .. " or " .. tostring(TEXTURE_FIELD_ID_2))
    end
    async.mapSeries(textureIds, gama.texture2D.getById, callback)
  end,
  makeSpriteFrames = function(assetId, texture, arrangement, assetFrames)
    assetFrames = assetFrames or { }
    for frameId, frameInfo in pairs(arrangement) do
      local frameName = tostring(assetId) .. "/" .. tostring(frameId)
      local frame = SpriteFrameCache:getSpriteFrame(frameName)
      if frame then
        assetFrames[frameName] = frame
      else
        local rect = cc.rect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h)
        frame = cc.SpriteFrame:createWithTexture(texture, rect)
        frame:setOriginalSizeInPixels(cc.size(512, 512))
        frame:setOffset(cc.p(frameInfo.ox, frameInfo.oy))
        SpriteFrameCache:addSpriteFrame(frame, frameName)
        assetFrames[frameName] = frame
      end
    end
    return assetFrames
  end
}
gama.animation = {
  getByCSX = function(data, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    if not (data and data.id) then
      return callback("invalid csx json data")
    end
    local id = data.id
    gama.texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local animation = AnimationCache:getAnimation(id)
      if not (animation) then
        local assetFrames = gama.texture2D.makeSpriteFrames(id, texture2Ds[1], data.atlas)
        local playframes = { }
        local defaultFrame = assetFrames[tostring(id) .. "/1"]
        local _list_0 = data.playframes
        for _index_0 = 1, #_list_0 do
          local assetId = _list_0[_index_0]
          table.insert(playframes, (assetFrames[tostring(id) .. "/" .. tostring(assetId + 1)] or defaultFrame))
        end
        animation = cc.Animation:createWithSpriteFrames(playframes, SPF)
        AnimationCache:addAnimation(animation, id)
      end
      local gamaAnimation = GamaAnimation(id, animation)
      return callback(nil, gamaAnimation)
    end)
  end,
  getById = function(id, callback)
    print("[gama::animation::getById] id:" .. tostring(id))
    gama.animation.getByCSX(gama.readJSON(id), callback)
  end
}
gama.figure = {
  getById = function(id, callback)
    print("[gama::tilemap::getById] id:" .. tostring(id))
    gama.figure.getByCSX(gama.readJSON(id), callback)
  end,
  getByCSX = function(data, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    if not (data and data.id) then
      return callback("invalid csx json data")
    end
    local id = data.id
    gama.texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local assetFrames = { }
      for i, texture in ipairs(texture2Ds) do
        local arrangement = data.atlas[i].arrangment
        gama.texture2D.makeSpriteFrames(id, texture, arrangement, assetFrames)
      end
      for motionName, directionSet in pairs(data.playframes) do
        for direction, assetFrameIds in pairs(directionSet) do
          local animationName = tostring(id) .. "/" .. tostring(motionName) .. "/" .. tostring(direction)
          local animation = AnimationCache:getAnimation(animationName)
          if animation then
            directionSet[direction] = animation
          else
            local playframes = { }
            for _index_0 = 1, #assetFrameIds do
              local assetId = assetFrameIds[_index_0]
              local assetFrame = assetFrames[tostring(id) .. "/" .. tostring(assetId)]
              if assetFrame then
                table.insert(playframes, assetFrame)
              end
            end
            animation = cc.Animation:createWithSpriteFrames(playframes, SPF)
            AnimationCache:addAnimation(animation, animationName)
            directionSet[direction] = animation
          end
        end
      end
      local instance = GamaFigure(id, data.playframes)
      return callback(nil, instance)
    end)
  end
}
gama.tilemap = {
  getById = function(id, callback)
    print("[gama::tilemap::getById] id:" .. tostring(id))
    gama.tilemap.getByCSX(gama.readJSON(id), callback)
  end,
  getByCSX = function(data, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    if not (data and data.id) then
      return callback("invalid csx json data")
    end
    local id = data.id
    gama.texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local gamaTilemap = GamaTilemap(id, texture2Ds, data.source_width, data.source_height, data.tile_size)
      return callback(nil, gamaTilemap)
    end)
  end
}
