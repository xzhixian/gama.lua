
async = require "async"
cjson = require "cjson"

print "[gama] init"

SpriteFrameCache = cc.SpriteFrameCache\getInstance!
TextureCache = cc.Director\getInstance!\getTextureCache!
AnimationCache = cc.AnimationCache\getInstance!

fs = cc.FileUtils\getInstance!
fs\addSearchPath "gama/"

WIN_SIZE = cc.Director\getInstance!\getWinSize!
WINDOW_HEIGTH = WIN_SIZE.height
WINDOW_WIDTH = WIN_SIZE.width
HALF_WINDOW_HEIGTH = WINDOW_HEIGTH / 2
HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2

-- key: asset id
-- value: asset type
ASSET_ID_TO_TYPE_KV = {}

-- key: asset id
-- value:
--    texture :
--    action :
--ASSET_ID_TO_ANIMATION_KV = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXTURE_FIELD_ID_1 = "png_8bit"
TEXTURE_FIELD_ID_2 = "jpg"

SPF = 1 / 15


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


-- TODO: following conts should goes into gama
DIRECTION_TO_FLIPX =
  n: false
  ne: false
  e: false
  se: false
  s: false
  sw: true
  w: true
  nw: true


-- 数据模型类: Gama 动画单元
-- GamaAnimation 是一个素材类，不是具体的物体类
class GamaAnimation
  -- 构造函数
  -- @param ccAnimation cc.Animation
  new: (id, ccAnimation)=>
    assert id, "missing animation id"
    assert ccAnimation, "missing ccAnimation"
    @id = id
    @ccAnimation = ccAnimation

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnSprite: (sprite)=>
    assert sprite, "invalid sprite"
    sprite\cleanup!
    animate = cc.Animate\create @ccAnimation
    action = cc.RepeatForever\create(animate)
    sprite\runAction(action)
    return

-- 动作造型
class GamaFigure

  -- @param {table} data
  --        数据结构：
  --                  动作
  --                    方向
  --                      ccAnimation
  new: (id, data, defaultMotion, defaultDirection)=>
    assert id, "missing figure id"
    assert data, "missing figure data"
    @id = id
    @data = data
    @defaultMotion = defaultMotion
    @defaultDirection = defaultDirection
    @motions = {}
    for motionName in pairs data
      table.insert @motions, motionName

  getId: => @id

  setDefaultMotion: (value)=> @defaultMotion = value

  setDefaultDirection: (value)=> @defaultDirection = value

  getMotions: => @motions

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnSprite: (sprite, motionName, direction)=>
    print "[GamaFigure::playOnSprite] sprite:#{sprite}, motionName:#{motionName}, direction:#{direction}"

    assert sprite, "invalid sprite"
    animationName = "#{@id}/#{motionName}/#{direction or @defaultDirection}"
    animation = AnimationCache\getAnimation animationName   -- 先到缓存里面找
    unless animation
      print "[GamaFigure(#{playOnSprite})::playOnSprite] missing animation for motionName:#{motionName}, direction:#{direction}, use defaults"
      animation = AnimationCache\getAnimation "#{@id}/#{@defaultMotion}/#{@defaultDirection}"
      unless animation
        print "[GamaFigure(#{playOnSprite})::playOnSprite] no default animation"
        return

    sprite\cleanup!
    animate = cc.Animate\create animation
    action = cc.RepeatForever\create(animate)
    sprite\runAction(action)
    return


