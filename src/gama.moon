
async = require "async"
cjson = require "cjson"

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

EVENT_START = "start"
EVENT_PROGRESS = "progress"
EVENT_WARNING = "warning"
EVENT_COMPLETE = "complete"
EVENT_FAILED = "failed"

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
    return print "[GamaAnimation(#{@id})::playOnSprite] invalid sprit" unless sprite and type(sprite.getScene) == "function"

    --sprite\cleanup! if sprite\getScene!
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    animate = cc.Animate\create @ccAnimation
    action = cc.RepeatForever\create(animate)
    action\setTag TAG_PLAYFRAME_ACTION
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

  -- 根据动作名字和方向 找到对应的动画
  -- @param motionName
  -- @param direction
  -- @param fallbackToDefaultMotion, when true 会切换到默认动作
  findAnimation: (motionName, direction, fallbackToDefaultMotion)=>
    animationName = "#{@id}/#{motionName}/#{direction}"
    animation = AnimationCache\getAnimation animationName   -- 先到缓存里面找
    return animation if animation

    -- 尝试找当前动作下的默认方向
    animation = AnimationCache\getAnimation "#{@id}/#{motionName}/#{@defaultDirection}"
    return animation if animation

    return unless fallbackToDefaultMotion

    print "[GamaFigure(#{@id})::findAnimation] missing animation for motionName:#{motionName}, direction:#{direction}, use defaults"
    animation = AnimationCache\getAnimation "#{@id}/#{@defaultMotion}/#{@defaultDirection}"
    return animation if animation

    print "[GamaFigure(#{@id})::findAnimation] no default animation"
    return nil

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnceOnSprite: (sprite, motionName, direction, callback)=>
    --print "[GamaFigure(#{@id})::playOnceOnSprite] sprite:#{sprite}, motionName:#{motionName}, direction:#{direction}"

    return print "[GamaFigure(#{@id})::playOnceOnSprite] invalid sprit" unless sprite and type(sprite.getScene) == "function"

    animation = @findAnimation motionName, direction

    unless animation
      print "[GamaFigure(#{@id})::playOnceOnSprite] fail to find animation"
      return

    -- 过滤 空动画
    if table.getn(animation\getFrames!) == 0
      print "[GamaFigure(#{@id})::playOnceOnSprite] animation contain 0 frames"
      callback! if type(callback) == "function"
      return

    --sprite\cleanup! if sprite\getScene!
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    animate = cc.Animate\create animation
    animate\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(animate)

    performWithDelay(sprite, callback, animation\getDuration!) if type(callback) == "function"
    return

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnSprite: (sprite, motionName, direction)=>
    --print "[GamaFigure::playOnSprite] sprite:#{sprite}, motionName:#{motionName}, direction:#{direction}"

    return print "[GamaFigure(#{@id})::playOnceOnSprite] invalid sprit" unless sprite and type(sprite.getScene) == "function"

    animation = @findAnimation motionName, direction, true

    unless animation
      print "[GamaFigure(#{@id})::playOnSprite] fail to find animation"
      return

    --console.info "[gama::playOnSprite] animation:#{animation}"

    --sprite\cleanup! if sprite\getScene!
    sprite\stopActionByTag TAG_PLAYFRAME_ACTION
    animate = cc.Animate\create animation
    action = cc.RepeatForever\create(animate)
    action\setTag TAG_PLAYFRAME_ACTION
    sprite\runAction(action)
    return


