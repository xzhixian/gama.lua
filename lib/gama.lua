local async = require("async")
local cjson = require("cjson")
print("[gama] init")
local SpriteFrameCache = cc.SpriteFrameCache:getInstance()
local TextureCache = cc.Director:getInstance():getTextureCache()
local AnimationCache = cc.AnimationCache:getInstance()
local fs = cc.FileUtils:getInstance()
fs:addSearchPath("gama/")
local fromhex
fromhex = function(str)
  local result = { }
  local n = #str
  for i = 1, n, 8 do
    local cc = str:sub(i, i + 7)
    table.insert(result, tonumber(cc, 16))
  end
  return result
end
local WIN_SIZE = cc.Director:getInstance():getWinSize()
local WINDOW_HEIGTH = WIN_SIZE.height
local WINDOW_WIDTH = WIN_SIZE.width
local HALF_WINDOW_HEIGTH = WINDOW_HEIGTH / 2
local HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2
local EVENT_START = "start"
local EVENT_PROGRESS = "progress"
local EVENT_WARNING = "warning"
local EVENT_COMPLETE = "complete"
local EVENT_FAILED = "failed"
local ASSET_TYPE_CHARACTER = 10
local ASSET_TYPE_TILEMAP = 20
local ASSET_TYPE_ANIMATION = 30
local ASSET_ID_TO_TYPE_KV = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local TEXTURE_FIELD_ID_1 = "png_8bit"
local TEXTURE_FIELD_ID_2 = "jpg"
local SPF = 1 / 15
local TILE_TEXTURE_RECTS = {
  [1] = cc.rect(0, 0, 256, 256),
  [2] = cc.rect(256, 0, 256, 256),
  [3] = cc.rect(512, 0, 256, 256),
  [4] = cc.rect(768, 0, 256, 256),
  [5] = cc.rect(0, 256, 256, 256),
  [6] = cc.rect(256, 256, 256, 256),
  [7] = cc.rect(512, 256, 256, 256),
  [8] = cc.rect(768, 256, 256, 256),
  [9] = cc.rect(0, 512, 256, 256),
  [10] = cc.rect(256, 512, 256, 256),
  [11] = cc.rect(512, 512, 256, 256),
  [12] = cc.rect(768, 512, 256, 256),
  [13] = cc.rect(0, 768, 256, 256),
  [14] = cc.rect(256, 768, 256, 256),
  [15] = cc.rect(512, 768, 256, 256),
  [16] = cc.rect(768, 768, 256, 256)
}
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
    addOrnament = function(self, gamaAnimation, x, y, flipX)
      if not (self.container) then
        print("[GamaTilemap::addOrnament] invalide container")
        return 
      end
      if not (gamaAnimation) then
        print("[GamaTilemap::addOrnament] invalide gama animation")
        return 
      end
      local yOffset = WINDOW_HEIGTH
      local xOffset = -self.pixelTileSize / 2
      local sprite = cc.Sprite:create()
      sprite:setAnchorPoint(0.5, 0.5)
      sprite:setFlippedX(not not flipX)
      sprite:setPosition(tonumber(x) + xOffset, yOffset - tonumber(y))
      self.container:addChild(sprite)
      gamaAnimation:playOnSprite(sprite)
    end,
    moveBy = function(self, xdiff, ydiff)
      return self:setCenterPosition(self.centerX - xdiff, self.centerY + ydiff)
    end,
    setCenterPosition = function(self, x, y)
      if x < self.minCenterX then
        x = self.minCenterX
      end
      if x > self.maxCenterX then
        x = self.maxCenterX
      end
      if y < self.minCenterY then
        y = self.minCenterY
      end
      if y > self.maxCenterY then
        y = self.maxCenterY
      end
      if x == self.centerX and y == self.centerY then
        return x, y
      end
      self.centerX = x
      self.centerY = y
      self:updateContainerPosition()
      return x, y
    end,
    updateContainerPosition = function(self)
      if self.container then
        return self.container:setPosition(HALF_WINDOW_WIDTH - self.centerX + (self.pixelTileSize / 2), self.centerY - HALF_WINDOW_HEIGTH)
      end
    end,
    uiCordToVertexCord = function(self, x, y)
      return x - self.halfPixelTileSize, y + WINDOW_HEIGTH
    end,
    getContainerPoisition = function(self)
      return self.container / getPosition()
    end,
    bindToSprite = function(self, sprite)
      assert(sprite and type(sprite.addChild) == "function", "invalid sprite")
      sprite:setAnchorPoint(0, 0)
      self.container = cc.Sprite:create()
      self.container:setAnchorPoint(0.5, 0.5)
      self.container:setPosition(0, 0)
      sprite:addChild(self.container)
      local yOffset = WINDOW_HEIGTH - (self.pixelTileSize / 2)
      for tileId = 1, self.tileCount do
        local textureId = math.ceil(tileId / self.numOfTilePerTexture)
        local texture = self.texture2Ds[textureId]
        sprite = cc.Sprite:createWithTexture(texture)
        local x = (tileId - 1) % self.tileWidth * self.pixelTileSize
        local y = yOffset - (math.floor((tileId - 1) / self.tileWidth) * self.pixelTileSize)
        sprite:setAnchorPoint(0.5, 0.5)
        local tileIdInTexture = tileId - self.numOfTilePerTexture * (textureId - 1)
        sprite:setTextureRect(TILE_TEXTURE_RECTS[tileIdInTexture])
        sprite:setPosition(x, y)
        self.container:addChild(sprite)
        self:updateContainerPosition()
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
      self.halfPixelTileSize = pixelTileSize / 2
      self.tileWidth = math.ceil(pixelWidth / pixelTileSize)
      self.tileHeight = math.ceil(pixelHeight / pixelTileSize)
      self.tileCount = self.tileWidth * self.tileHeight
      self.numOfTilePerRow = PIXEL_TEXTURE_SIZE / pixelTileSize
      self.numOfTilePerTexture = self.numOfTilePerRow * self.numOfTilePerRow
      self.maxCenterX = self.pixelWidth - HALF_WINDOW_WIDTH
      self.minCenterX = HALF_WINDOW_WIDTH
      self.minCenterY = HALF_WINDOW_HEIGTH
      self.maxCenterY = self.pixelHeight - HALF_WINDOW_HEIGTH
      self.centerX = 0
      self.centerY = 0
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
  readJSONAsync = function(id, callback)
    assert(id, "missing id")
    assert(type(callback) == "function", "invalid callback")
    local path = tostring(id) .. ".csx"
    if not (fs:isFileExist(path)) then
      return callback("file:" .. tostring(path) .. " not found")
    end
    local status, content = pcall(fs.getStringFromFile, fs, path)
    if not (status) then
      return callback("fail to read file:" .. tostring(path) .. ", error:" .. tostring(content))
    end
    status, content = pcall(cjson.decode, content)
    if not (status) then
      return callback("fail to decode json from:" .. tostring(path) .. ", error:" .. tostring(content))
    end
    return callback(nil, content)
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
gama.scene = {
  cleanup = function()
    SpriteFrameCache:removeUnusedSpriteFrames()
    TextureCache:removeUnusedTextures()
  end,
  loadById = function(id, callback)
    assert(id, "missing scene id")
    assert(type(callback) == "function", "invalid callback")
    print("[gama::scene::loadById] id:" .. tostring(id))
    return gama.readJSONAsync(id, function(err, sceneData)
      if err then
        return callback(err)
      end
      return gama.scene.loadByCSX(sceneData, callback)
    end)
  end,
  loadByCSX = function(sceneData, callback)
    assert(sceneData and sceneData.type == "scenes", "invalid data type")
    assert(type(callback) == "function", "invalid callback")
    print("[gama::scene::loadByCSX]")
    local jobs = { }
    local pushedIds = { }
    sceneData.binaryBlock = fromhex(sceneData.mask_binary[1])
    sceneData.binaryMask = fromhex(sceneData.mask_binary[2])
    sceneData.isWalkableAt = function(self, brickX, brickY)
      local brickN = (brickY * self.brickWidth) + brickX
      local bytePos = math.floor(brickN / 32) + 1
      local byte = sceneData.binaryBlock[bytePos]
      local bitValue = bit.rshift(byte, brickN % 32)
      return (bitValue % 2) == 1
    end
    sceneData.isMaskedAt = function(self, brickX, brickY)
      local brickN = (brickY * self.brickWidth) + brickX
      local bytePos = math.floor(brickN / 32) + 1
      local byte = sceneData.binaryMask[bytePos]
      local bitValue = bit.rshift(byte, brickN % 32)
      return (bitValue % 2) == 0
    end
    table.insert(jobs, {
      sceneData.map_id,
      ASSET_TYPE_TILEMAP
    })
    rawset(pushedIds, sceneData.map_id, true)
    if type(sceneData.ornaments) == "table" then
      local _list_0 = sceneData.ornaments
      for _index_0 = 1, #_list_0 do
        local item = _list_0[_index_0]
        local assetId = item.id
        if assetId and pushedIds[assetId] == nil then
          table.insert(jobs, {
            assetId,
            ASSET_TYPE_ANIMATION
          })
          rawset(pushedIds, assetId, true)
        end
      end
    end
    local processor
    processor = function(job, next)
      local asserId, jobType = unpack(job)
      local _exp_0 = jobType
      if ASSET_TYPE_CHARACTER == _exp_0 then
        gama.character.getById(asserId, next)
      elseif ASSET_TYPE_TILEMAP == _exp_0 then
        gama.tilemap.getById(asserId, next)
      elseif ASSET_TYPE_ANIMATION == _exp_0 then
        gama.animation.getById(asserId, function(err, gamaAnimation)
          if err then
            console.warn("[gama::scene::load animation] skip invalid animation:" .. tostring(assetId) .. ", error:" .. tostring(err))
            err = nil
          end
          return next(err, gamaAnimation)
        end)
      else
        console.error("[gama::scene::loadById::on job] unknown asset type:" .. tostring(jobType))
      end
    end
    async.mapSeries(jobs, processor, function(err, results)
      if err then
        return callback(err)
      end
      local gamaTilemap = results[1]
      table.insert(results, 1, sceneData)
      for _index_0 = 1, #results do
        local piece = results[_index_0]
        local id = piece.id
        if id then
          results[tostring(id)] = piece
        end
      end
      sceneData.pixelWidth = gamaTilemap.pixelWidth
      sceneData.pixelHeight = gamaTilemap.pixelHeight
      sceneData.brickUnitWidth = sceneData.brick_width
      sceneData.brickUnitHeight = sceneData.brick_height
      sceneData.brickWidth = math.floor(gamaTilemap.pixelWidth / sceneData.brick_width)
      sceneData.brickHeight = math.floor(gamaTilemap.pixelHeight / sceneData.brick_height)
      return callback(nil, results)
    end)
  end
}
