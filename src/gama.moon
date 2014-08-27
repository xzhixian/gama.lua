
async = require "async"
cjson = require "cjson"
AudioEngine = require "AudioEngine"

print "[gama] init"

SpriteFrameCache = cc.SpriteFrameCache\getInstance!
TextureCache = cc.Director\getInstance!\getTextureCache!
AnimationCache = cc.AnimationCache\getInstance!

fs = cc.FileUtils\getInstance!
fs\addSearchPath "gama/"

-- 将 hex 字符串转化为 UINT32 数组table
fromhex = (str)->
  result = {}
  n = #str
  for i = 1, n, 8
    cc = str\sub(i, i+ 7)
    table.insert result, tonumber(cc, 16)
  return result

WIN_SIZE = cc.Director\getInstance!\getWinSize!
WINDOW_HEIGTH = WIN_SIZE.height
WINDOW_WIDTH = WIN_SIZE.width
HALF_WINDOW_HEIGTH = WINDOW_HEIGTH / 2
HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2


TYPE_ANIMATION = "animations"
TYPE_FIGURE = "figures"
TYPE_TILEMAP = "tilemaps"
TYPE_SCENE = "scenes"
TYPE_ICONPACK = "iconpacks"

ASSET_TYPE_CHARACTER = 10
ASSET_TYPE_TILEMAP = 20
ASSET_TYPE_ANIMATION = 30

ASSET_ID_TO_TYPE_KV = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXTURE_FIELD_ID_1 = "png_8bit"
TEXTURE_FIELD_ID_2 = "jpg"

-- 在 sprite 上播放内容的 action
TAG_PLAYFRAME_ACTION = 65535

-- 在 sprite 上播放 音效
TAG_SOUND_FX_ACTION = 65534

SPF = 1 / 20

TILE_TEXTURE_RECTS =
  [1]: cc.rect(0, 0, 256, 256)
  [2]: cc.rect(256, 0, 256, 256)
  [3]: cc.rect(512, 0, 256, 256)
  [4]: cc.rect(768, 0, 256, 256)
  [5]: cc.rect(0, 256, 256, 256)
  [6]: cc.rect(256, 256, 256, 256)
  [7]: cc.rect(512, 256, 256, 256)
  [8]: cc.rect(768, 256, 256, 256)
  [9]: cc.rect(0, 512, 256, 256)
  [10]: cc.rect(256, 512, 256, 256)
  [11]: cc.rect(512, 512, 256, 256)
  [12]: cc.rect(768, 512, 256, 256)
  [13]: cc.rect(0, 768, 256, 256)
  [14]: cc.rect(256, 768, 256, 256)
  [15]: cc.rect(512, 768, 256, 256)
  [16]: cc.rect(768, 768, 256, 256)


DIRECTION_TO_FLIPX =
  n: false
  ne: false
  e: false
  se: false
  s: false
  sw: true
  w: true
  nw: true

LOADED_SOUND_EFFECT_FILES = {}

playSoundFx = (id)->
  filename = "#{id}.mp3"
  LOADED_SOUND_EFFECT_FILES[filename] = true
  AudioEngine.playEffect filename
  return

-- @param {array}  soundFx, 格式: delay, soundId, delay, soundId ...
soundFX2Action = (soundFx)->
  return nil unless type(soundFx) == "table" and #soundFx > 1

  -- 简单版本
  return playSoundFx soundFx[2] if #soundFx == 2 and soundFx[1] == 0

  sequence = {}
  soundFxIds = {}

  for i = 1, #soundFx, 2
    table.insert sequence, cc.DelayTime\create soundFx[i]
    table.insert soundFxIds, soundFx[i + 1]
    table.insert sequence, cc.CallFunc\create -> playSoundFx(table.remove(soundFxIds, 1))

  return cc.Sequence\create(unpack(sequence))