-- 人物
--class GamaCharacter

  --new: (id, gamaFigure, sprite)=>
    --@id = id
    --@figure = gamaFigure
    --@motions = gamaFigure.getMotions
    --@sprite = sprite

    ---- 连续性动作的 motion id 列表
    --@continouseMotionIds =
      --idl: true

    --@curDirection = "s"
    --@curMotion = "idl"
    --@applyChange!

  ---- 添加连续性动作的id
  --addContinouseMotionId: (...)=>
    --names = {...}
    --for name in *names
      --@continouseMotionIds[name] = true

    --console.info "[gama::] continouseMotionIds:"
    --console.dir @continouseMotionIds

    --return

  --getId: => @id

  --getCurDirection: => @curDirection

  --getCurMotion: => @getCurMotion

  --applyChange: =>
    --@sprite\setFlippedX(DIRECTION_TO_FLIPX[@curDirection])

    --if @continouseMotionIds[@curMotion]
      --@figure\playOnSprite @sprite, @curMotion, @curDirection
      --return

    --@figure\playOnceOnSprite @sprite, @curMotion, @curDirection

  --setDirection: (value)=>
    --return if @curDirection == value  --lazy
    --@curDirection = value
    --@applyChange!
    --return

  --setMotion: (value)=>
    --return if @curMotion == value   --lazy
    --@curMotion = value
    --@applyChange!
    --return


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

--class GamaScene

  --new: (id, sceneData, gamaTilemap)=>
    --assert id, "missing id"
    --assert sceneData, "invalid scene data"
    --assert gamaTilemap.__class == "GamaTilemap", "invalid gama tilemap"

    --@sceneData = sceneData
    --@tilemap = gamaTilemap

export gama

gama =
  VERSION:  "0.1.0"

  getAssetPath: (id)-> "#{id}"

  readJSONAsync: (id, callback)->
    assert id, "missing id"
    assert type(callback) == "function", "invalid callback"
    path =  "#{id}.csx"
    return callback "file:#{path} not found" unless fs\isFileExist path

    status, content = pcall fs.getStringFromFile, fs, path

    return callback "fail to read file:#{path}, error:#{content}" unless status

    status, content = pcall cjson.decode, content

    return callback "fail to decode json from:#{path}, error:#{content}" unless status

    return callback nil, content

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
  --createCharacterWithSprite: (id, gamaFigure, sprite)->
    --assert id
    --assert gamaFigure
    --assert sprite
    --return GamaCharacter(id, gamaFigure, sprite)

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

  -- 根据 character id 来获取 figure
  getByCharacterId:  (id, callback)->
    assert type(callback) == "function", "invalid callback"
    gama.readJSONAsync id, (err, data)->
      return callback err if err
      return callback "invalid character data for id:#{id}" unless data and data.type == "characters" and type(data.figure) == "table"
      -- NOTE: 将所请求的 figure 的 id 重置为 character 的 id
      data.figure.id = id
      gama.figure.getByCSX(data.figure, callback)
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

gama.scene =

  --loadedData: nil

  cleanup:  ->
    SpriteFrameCache\removeUnusedSpriteFrames!
    TextureCache\removeUnusedTextures!
    return

  -- callback signature: callback(err, sceneDataPack)
  --  其中 sceneDataPack 是一个数组，内涵： 1. sceneData, 2. tilemap, ...
  loadById: (id, callback)->

    assert id, "missing scene id"

    assert(type(callback) == "function", "invalid callback")
    print "[gama::scene::loadById] id:#{id}"

    -- 加载场景数据
    gama.readJSONAsync id, (err, sceneData)->
      return callback err if err
      return gama.scene.loadByCSX sceneData, callback


  -- @param {table} data, csx json data
  loadByCSX: (sceneData, callback)->

    assert sceneData and sceneData.type == "scenes", "invalid data type"
    assert type(callback) == "function", "invalid callback"

    print "[gama::scene::loadByCSX]"

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

    sceneData.isMaskedAt = (brickX, brickY)=>
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

    processor = (job, next)->
      asserId, jobType = unpack job

      switch jobType
        when ASSET_TYPE_CHARACTER
          gama.figure.getByCharacterId asserId, next

        when ASSET_TYPE_TILEMAP
          gama.tilemap.getById asserId, next

        when ASSET_TYPE_ANIMATION
          --gama.animation.getById asserId, next
          gama.animation.getById asserId, (err, gamaAnimation)->
            if err
              console.warn "[gama::scene::load animation] skip invalid animation:#{assetId}, error:#{err}"
              err = nil
            return next err, gamaAnimation
        else
          console.error "[gama::scene::loadById::on job] unknown asset type:#{jobType}"

      return

    async.mapSeries jobs, processor, (err, results)->
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



