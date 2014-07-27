
async = require "async"

print "[gama] init"

SpriteFrameCache = cc.SpriteFrameCache\getInstance!
TextureCache = cc.Director\getInstance!\getTextureCache!
AnimationCache = cc.AnimationCache\getInstance!

fs = cc.FileUtils\getInstance!
fs\addSearchPath "gama/"

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

TEXTURE_FIELD_ID = "png_8bit"

SPF = 1 / 15

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
    --gamaFigure\setDefaultMotion "idl"
    --gamaFigure\setDefaultDirection "s"

    @curDirection = "s"
    @curMotion = "idl"
    @applyChange!

  getId: => @id

  applyChange: => @figure\playOnSprite @sprite, @curMotion, @curDirection

  setDirection: (value)=>
    @curDirection = value
    @applyChange!
    return

  setMotion: (value)=>
    @curMotion = value
    @applyChange!
    return

export gama

gama =
  VERSION:  "0.1.0"

  getAssetPath: (id)-> "assets/#{id}"

  readJSON: (id)->
    path =  "assets/#{id}.csx"
    print "[gama::readJSON] path:#{path}"

    unless fs\isFileExist path
      print "[gama::readJSON] file not found:#{path}"
      return nil

    content = fs\getStringFromFile path

    -- TODO: use sting.match
    return json.decode content

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

    texture = TextureCache\addImage pathToFile

    return callback(nil, texture)

  -- 分析 csx json，从里面拉出来 texture id，然后在内存中载入所有所需要的 Texture2D
  getFromJSON: (data, callback)->

    -- work out required texture ids
    textureIds = (data.texture or EMPTY_TABLE)[TEXTURE_FIELD_ID]

    textureIds = {textureIds} if type(textureIds) == "string"

    return callback "invalid textureIds:#{textureIds}, field:#{TEXTURE_FIELD_ID}" unless type(textureIds) == "table" and #textureIds > 0

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

  -- @param {function} callback, signature: callback(err, gamaAnimation)
  getById:  (id, callback)->

    print "[gama::animation::getById] id:#{id}"

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    data = gama.readJSON id

    return callback "fail to parse json data from id:#{id}" unless data

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


gama.figure =

  -- @param {function} callback, signature: callback(err, gamaTilemap)
  getById:  (id, callback)->

    print "[gama::tilemap::getById] id:#{id}"

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    data = gama.readJSON id
    return callback "fail to parse json data from id:#{id}" unless data

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