-- 数据模型类: Gama 动画单元
-- GamaAnimation 是一个素材类，不是具体的物体类
class GamaAnimation
  -- 构造函数
  -- @param ccAnimation cc.Animation
  new: (@id, @ccAnimation, @soundfxs)=>

  retain: => @ccAnimation\retain!

  release: => @ccAnimation\release!

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnSprite: (sprite)=>
    return print "[GamaAnimation(#{@id})::playOnSprite] invalid sprit" unless sprite and type(sprite.getScene) == "function"

    --sprite\cleanup! if sprite\getScene!
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    animate = cc.Animate\create @ccAnimation
    action = cc.RepeatForever\create(animate)
    action\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(action)
    return

  playOnSpriteWithInterval: (sprite, interval, intervalVariance = 0, callbackWhenEachEnd)=>
    return playOnceOnSprite(sprite) unless type(interval) == "number" and interval > 0
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    delay = interval + math.random(intervalVariance) if intervalVariance > 0
    sequence = {cc.Animate\create(@ccAnimation)}
    table.insert(sequence, cc.CallFunc\create(callbackWhenEachEnd)) if type(callbackWhenEachEnd) == "function"
    table.insert(sequence, cc.ToggleVisibility\create!)  -- hide when sleep
    table.insert(sequence, cc.DelayTime\create(delay))
    table.insert(sequence, cc.ToggleVisibility\create!)
    table.insert sequence, cc.CallFunc\create -> self\playOnSpriteWithInterval(sprite, interval, intervalVariance, callbackWhenEachEnd)

    action = cc.Sequence\create sequence
    action\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(action)
    return

  playOnceOnSprite: (sprite)=>
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    action = cc.Animate\create @ccAnimation
    action\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(action)

    -- 播放音效
    sprite\stopActionByTag TAG_SOUND_FX_ACTION
    if @soundfxs
      action = soundFX2Action @soundfxs
      if action and action.setTag -- the action looks like an action
        action\setTag TAG_SOUND_FX_ACTION
        sprite\runAction(action)

    return

-- 动作造型
class GamaFigure

  -- @param {table} data
  --        数据结构：
  --                  动作
  --                    方向
  --                      ccAnimation
  new: (@id, playframes, @mirrors, @soundfxs, @defaultMotion, @defaultDirection)=>
    assert @id, "missing figure id"
    assert playframes, "missing figure playframes"

    @motions = {}
    for motionName in pairs playframes do table.insert @motions, motionName

    --console.info "[gama::new] soundfxs"
    --console.dir @soundfxs

    return

  getId: => @id

  setDefaultMotion: (value)=> @defaultMotion = value

  setDefaultDirection: (value)=> @defaultDirection = value

  getMotions: => @motions

  -- 计算在给定的方向上是否要 x 轴镜像
  isFlipped: (motion, direction)=>
    if @mirrors
      --console.info "[gama::isFlipped] has mirrors: motion:#{motion}, direction:#{direction}"
      return not not (@mirrors[motion] or EMPTY_TABLE)[direction]
    else
      return DIRECTION_TO_FLIPX[direction]

  getSoundFX: (motionName, direction)=>
    return nil if @soundfxs == nil
    return nil if @soundfxs[motionName] == nil
    return @soundfxs[motionName][direction]

  -- 根据动作名字和方向 找到对应的动画
  -- @param motionName
  -- @param direction
  -- @param fallbackToDefaultMotion, when true 会切换到默认动作
  findAnimation: (motionName, direction, fallbackToDefaultMotion)=>
    animationName = "#{@id}/#{motionName}/#{direction}"
    animation = AnimationCache\getAnimation animationName   -- 先到缓存里面找
    return animation, @isFlipped(motionName, direction), @getSoundFX(motionName, direction) if animation

    -- 尝试找当前动作下的默认方向
    animation = AnimationCache\getAnimation "#{@id}/#{motionName}/#{@defaultDirection}"
    return animation, @isFlipped(motionName, @defaultDirection), @getSoundFX(motionName, direction) if animation

    return unless fallbackToDefaultMotion

    print "[GamaFigure(#{@id})::findAnimation] missing animation for motionName:#{motionName}, direction:#{direction}, use defaults"
    animation = AnimationCache\getAnimation "#{@id}/#{@defaultMotion}/#{@defaultDirection}"
    return animation, @isFlipped(@defaultMotion, @defaultDirection), @getSoundFX(motionName, direction) if animation

    print "[GamaFigure(#{@id})::findAnimation] no default animation"
    return nil, false, nil

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnceOnSprite: (sprite, motionName, direction, callback)=>
    --print "[GamaFigure(#{@id})::playOnceOnSprite] sprite:#{sprite}, motionName:#{motionName}, direction:#{direction}"

    return print "[GamaFigure(#{@id})::playOnceOnSprite] invalid sprit" unless sprite and type(sprite.getScene) == "function"

    animation, isFlipped, soundFx = @findAnimation motionName, direction

    unless animation
      print "[GamaFigure(#{@id})::playOnceOnSprite] fail to find animation"
      return

    -- 过滤 空动画
    if table.getn(animation\getFrames!) == 0
      print "[GamaFigure(#{@id})::playOnceOnSprite] animation contain 0 frames"
      callback! if type(callback) == "function"
      return

    -- 播放动画
    sprite\setFlippedX isFlipped
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    action = cc.Animate\create animation
    action\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(action)

    -- 播放音效
    sprite\stopActionByTag TAG_SOUND_FX_ACTION
    if soundFx
      action = soundFX2Action soundFx
      if action and action.setTag -- the action looks like an action
        action\setTag TAG_SOUND_FX_ACTION
        sprite\runAction(action)

    performWithDelay(sprite, callback, animation\getDuration!) if type(callback) == "function"
    return

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnSprite: (sprite, motionName, direction)=>
    --print "[GamaFigure::playOnSprite] sprite:#{sprite}, motionName:#{motionName}, direction:#{direction}"

    return print "[GamaFigure(#{@id})::playOnceOnSprite] invalid sprit" unless sprite and type(sprite.getScene) == "function"

    animation, isFlipped = @findAnimation motionName, direction, true

    unless animation
      print "[GamaFigure(#{@id})::playOnSprite] fail to find animation"
      return

    sprite\setFlippedX isFlipped
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    animate = cc.Animate\create animation
    action = cc.RepeatForever\create(animate)
    action\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(action)
    return


