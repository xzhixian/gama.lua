local async = require("async")
local cjson = require("cjson")
local AudioEngine = require("AudioEngine")
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
local TYPE_ANIMATION = "animations"
local TYPE_FIGURE = "figures"
local TYPE_TILEMAP = "tilemaps"
local TYPE_SCENE = "scenes"
local TYPE_ICONPACK = "iconpacks"
local ASSET_TYPE_CHARACTER = 10
local ASSET_TYPE_TILEMAP = 20
local ASSET_TYPE_ANIMATION = 30
local ASSET_ID_TO_TYPE_KV = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local TEXTURE_FIELD_ID_1 = "png_8bit"
local TEXTURE_FIELD_ID_2 = "jpg"
local TAG_PLAYFRAME_ACTION = 65535
local TAG_SOUND_FX_ACTION = 65534
local SPF = 1 / 20
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
local LOADED_SOUND_EFFECT_FILES = { }
local playSoundFx
playSoundFx = function(id)
  local filename = tostring(id) .. ".mp3"
  LOADED_SOUND_EFFECT_FILES[filename] = true
  AudioEngine.playEffect(filename)
end
local soundFX2Action
soundFX2Action = function(soundFx)
  if not (type(soundFx) == "table" and #soundFx > 1) then
    return nil
  end
  if #soundFx == 2 and soundFx[1] == 0 then
    return playSoundFx(soundFx[2])
  end
  local sequence = { }
  local soundFxIds = { }
  for i = 1, #soundFx, 2 do
    table.insert(sequence, cc.DelayTime:create(soundFx[i]))
    table.insert(soundFxIds, soundFx[i + 1])
    table.insert(sequence, cc.CallFunc:create(function()
      return playSoundFx(table.remove(soundFxIds, 1))
    end))
  end
  return cc.Sequence:create(unpack(sequence))
end
local GamaAnimation
do
  local _base_0 = {
    __tostring = function(self)
      return "[GamaAnimation " .. tostring(self.id) .. "]"
    end,
    retain = function(self)
      return self.ccAnimation:retain()
    end,
    release = function(self)
      return self.ccAnimation:release()
    end,
    getDuration = function(self)
      return self.ccAnimation:getDuration()
    end,
    playOnSprite = function(self, sprite)
      if not (sprite and type(sprite.runAction) == "function") then
        return print("[GamaAnimation(" .. tostring(self.id) .. ")::playOnSprite] invalid sprit")
      end
      sprite:stopActionByTag(TAG_PLAYFRAME_ACTION)
      local animate = cc.Animate:create(self.ccAnimation)
      local action = cc.RepeatForever:create(animate)
      action:setTag(TAG_PLAYFRAME_ACTION)
      sprite:runAction(action)
    end,
    playOnSpriteWithInterval = function(self, sprite, interval, intervalVariance, callbackWhenEachEnd)
      if intervalVariance == nil then
        intervalVariance = 0
      end
      if not (type(interval) == "number" and interval > 0) then
        return playOnceOnSprite(sprite)
      end
      sprite:stopActionByTag(TAG_PLAYFRAME_ACTION)
      local delay
      if intervalVariance > 0 then
        delay = interval + math.random(intervalVariance)
      end
      local sequence = {
        cc.Animate:create(self.ccAnimation)
      }
      if type(callbackWhenEachEnd) == "function" then
        table.insert(sequence, cc.CallFunc:create(callbackWhenEachEnd))
      end
      table.insert(sequence, cc.ToggleVisibility:create())
      table.insert(sequence, cc.DelayTime:create(delay))
      table.insert(sequence, cc.ToggleVisibility:create())
      table.insert(sequence, cc.CallFunc:create(function()
        return self:playOnSpriteWithInterval(sprite, interval, intervalVariance, callbackWhenEachEnd)
      end))
      local action = cc.Sequence:create(sequence)
      action:setTag(TAG_PLAYFRAME_ACTION)
      sprite:runAction(action)
    end,
    playOnceOnSprite = function(self, sprite)
      sprite:stopActionByTag(TAG_PLAYFRAME_ACTION)
      local action = cc.Animate:create(self.ccAnimation)
      action:setTag(TAG_PLAYFRAME_ACTION)
      sprite:runAction(action)
      sprite:stopActionByTag(TAG_SOUND_FX_ACTION)
      if self.soundfxs then
        action = soundFX2Action(self.soundfxs)
        if action and action.setTag then
          action:setTag(TAG_SOUND_FX_ACTION)
          sprite:runAction(action)
        end
      end
    end,
    playOnceInContainer = function(self, container, flipX)
      if flipX == nil then
        flipX = false
      end
      assert(container and container.addChild)
      local node = cc.Sprite:create()
      node:setFlippedX(flipX)
      local action = cc.Animate:create(self.ccAnimation)
      action = cc.Sequence:create(action, cc.RemoveSelf:create())
      node:runAction(action)
      container:addChild(node)
      if self.soundfxs then
        action = soundFX2Action(self.soundfxs)
        if action and action.setTag then
          node:runAction(action)
        end
      end
    end,
    drawSingleFrame = function(self, frameId)
      local aniFrames = self.ccAnimation:getFrames()
      if frameId > #aniFrames then
        print("[gama::drawSingleFrame] ERROR: frameId:" .. tostring(frameId) .. " overflow. total frame count:" .. tostring(#aniFrames))
        return nil
      end
      local spriteFrame = aniFrames[frameId]:getSpriteFrame()
      return cc.Sprite:createWithSpriteFrame(spriteFrame)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, ccAnimation, soundfxs)
      self.id, self.ccAnimation, self.soundfxs = id, ccAnimation, soundfxs
      local duration = #self.ccAnimation:getFrames() / 24
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
    __tostring = function(self)
      return "[GamaFigure " .. tostring(self.id) .. "]"
    end,
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
    isFlipped = function(self, motion, direction)
      if self.mirrors then
        return not not (self.mirrors[motion] or EMPTY_TABLE)[direction]
      else
        return DIRECTION_TO_FLIPX[direction]
      end
    end,
    getSoundFX = function(self, motionName, direction)
      if self.soundfxs == nil then
        return nil
      end
      if self.soundfxs[motionName] == nil then
        return nil
      end
      return self.soundfxs[motionName][direction]
    end,
    findAnimation = function(self, motionName, direction, fallbackToDefaultMotion)
      local animationName = tostring(self.id) .. "/" .. tostring(motionName) .. "/" .. tostring(direction)
      local animation = AnimationCache:getAnimation(animationName)
      if animation then
        return animation, self:isFlipped(motionName, direction), self:getSoundFX(motionName, direction)
      end
      animation = AnimationCache:getAnimation(tostring(self.id) .. "/" .. tostring(motionName) .. "/" .. tostring(self.defaultDirection))
      if animation then
        return animation, self:isFlipped(motionName, self.defaultDirection), self:getSoundFX(motionName, direction)
      end
      if not (fallbackToDefaultMotion) then
        return 
      end
      print("[GamaFigure(" .. tostring(self.id) .. ")::findAnimation] missing animation for motionName:" .. tostring(motionName) .. ", direction:" .. tostring(direction) .. ", use defaults")
      animation = AnimationCache:getAnimation(tostring(self.id) .. "/" .. tostring(self.defaultMotion) .. "/" .. tostring(self.defaultDirection))
      if animation then
        return animation, self:isFlipped(self.defaultMotion, self.defaultDirection), self:getSoundFX(motionName, direction)
      end
      print("[GamaFigure(" .. tostring(self.id) .. ")::findAnimation] no default animation")
      return nil, false, nil
    end,
    playOnceOnSprite = function(self, sprite, motionName, direction, callback)
      if not (sprite and type(sprite.getScene) == "function") then
        return print("[GamaFigure(" .. tostring(self.id) .. ")::playOnceOnSprite] invalid sprit")
      end
      local animation, isFlipped, soundFx = self:findAnimation(motionName, direction)
      if not (animation) then
        print("[GamaFigure(" .. tostring(self.id) .. ")::playOnceOnSprite] fail to find animation")
        return 
      end
      if table.getn(animation:getFrames()) == 0 then
        print("[GamaFigure(" .. tostring(self.id) .. ")::playOnceOnSprite] animation contain 0 frames")
        if type(callback) == "function" then
          callback()
        end
        return 
      end
      sprite:setFlippedX(isFlipped)
      sprite:stopActionByTag(TAG_PLAYFRAME_ACTION)
      local action = cc.Animate:create(animation)
      action:setTag(TAG_PLAYFRAME_ACTION)
      sprite:runAction(action)
      sprite:stopActionByTag(TAG_SOUND_FX_ACTION)
      if soundFx then
        action = soundFX2Action(soundFx)
        if action and action.setTag then
          action:setTag(TAG_SOUND_FX_ACTION)
          sprite:runAction(action)
        end
      end
      if type(callback) == "function" then
        performWithDelay(sprite, callback, animation:getDuration())
      end
    end,
    playOnSprite = function(self, sprite, motionName, direction)
      if not (sprite and type(sprite.getScene) == "function") then
        return print("[GamaFigure(" .. tostring(self.id) .. ")::playOnceOnSprite] invalid sprit")
      end
      local animation, isFlipped = self:findAnimation(motionName, direction, true)
      if not (animation) then
        print("[GamaFigure(" .. tostring(self.id) .. ")::playOnSprite] fail to find animation")
        return 
      end
      sprite:setFlippedX(isFlipped)
      sprite:stopActionByTag(TAG_PLAYFRAME_ACTION)
      local animate = cc.Animate:create(animation)
      local action = cc.RepeatForever:create(animate)
      action:setTag(TAG_PLAYFRAME_ACTION)
      sprite:runAction(action)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, playframes, mirrors, soundfxs, defaultMotion, defaultDirection)
      self.id, self.mirrors, self.soundfxs, self.defaultMotion, self.defaultDirection = id, mirrors, soundfxs, defaultMotion, defaultDirection
      assert(self.id, "missing figure id")
      assert(playframes, "missing figure playframes")
      self.motions = { }
      for motionName in pairs(playframes) do
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
local GamaTilemap
do
  local _base_0 = {
    __tostring = function(self)
      return "[GamaTilemap " .. tostring(self.id) .. "]"
    end,
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
      assert(type(x) == "number" and type(y) == "number", "invalid x:" .. tostring(x) .. ", y:" .. tostring(y))
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
        return x, y, false
      end
      self.centerX = x
      self.centerY = y
      self:updateContainerPosition()
      return x, y, true
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
local GamaIconPack
do
  local _base_0 = {
    __tostring = function(self)
      return "[GamaIconPack " .. tostring(self.id) .. "]"
    end,
    retain = function(self)
      for key, spriteFrame in pairs(self.icons) do
        spriteFrame:retain()
      end
    end,
    release = function(self)
      for key, spriteFrame in pairs(self.icons) do
        spriteFrame:release()
      end
    end,
    drawOnSprite = function(self, sprite, key)
      assert(sprite, "invalid sprite:" .. tostring(sprite))
      local icon = self.icons[tostring(key)]
      if not (icon) then
        return print("[GamaIconPack(" .. tostring(self.id) .. ")::drawOnSprite] missing icon for " .. tostring(key))
      end
      sprite:setSpriteFrame(icon)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, id, keys, assetFrames)
      self.id, self.keys = id, keys
      assert(type(id) == "string", "invalid id")
      assert(type(keys) == "table" and #keys > 0, "invalid keys")
      assert(type(assetFrames) == "table", "invalid assetFrames")
      self.icons = { }
      local _list_0 = self.keys
      for _index_0 = 1, #_list_0 do
        local key = _list_0[_index_0]
        local frameKey = tostring(self.id) .. "/" .. tostring(key)
        if assetFrames[frameKey] then
          self.icons[key] = assetFrames[frameKey]
        end
      end
    end,
    __base = _base_0,
    __name = "GamaIconPack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GamaIconPack = _class_0
end
local readJSON, readJSONAsync, getTypeById, loadById, texture2D, Animation, Figure, Tilemap, Scene, Iconpack, cleanup, gama, proxy
readJSON = function(id)
  local path = tostring(id) .. ".csx"
  print("[gama::readJSON] path:" .. tostring(path))
  if not (fs:isFileExist(path)) then
    print("[gama::readJSON] file not found:" .. tostring(path))
    return nil
  end
  local content = fs:getStringFromFile(path)
  return cjson.decode(content)
end
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
end
getTypeById = function(id)
  local type = ASSET_ID_TO_TYPE_KV[id]
  if type then
    return type
  end
  local obj = readJSON(id)
  if not (obj) then
    return nil
  end
  type = obj["type"]
  ASSET_ID_TO_TYPE_KV[id] = type
  print("[gama::getTypeById] type:" .. tostring(type))
  return type
end
loadById = function(id, callback)
  assert(id, "missing id")
  assert(type(callback) == "function", "invalid callback")
  readJSONAsync(id, function(err, csxData)
    if err then
      return callback(err)
    end
    if not (csxData and csxData.type) then
      return callback("invalid csx data")
    end
    local _exp_0 = csxData.type
    if TYPE_ANIMATION == _exp_0 then
      Animation.getByCSX(csxData, callback)
    elseif TYPE_ICONPACK == _exp_0 then
      Iconpack.getByCSX(csxData, callback)
    elseif TYPE_FIGURE == _exp_0 then
      Figure.getByCSX(csxData, callback)
    elseif TYPE_SCENE == _exp_0 then
      Scene.getByCSX(csxData, callback)
    elseif TYPE_TILEMAP == _exp_0 then
      Tilemap.getByCSX(csxData, callback)
    else
      callback("unknow type:" .. tostring(csxData.type))
    end
  end)
end
texture2D = {
  getById = function(id, callback)
    print("[gama::Texture2D::getById] id:" .. tostring(id))
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    local pathToFile = tostring(id)
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
    async.mapSeries(textureIds, texture2D.getById, callback)
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
        if frameInfo.ox and frameInfo.oy then
          frame:setOffset(cc.p(frameInfo.ox, frameInfo.oy))
        end
        SpriteFrameCache:addSpriteFrame(frame, frameName)
        assetFrames[frameName] = frame
      end
    end
    return assetFrames
  end
}
Animation = {
  getByCSX = function(data, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    if not (data and data.id) then
      return callback("invalid csx json data")
    end
    local id = data.id
    local ani = AnimationCache:getAnimation(id)
    if ani then
      console.info("[gama::getByCSX] find ani:" .. tostring(id) .. " in cache")
      return callback(nil, GamaAnimation(id, ani, data.soundeffects))
    end
    local spf = SPF
    if type(data.spf) == "number" and data.spf > 0 then
      spf = data.spf
    end
    texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      if not (ani) then
        local assetFrames = texture2D.makeSpriteFrames(id, texture2Ds[1], data.atlas)
        local playframes = { }
        local defaultFrame = assetFrames[tostring(id) .. "/1"]
        local _list_0 = data.playframes
        for _index_0 = 1, #_list_0 do
          local assetId = _list_0[_index_0]
          table.insert(playframes, (assetFrames[tostring(id) .. "/" .. tostring(assetId + 1)] or defaultFrame))
        end
        ani = cc.Animation:createWithSpriteFrames(playframes, spf)
        AnimationCache:addAnimation(ani, id)
      end
      local gamaAnimation = GamaAnimation(id, ani, data.soundeffects)
      return callback(nil, gamaAnimation)
    end)
  end,
  getById = function(id, callback)
    print("[gama::animation::getById] id:" .. tostring(id))
    Animation.getByCSX(readJSON(id), callback)
  end
}
Figure = {
  getById = function(id, callback)
    print("[gama::tilemap::getById] id:" .. tostring(id))
    Figure.getByCSX(readJSON(id), callback)
  end,
  getByCharacterId = function(id, callback)
    assert(type(callback) == "function", "invalid callback")
    return readJSONAsync(id, function(err, data)
      if err then
        return callback(err)
      end
      if not (data and data.type == "characters" and type(data.figure) == "table") then
        return callback("invalid character data for id:" .. tostring(id))
      end
      data.figure.id = id
      Figure.getByCSX(data.figure, callback)
    end)
  end,
  getByCSX = function(data, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    if not (data and data.id) then
      return callback("invalid csx json data")
    end
    local id = data.id
    texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local assetFrames = { }
      for i, texture in ipairs(texture2Ds) do
        local arrangement = data.atlas[i].arrangment
        texture2D.makeSpriteFrames(id, texture, arrangement, assetFrames)
      end
      local spf = SPF
      if type(data.spf) == "number" and data.spf > 0 then
        spf = data.spf
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
            animation = cc.Animation:createWithSpriteFrames(playframes, spf)
            AnimationCache:addAnimation(animation, animationName)
            directionSet[direction] = animation
          end
        end
      end
      local instance = GamaFigure(id, data.playframes, data.flipx, data.soundeffects)
      return callback(nil, instance)
    end)
  end
}
Tilemap = {
  getById = function(id, callback)
    print("[gama::tilemap::getById] id:" .. tostring(id))
    Tilemap.getByCSX(readJSON(id), callback)
  end,
  getByCSX = function(data, callback)
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
    if not (data and data.id) then
      return callback("invalid csx json data")
    end
    local id = data.id
    texture2D.getFromJSON(data, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local gamaTilemap = GamaTilemap(id, texture2Ds, data.source_width, data.source_height, data.tile_size)
      return callback(nil, gamaTilemap)
    end)
  end
}
Scene = {
  jobProcessor = function(job, next)
    local assetId, jobType = unpack(job)
    local _exp_0 = jobType
    if ASSET_TYPE_CHARACTER == _exp_0 then
      Figure.getByCharacterId(assetId, next)
    elseif ASSET_TYPE_TILEMAP == _exp_0 then
      Tilemap.getById(assetId, next)
    elseif ASSET_TYPE_ANIMATION == _exp_0 then
      Animation.getById(assetId, function(err, gamaAnimation)
        if err then
          print("WARN:[gama::scene::load animation] skip invalid animation:" .. tostring(assetId) .. ", error:" .. tostring(err))
          err = nil
        end
        return next(err, gamaAnimation)
      end)
    else
      print("ERROR: [gama::scene::loadById::on job] unknown asset type:" .. tostring(jobType))
    end
  end,
  loadById = function(id, callback)
    assert(id, "missing scene id")
    assert(type(callback) == "function", "invalid callback")
    print("[gama::scene::loadById] id:" .. tostring(id))
    return readJSONAsync(id, function(err, sceneData)
      if err then
        return callback(err)
      end
      return Scene.getByCSX(sceneData, callback)
    end)
  end,
  getByCSX = function(sceneData, callback)
    assert(sceneData and sceneData.type == "scenes", "invalid data type")
    assert(type(callback) == "function", "invalid callback")
    print("[gama::scene::getByCSX]")
    local jobs = { }
    local pushedIds = { }
    sceneData.binaryBlock = fromhex(sceneData.mask_binary[1])
    sceneData.binaryMask = fromhex(sceneData.mask_binary[2])
    sceneData.isWalkableAt = function(self, pixelX, pixelY)
      return self:isWalkableAtBrick(math.floor(pixelX / self.brickUnitWidth), math.floor(pixelY / self.brickUnitHeight))
    end
    sceneData.isWalkableAtBrick = function(self, brickX, brickY)
      local brickN = (brickY * self.brickWidth) + brickX
      local bytePos = math.floor(brickN / 32) + 1
      local byte = sceneData.binaryBlock[bytePos]
      local bitValue = bit.rshift(byte, brickN % 32)
      return (bitValue % 2) == 1
    end
    sceneData.isMaskedAt = function(self, pixelX, pixelY)
      return self:isMaskedAtBrick(math.floor(pixelX / self.brickUnitWidth), math.floor(pixelY / self.brickUnitHeight))
    end
    sceneData.isMaskedAtBrick = function(self, brickX, brickY)
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
    if type(sceneData.characters) == "table" then
      local _list_0 = sceneData.characters
      for _index_0 = 1, #_list_0 do
        local characterGroup = _list_0[_index_0]
        if type(characterGroup) == "table" then
          for _index_1 = 1, #characterGroup do
            local character = characterGroup[_index_1]
            if type(character.id) == "string" and pushedIds[character.id] ~= true then
              table.insert(jobs, {
                character.id,
                ASSET_TYPE_CHARACTER
              })
              rawset(pushedIds, character.id, true)
            end
          end
        end
      end
    end
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
    async.mapSeries(jobs, Scene.jobProcessor, function(err, results)
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
Iconpack = {
  getById = function(id, callback)
    assert(id, "invalid id")
    assert(type(callback) == "function", "invalid callback")
    print("[gama::iconpack::loadById] id:" .. tostring(id))
    readJSONAsync(id, function(err, data)
      if err then
        return callback(err)
      end
      return Iconpack.getByCSX(data, callback)
    end)
  end,
  getByCSX = function(csxData, callback)
    assert(type(callback) == "function", "invalid callback")
    if not (csxData and csxData.type == "iconpacks") then
      return callback("invalid csx json data")
    end
    local id = csxData.id
    texture2D.getFromJSON(csxData, function(err, texture2Ds)
      if err then
        return callback(err)
      end
      local assetFrames = texture2D.makeSpriteFrames(id, texture2Ds[1], csxData.atlas)
      local keys = { }
      for key in pairs(csxData.atlas) do
        table.insert(keys, key)
      end
      callback(nil, GamaIconPack(id, keys, assetFrames))
    end)
  end
}
cleanup = function()
  SpriteFrameCache:removeUnusedSpriteFrames()
  TextureCache:removeUnusedTextures()
  for key, value in pairs(LOADED_SOUND_EFFECT_FILES) do
    AudioEngine.unloadEffect(key)
  end
  LOADED_SOUND_EFFECT_FILES = { }
end
gama = {
  VERSION = "0.1.0",
  readJSONAsync = readJSONAsync,
  readJSON = readJSON,
  getTypeById = getTypeById,
  loadById = loadById,
  cleanup = cleanup,
  animation = Animation,
  figure = Figure,
  tilemap = Tilemap,
  scene = Scene,
  iconpack = Iconpack,
  TYPE_ANIMATION = TYPE_ANIMATION,
  TYPE_FIGURE = TYPE_FIGURE,
  TYPE_TILEMAP = TYPE_TILEMAP,
  TYPE_SCENE = TYPE_SCENE,
  TYPE_ICONPACK = TYPE_ICONPACK,
  GamaAnimation = GamaAnimation,
  GamaFigure = GamaFigure,
  GamaTilemap = GamaTilemap,
  GamaIconPack = GamaIconPack
}
proxy = { }
setmetatable(proxy, {
  __index = gama,
  __newindex = function(t, k, v)
    return print("attemp to update a read-only table")
  end
})
return proxy