-- 人物
class GamaCharacter

  new: (id, gamaFigure, sprite)=>
    @id = id
    @figure = gamaFigure
    @motions = gamaFigure.getMotions
    @sprite = sprite

    @curDirection = "s"
    @curMotion = "idl"
    @applyChange!

  getId: => @id

  getCurDirection: => @curDirection

  getCurMotion: => @getCurMotion

  applyChange: =>
    @sprite\setFlippedX(DIRECTION_TO_FLIPX[@curDirection])
    @figure\playOnSprite @sprite, @curMotion, @curDirection

  setDirection: (value)=>
    return if @curDirection == value  --lazy
    @curDirection = value
    @applyChange!
    return

  setMotion: (value)=>
    return if @curMotion == value   --lazy
    @curMotion = value
    @applyChange!
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
    @tileWidth = math.ceil(pixelWidth / pixelTileSize)
    @tileHeight = math.ceil(pixelHeight / pixelTileSize)
    @tileCount = @tileWidth * @tileHeight
    @numOfTilePerRow = PIXEL_TEXTURE_SIZE / pixelTileSize
    @numOfTilePerTexture = @numOfTilePerRow * @numOfTilePerRow
    @minLeftBottomX = WINDOW_WIDTH - @pixelWidth
    @maxLeftBottomX = 0
    @minLeftBottomY = WINDOW_HEIGTH
    @maxLeftBottomY = @pixelHeight

  moveBy: (diff)=>
    console.info "[GamaTilemap::moveBy] x:#{diff.x}, y:#{diff.y}"
    @setCenterPosition(@x + diff.x, @y + diff.y)
    return

  -- CPU DOM 坐标系
  setCenterPosition: (x, y)=>
    console.log "[gama::setCenterPosition] x:#{x}, y:#{y}"

    leftBottomX = x - HALF_WINDOW_WIDTH
    leftBottomY = y - HALF_WINDOW_HEIGTH

    leftBottomX = @minLeftBottomX if leftBottomX < @minLeftBottomX
    leftBottomX = @maxLeftBottomX if leftBottomX > @maxLeftBottomX

    leftBottomY = @maxLeftBottomY if leftBottomY > @maxLeftBottomY
    leftBottomY = @minLeftBottomY if leftBottomY < @minLeftBottomY

    @x = leftBottomX + HALF_WINDOW_WIDTH
    @y = leftBottomY + HALF_WINDOW_HEIGTH

    console.log "[gama::setCenterPosition] leftBottomX:#{leftBottomX}, leftBottomY:#{leftBottomY}, @x:#{@x}, @y:#{@y}"
    @container\setPosition(leftBottomX, leftBottomY)
    return

  bindToSprite: (sprite)=>
    assert sprite and type(sprite.addChild) == "function", "invalid sprite"
    --sprite\cleanup!
    sprite\setAnchorPoint(0, 0)
    @container = cc.Sprite\create!
    @container\setAnchorPoint(0.5, 0.5)
    @container\setPosition(0,0)
    sprite\addChild @container

    console.warn "[gama::method] @tileCount:#{@tileCount}, tileWidth:#{@tileWidth}, tileHeight:#{@tileHeight}"

    for tileId = 1, @tileCount
      textureId = math.ceil(tileId / @numOfTilePerTexture)
      texture = @texture2Ds[textureId]
      sprite = cc.Sprite\createWithTexture texture
      x = (tileId - 1) % @tileWidth * @pixelTileSize
      y = -(math.floor((tileId - 1) / @tileWidth) * @pixelTileSize)
      sprite\setAnchorPoint(0, 1)

      tileIdInTexture = tileId - @numOfTilePerTexture * (textureId - 1)
      --console.log "[GamaTilemap::bindToSprite] tileId:#{tileId}, x:#{x}, y:#{y}, textureId:#{textureId}, tileIdInTexture:#{tileIdInTexture}"
      sprite\setTextureRect(TILE_TEXTURE_RECTS[tileIdInTexture])
      sprite\setPosition(x, y)
      @container\addChild sprite

    --@container\setPosition(0, @pixelHeight)
    @setCenterPosition(0, 0)
    return

export gama