class GamaTilemap

  new: (id, texture2Ds, pixelWidth, pixelHeight, pixelTileSize)=>

    pixelWidth = tonumber(pixelWidth) or 0
    pixelHeight = tonumber(pixelHeight) or 0
    pixelTileSize = tonumber(pixelTileSize) or 0

    assert pixelWidth > 0, "invalid pixelWidth:#{pixelWidth}"
    assert pixelHeight > 0, "invalid pixelWidth:#{pixelHeight}"
    assert pixelTileSize > 0, "invalid pixelWidth:#{pixelTileSize}"

    PIXEL_TEXTURE_SIZE = 1024
    @id = id
    @texture2Ds = texture2Ds
    @pixelWidth = pixelWidth
    @pixelHeight = pixelHeight
    @pixelTileSize = pixelTileSize
    @halfPixelTileSize = pixelTileSize / 2
    @tileWidth = math.ceil(pixelWidth / pixelTileSize)
    @tileHeight = math.ceil(pixelHeight / pixelTileSize)
    @tileCount = @tileWidth * @tileHeight
    @numOfTilePerRow = PIXEL_TEXTURE_SIZE / pixelTileSize
    @numOfTilePerTexture = @numOfTilePerRow * @numOfTilePerRow

    @maxCenterX = @pixelWidth - HALF_WINDOW_WIDTH
    @minCenterX = HALF_WINDOW_WIDTH
    @minCenterY = HALF_WINDOW_HEIGTH
    @maxCenterY = @pixelHeight - HALF_WINDOW_HEIGTH

    @centerX = 0
    @centerY = 0



  -- 在场景中添加底层装饰物
  addOrnament: (gamaAnimation, x, y, flipX)=>
    unless @container
      print "[GamaTilemap::addOrnament] invalide container"
      return

    unless gamaAnimation
      print "[GamaTilemap::addOrnament] invalide gama animation"
      return

    yOffset = WINDOW_HEIGTH
    xOffset = -@pixelTileSize / 2

    sprite = cc.Sprite\create!
    sprite\setAnchorPoint(0.5, 0.5)
    sprite\setFlippedX(not not flipX)
    sprite\setPosition(tonumber(x) + xOffset, yOffset - tonumber(y))
    @container\addChild sprite
    gamaAnimation\playOnSprite(sprite)
    return

  moveBy: (xdiff, ydiff)=> return @setCenterPosition(@centerX - xdiff, @centerY + ydiff)

  -- 设置场景在屏幕上的中心点，基于CPU DOM 坐标系
  -- @return 有效设置后的x， 有效设置后的y， 是否改动了设置前的中心点
  setCenterPosition: (x, y)=>
    --console.log "[GamaTilemap::setCenterPosition] x:#{x}, y:#{y}"
    assert type(x) == "number" and type(y) == "number", "invalid x:#{x}, y:#{y}"

    x = @minCenterX if x < @minCenterX
    x = @maxCenterX if x > @maxCenterX
    y = @minCenterY if y < @minCenterY
    y = @maxCenterY if y > @maxCenterY

    return x, y, false if x == @centerX and y == @centerY       -- lazy

    @centerX = x
    @centerY = y

    --@container\setPosition(HALF_WINDOW_WIDTH - x + (@pixelTileSize / 2) , y - HALF_WINDOW_HEIGTH) if @container
    @updateContainerPosition!
    return x, y, true

  updateContainerPosition: =>
    @container\setPosition(HALF_WINDOW_WIDTH - @centerX + (@pixelTileSize / 2) , @centerY - HALF_WINDOW_HEIGTH) if @container

  -- 将 UI 的目标 X,Y 转换为GPU渲染时候的 X, Y
  uiCordToVertexCord: (x, y)=>
    return x - @halfPixelTileSize, y + WINDOW_HEIGTH

  -- 返回显示容器的坐标
  getContainerPoisition: => @container/getPosition!

  -- 将地图构建到给定的 sprite 容器
  bindToSprite: (sprite)=>
    assert sprite and type(sprite.addChild) == "function", "invalid sprite"
    --sprite\cleanup!
    sprite\setAnchorPoint(0, 0)
    @container = cc.Sprite\create!
    @container\setAnchorPoint(0.5, 0.5)
    @container\setPosition(0,0)
    sprite\addChild @container

    --console.warn "[gama::method] @tileCount:#{@tileCount}, tileWidth:#{@tileWidth}, tileHeight:#{@tileHeight}"

    yOffset = WINDOW_HEIGTH - (@pixelTileSize / 2)

    for tileId = 1, @tileCount
      textureId = math.ceil(tileId / @numOfTilePerTexture)
      texture = @texture2Ds[textureId]
      sprite = cc.Sprite\createWithTexture texture
      x = (tileId - 1) % @tileWidth * @pixelTileSize
      y = yOffset - (math.floor((tileId - 1) / @tileWidth) * @pixelTileSize)
      sprite\setAnchorPoint(0.5, 0.5)

      tileIdInTexture = tileId - @numOfTilePerTexture * (textureId - 1)
      --console.log "[GamaTilemap::bindToSprite] tileId:#{tileId}, x:#{x}, y:#{y}, textureId:#{textureId}, tileIdInTexture:#{tileIdInTexture}"
      sprite\setTextureRect(TILE_TEXTURE_RECTS[tileIdInTexture])
      sprite\setPosition(x, y)
      @container\addChild sprite

    --@container\setPosition(0, @pixelHeight)
    --@setCenterPosition(HALF_WINDOW_WIDTH, HALF_WINDOW_HEIGTH)
      @updateContainerPosition!
    return

class GamaIconPack

  new: (@id, @keys, assetFrames)=>
    assert type(id) == "string", "invalid id"
    assert type(keys) == "table" and #keys > 0, "invalid keys"
    assert type(assetFrames) == "table", "invalid assetFrames"
    @icons = {}
    for key in *@keys
      frameKey = "#{@id}/#{key}"
      @icons[key] = assetFrames[frameKey] if assetFrames[frameKey]
    return

  retain: =>
    for key, spriteFrame in pairs @icons
      spriteFrame\retain!

  release: =>
    for key, spriteFrame in pairs @icons
      spriteFrame\release!


  drawOnSprite: (sprite, key)=>
    assert sprite, "invalid sprite:#{sprite}"
    icon = @icons[tostring(key)]
    return print "[GamaIconPack(#{@id})::drawOnSprite] missing icon for #{key}" unless icon
    sprite\setSpriteFrame icon
    return

--gama = nil

local *


readJSON = (id)->
  path =  "#{id}.csx"
  print "[gama::readJSON] path:#{path}"

  unless fs\isFileExist path
    print "[gama::readJSON] file not found:#{path}"
    return nil

  content = fs\getStringFromFile path

  -- TODO: use sting.match
  return cjson.decode content


readJSONAsync = (id, callback)->
  assert id, "missing id"
  assert type(callback) == "function", "invalid callback"
  path =  "#{id}.csx"
  return callback "file:#{path} not found" unless fs\isFileExist path

  status, content = pcall fs.getStringFromFile, fs, path

  return callback "fail to read file:#{path}, error:#{content}" unless status

  status, content = pcall cjson.decode, content

  return callback "fail to decode json from:#{path}, error:#{content}" unless status

  return callback nil, content