gama =
  VERSION:  "0.1.0"

  getAssetPath: (id)-> "#{id}"

  readJSON: (id)->
    path =  "#{id}.csx"
    print "[gama::readJSON] path:#{path}"

    unless fs\isFileExist path
      print "[gama::readJSON] file not found:#{path}"
      return nil

    content = fs\getStringFromFile path

    -- TODO: use sting.match
    return cjson.decode content

  -- return the asset type of given asset id
  -- @param id
  -- @return asset type, or nil
  getTypeById:  (id)->

    type = ASSET_ID_TO_TYPE_KV[id]
    return type if type

    obj = gama.readJSON id
    return nil unless obj

    type = obj["type"]
    ASSET_ID_TO_TYPE_KV[id] = type

    print "[gama::getTypeById] type:#{type}"

    return type

  -- 创建一个 GamaFigure 实例，并且将这个实例绑定到用于显示其的 Sprite 上
  createCharacterWithSprite: (id, gamaFigure, sprite)->
    assert id
    assert gamaFigure
    assert sprite
    return GamaCharacter(id, gamaFigure, sprite)

-- 管理和处理 texture2D
gama.texture2D =

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

    pathToFile = gama.getAssetPath id

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
    async.mapSeries textureIds, gama.texture2D.getById, callback

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
        frame\setOffset(cc.p(frameInfo.ox, frameInfo.oy))
        -- push the frame into cache
        SpriteFrameCache\addSpriteFrame frame, frameName

        assetFrames[frameName] = frame

    return assetFrames


-- Animation module
gama.animation =

  -- @param {table} data, csx json data
  getByCSX: (data, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    return callback "invalid csx json data" unless data and data.id

    id = data.id

    -- 根据 json 准备好 texture2D 实例
    gama.texture2D.getFromJSON data, (err, texture2Ds)->
      return callback err if err

      animation = AnimationCache\getAnimation id   -- 先到缓存里面找

      unless animation
        assetFrames = gama.texture2D.makeSpriteFrames(id, texture2Ds[1], data.atlas)
        playframes = {}
        defaultFrame = assetFrames["#{id}/1"]
        for assetId in *data.playframes
          table.insert(playframes, (assetFrames["#{id}/#{assetId + 1}"] or defaultFrame))
        animation = cc.Animation\createWithSpriteFrames(playframes, SPF)
        AnimationCache\addAnimation(animation, id)  -- 加入到缓存，避免再次计算

      gamaAnimation = GamaAnimation(id, animation)

      callback nil, gamaAnimation

    return


  -- @param {function} callback, signature: callback(err, gamaAnimation)
  getById:  (id, callback)->
    print "[gama::animation::getById] id:#{id}"
    gama.animation.getByCSX(gama.readJSON(id), callback)
    return


gama.figure =

  -- @param {function} callback, signature: callback(err, gamaFigure)
  getById:  (id, callback)->
    print "[gama::tilemap::getById] id:#{id}"
    gama.figure.getByCSX(gama.readJSON(id), callback)
    return


  -- @param {table} data, csx json data
  getByCSX: (data, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    return callback "invalid csx json data" unless data and data.id

    id = data.id

    -- 根据 json 准备好 texture2D 实例
    gama.texture2D.getFromJSON data, (err, texture2Ds)->

      return callback err if err

      -- 准备好素材帧
      assetFrames = {}
      for i, texture in ipairs texture2Ds
        arrangement = data.atlas[i].arrangment
        gama.texture2D.makeSpriteFrames(id, texture, arrangement, assetFrames)

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

            animation = cc.Animation\createWithSpriteFrames(playframes, SPF)
            AnimationCache\addAnimation(animation, animationName)  -- 加入到缓存，避免再次计算
            directionSet[direction] = animation

      instance = GamaFigure(id, data.playframes)
      callback nil, instance

    return


gama.tilemap =

  -- @param {function} callback, signature: callback(err, gamaTilemap)
  getById:  (id, callback)->
    print "[gama::tilemap::getById] id:#{id}"
    gama.tilemap.getByCSX(gama.readJSON(id), callback)
    return

  -- @param {table} data, csx json data
  getByCSX: (data, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    return callback "invalid csx json data" unless data and data.id

    id = data.id

    -- 根据 json 准备好 texture2D 实例
    gama.texture2D.getFromJSON data, (err, texture2Ds)->

      return callback err if err

      gamaTilemap = GamaTilemap(id, texture2Ds, data.source_width, data.source_height, data.tile_size)

      return callback nil, gamaTilemap

    return