-- return the asset type of given asset id
-- @param id
-- @return asset type, or nil
getTypeById = (id)->

  type = ASSET_ID_TO_TYPE_KV[id]
  return type if type

  obj = readJSON id
  return nil unless obj

  type = obj["type"]
  ASSET_ID_TO_TYPE_KV[id] = type

  print "[gama::getTypeById] type:#{type}"

  return type


loadById = (id, callback)->
  assert id, "missing id"
  assert type(callback) == "function", "invalid callback"

  readJSONAsync id, (err, csxData)->
    return callback err if err
    return callback "invalid csx data" unless csxData and csxData.type
    switch csxData.type
      when TYPE_ANIMATION
        Animation.getByCSX csxData, callback
      when TYPE_ICONPACK
        Iconpack.getByCSX csxData, callback
      when TYPE_FIGURE
        Figure.getByCSX csxData, callback
      when TYPE_SCENE
        Scene.getByCSX csxData, callback
      when TYPE_TILEMAP
        Tilemap.getByCSX csxData, callback
      else
        callback "unknow type:#{csxData.type}"
    return
  return

-- 管理和处理 texture2D
texture2D =

  --- getTextureById
  -- 获取纹理
  -- @param id asset id
  -- @param extname
  -- @param callback , signature: callback(err, texture2D)
  getById:  (id, callback)->

    print "[gama::Texture2D::getById] id:#{id}"

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    pathToFile = tostring(id)

    texture = TextureCache\getTextureForKey(pathToFile)

    -- require texture is avilable
    if texture
      print "[gama::Texture2D::getById] texture avilable for id:#{id}#{extname}"
      return  callback(nil, texture)

    return callback "missing file at:#{pathToFile}" unless fs\isFileExist pathToFile

    texture = TextureCache\addImageAsync pathToFile, (texture2D)->
      return callback "addImageAsync return nil" unless texture2D
      return callback(nil, texture2D)

    return

  -- 分析 csx json，从里面拉出来 texture id，然后在内存中载入所有所需要的 Texture2D
  getFromJSON: (data, callback)->

    return callback "missing texture decleration" unless type(data.texture) == "table"

    -- work out required texture ids
    textureIds = data.texture[TEXTURE_FIELD_ID_1] or data.texture[TEXTURE_FIELD_ID_2]

    textureIds = {textureIds} if type(textureIds) == "string"

    return callback "invalid textureIds:#{textureIds}, field:#{TEXTURE_FIELD_ID_1} or #{TEXTURE_FIELD_ID_2}" unless type(textureIds) == "table" and #textureIds > 0

    -- 根据 textureIds 准备好 texture2D 实例
    async.mapSeries textureIds, texture2D.getById, callback

    return


  -- 根据给定的 texture , arrangement 生产出 sprite frame
  -- @param {String} assetId, gama asset id
  -- @param {Texture2D} texture
  -- @param {Table} arrangement, bin arrangement
  -- @param {Table} assetFrames, optional, is supplied, then will be used as output
  -- @return frames[]
  makeSpriteFrames: (assetId, texture, arrangement, assetFrames)->

    assetFrames = assetFrames or {}

    for frameId, frameInfo in pairs arrangement

      frameName = "#{assetId}/#{frameId}"

      frame = SpriteFrameCache\getSpriteFrame(frameName)

      if frame
        --print "[animation::buildSpriteFrameCache] find frame in cache, asset frame name: #{frameName}"
        assetFrames[frameName] = frame

      else
        --print "[animation::buildSpriteFrameCache] build up from json, asset frame name: #{frameName}"
        rect = cc.rect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h)

        frame = cc.SpriteFrame\createWithTexture(texture, rect)
        frame\setOriginalSizeInPixels(cc.size(512, 512))
        frame\setOffset(cc.p(frameInfo.ox, frameInfo.oy)) if frameInfo.ox and frameInfo.oy
        -- push the frame into cache
        SpriteFrameCache\addSpriteFrame frame, frameName

        assetFrames[frameName] = frame

    return assetFrames


-- Animation module
Animation =

  -- @param {table} data, csx json data
  getByCSX: (data, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    return callback "invalid csx json data" unless data and data.id

    id = data.id

    ani = AnimationCache\getAnimation id   -- 先到缓存里面找

    if ani
      console.info "[gama::getByCSX] find ani:#{id} in cache"
      return callback nil, GamaAnimation(id, ani, data.soundeffects)

    spf = SPF
    spf = data.spf if type(data.spf) == "number" and data.spf > 0

    -- 根据 json 准备好 texture2D 实例
    texture2D.getFromJSON data, (err, texture2Ds)->
      return callback err if err

      unless ani
        assetFrames = texture2D.makeSpriteFrames(id, texture2Ds[1], data.atlas)
        playframes = {}
        defaultFrame = assetFrames["#{id}/1"]
        for assetId in *data.playframes
          table.insert(playframes, (assetFrames["#{id}/#{assetId + 1}"] or defaultFrame))
        ani = cc.Animation\createWithSpriteFrames(playframes, spf)
        AnimationCache\addAnimation(ani, id)  -- 加入到缓存，避免再次计算

      gamaAnimation = GamaAnimation(id, ani, data.soundeffects)

      callback nil, gamaAnimation

    return


  -- @param {function} callback, signature: callback(err, gamaAnimation)
  getById:  (id, callback)->
    print "[gama::animation::getById] id:#{id}"
    Animation.getByCSX(readJSON(id), callback)
    return


Figure =

  -- @param {function} callback, signature: callback(err, gamaFigure)
  getById:  (id, callback)->
    print "[gama::tilemap::getById] id:#{id}"
    Figure.getByCSX(readJSON(id), callback)
    return

  -- 根据 character id 来获取 figure
  getByCharacterId:  (id, callback)->
    assert type(callback) == "function", "invalid callback"
    readJSONAsync id, (err, data)->
      return callback err if err
      return callback "invalid character data for id:#{id}" unless data and data.type == "characters" and type(data.figure) == "table"
      -- NOTE: 将所请求的 figure 的 id 重置为 character 的 id
      data.figure.id = id
      Figure.getByCSX(data.figure, callback)
      return

  -- @param {table} data, csx json data
  getByCSX: (data, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    return callback "invalid csx json data" unless data and data.id

    id = data.id

    -- 根据 json 准备好 texture2D 实例
    texture2D.getFromJSON data, (err, texture2Ds)->

      return callback err if err

      -- 准备好素材帧
      assetFrames = {}
      for i, texture in ipairs texture2Ds
        arrangement = data.atlas[i].arrangment
        texture2D.makeSpriteFrames(id, texture, arrangement, assetFrames)

      spf = SPF
      spf = data.spf if type(data.spf) == "number" and data.spf > 0

      for motionName, directionSet in pairs data.playframes       -- 遍历动作
        for direction, assetFrameIds in pairs directionSet        -- 遍历每个动作的方向
          animationName = "#{id}/#{motionName}/#{direction}"

          animation = AnimationCache\getAnimation animationName   -- 先到缓存里面找

          if animation
            -- found in cache
            directionSet[direction] = animation

          else

            playframes = {}
            for assetId in *assetFrameIds
              assetFrame = assetFrames["#{id}/#{assetId}"]
              table.insert(playframes, assetFrame) if assetFrame

            animation = cc.Animation\createWithSpriteFrames(playframes, spf)
            AnimationCache\addAnimation(animation, animationName)  -- 加入到缓存，避免再次计算
            directionSet[direction] = animation

      instance = GamaFigure(id, data.playframes, data.flipx, data.soundeffects)
      callback nil, instance

    return


Tilemap =

  -- @param {function} callback, signature: callback(err, gamaTilemap)
  getById:  (id, callback)->
    print "[gama::tilemap::getById] id:#{id}"
    Tilemap.getByCSX(readJSON(id), callback)
    return

  -- @param {table} data, csx json data
  getByCSX: (data, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    return callback "invalid csx json data" unless data and data.id

    id = data.id

    -- 根据 json 准备好 texture2D 实例
    texture2D.getFromJSON data, (err, texture2Ds)->

      return callback err if err

      gamaTilemap = GamaTilemap(id, texture2Ds, data.source_width, data.source_height, data.tile_size)

      return callback nil, gamaTilemap

    return

Scene =

  --loadedData: nil

  jobProcessor: (job, next)->
    assetId, jobType = unpack job

    switch jobType
      when ASSET_TYPE_CHARACTER
        Figure.getByCharacterId assetId, next

      when ASSET_TYPE_TILEMAP
        Tilemap.getById assetId, next

      when ASSET_TYPE_ANIMATION
        Animation.getById assetId, (err, gamaAnimation)->
          if err
            print "WARN:[gama::scene::load animation] skip invalid animation:#{assetId}, error:#{err}"
            err = nil
          return next err, gamaAnimation
      else
        print "ERROR: [gama::scene::loadById::on job] unknown asset type:#{jobType}"

    return

  -- callback signature: callback(err, sceneDataPack)
  --  其中 sceneDataPack 是一个数组，内涵： 1. sceneData, 2. tilemap, ...
  loadById: (id, callback)->

    assert id, "missing scene id"

    assert(type(callback) == "function", "invalid callback")
    print "[gama::scene::loadById] id:#{id}"

    -- 加载场景数据
    readJSONAsync id, (err, sceneData)->
      return callback err if err
      return Scene.getByCSX sceneData, callback


  -- @param {table} data, csx json data
  getByCSX: (sceneData, callback)->

    assert sceneData and sceneData.type == "scenes", "invalid data type"
    assert type(callback) == "function", "invalid callback"

    print "[gama::scene::getByCSX]"

    jobs = {}
    pushedIds = {}

    -- 将阻挡点和隐身点数据转换成 binary
    sceneData.binaryBlock = fromhex(sceneData.mask_binary[1])
    sceneData.binaryMask = fromhex(sceneData.mask_binary[2])

    sceneData.isWalkableAt = (pixelX, pixelY)=>
      @isWalkableAtBrick(math.floor(pixelX / @brickUnitWidth), math.floor(pixelY / @brickUnitHeight))

    sceneData.isWalkableAtBrick = (brickX, brickY)=>
      brickN = (brickY * @brickWidth) + brickX -- brickX, brickY are 0-based
      bytePos = math.floor(brickN / 32) + 1
      byte = sceneData.binaryBlock[bytePos]
      bitValue = bit.rshift(byte, brickN % 32)
      return (bitValue % 2) == 1

    sceneData.isMaskedAt = (pixelX, pixelY)=>
      @isMaskedAtBrick(math.floor(pixelX / @brickUnitWidth), math.floor(pixelY / @brickUnitHeight))

    sceneData.isMaskedAtBrick = (brickX, brickY)=>
      brickN = (brickY * @brickWidth) + brickX -- brickX, brickY are 0-based
      bytePos = math.floor(brickN / 32) + 1
      byte = sceneData.binaryMask[bytePos]
      bitValue = bit.rshift(byte, brickN % 32)
      return (bitValue % 2) == 0

    -- 下载场景
    -- 下载任务的第一个步 是 下载场景地图
    table.insert jobs, {sceneData.map_id, ASSET_TYPE_TILEMAP}
    rawset pushedIds, sceneData.map_id, true

    -- characters
    if type(sceneData.characters) == "table"
      for characterGroup in *sceneData.characters
        if type(characterGroup) == "table"
          for character in *characterGroup
            if type(character.id) == "string" and pushedIds[character.id] != true
              --console.error "[gama::push character] id:#{character.id}"
              table.insert jobs, {character.id, ASSET_TYPE_CHARACTER}
              rawset pushedIds, character.id, true

    -- ornaments
    if type(sceneData.ornaments) == "table"
      for item in *sceneData.ornaments
        assetId = item.id
        if assetId and pushedIds[assetId] == nil
          table.insert jobs, {assetId, ASSET_TYPE_ANIMATION}
          rawset pushedIds, assetId, true

    async.mapSeries jobs, Scene.jobProcessor, (err, results)->
      return callback(err) if err

      gamaTilemap = results[1]

      -- 在返回结果的头部插入 sceneData
      table.insert results, 1, sceneData

      -- 在有序数组的结构的同时，在把这个返回结果做成 kv
      for piece in * results
        id = piece.id
        results[tostring(id)] = piece if id

      -- 将 tilemap 中的长宽数据补充到 sceneData 中
      sceneData.pixelWidth = gamaTilemap.pixelWidth
      sceneData.pixelHeight = gamaTilemap.pixelHeight
      sceneData.brickUnitWidth = sceneData.brick_width
      sceneData.brickUnitHeight = sceneData.brick_height
      sceneData.brickWidth = math.floor(gamaTilemap.pixelWidth / sceneData.brick_width)
      sceneData.brickHeight = math.floor(gamaTilemap.pixelHeight / sceneData.brick_height)

      --console.info "[gama::] gamaTilemap:#{gamaTilemap}"
      --console.info "[gama::] brickUnitWidth:#{sceneData.brickUnitWidth}, brickUnitHeight:#{sceneData.brickUnitHeight}, brickWidth:#{sceneData.brickWidth}, brickHeight:#{sceneData.brickHeight}"

      return callback nil, results

    return


Iconpack =

  -- callback signature: callback(err, gamaIconPack)
  getById: (id, callback)->

    assert id, "invalid id"

    assert(type(callback) == "function", "invalid callback")

    print "[gama::iconpack::loadById] id:#{id}"

    -- 加载场景数据
    readJSONAsync id, (err, data)->
      return callback err if err
      return Iconpack.getByCSX data, callback

    return

  -- @param {table} data, csx json data
  getByCSX: (csxData, callback)->
    print "[gama::iconpack::getByCSX]"

    assert type(callback) == "function", "invalid callback"

    return callback "invalid csx json data" unless csxData and csxData.type == "iconpacks"

    id = csxData.id

    -- 根据 json 准备好 texture2D 实例
    texture2D.getFromJSON csxData, (err, texture2Ds)->
      return callback err if err

      assetFrames = texture2D.makeSpriteFrames(id, texture2Ds[1], csxData.atlas)

      keys = {}
      for key in pairs csxData.atlas
        table.insert keys, key

      callback nil, GamaIconPack(id, keys, assetFrames)
      return
    return


cleanup = ->
  SpriteFrameCache\removeUnusedSpriteFrames!
  TextureCache\removeUnusedTextures!

  -- unload all played effects
  for key, value in pairs LOADED_SOUND_EFFECT_FILES do AudioEngine.unloadEffect key
  LOADED_SOUND_EFFECT_FILES = {}

  return


gama =
  VERSION:  "0.1.0"

  :readJSONAsync
  :readJSON
  :getTypeById
  :loadById
  :cleanup

  animation: Animation
  figure: Figure
  tilemap: Tilemap
  scene:Scene
  iconpack: Iconpack

  :TYPE_ANIMATION
  :TYPE_FIGURE
  :TYPE_TILEMAP
  :TYPE_SCENE
  :TYPE_ICONPACK
  :GamaAnimation
  :GamaFigure
  :GamaTilemap
  :GamaIconPack

-- sealed
proxy = {}
setmetatable proxy,
  __index: gama
  __newindex: (t ,k ,v)-> print "attemp to update a read-only table"

return proxy


