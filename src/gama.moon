
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
class GamaAnimation
  -- 构造函数
  -- @param texture cc.Texture2D
  -- @param ccAnimation cc.Animation
  new: (texture, ccAnimation)=>
    @texture = texture
    @ccAnimation = ccAnimation

  -- play this animation on the given sprite
  -- @param sprite  cc.Sprite
  playOnSprite: (sprite)=>
    animate = cc.Animate\create @ccAnimation
    action = cc.RepeatForever\create(animate)
    sprite\runAction(action)
    return


------------ 补丁 : start --------------------
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
        assetFrames = gama.animation.makeSpriteFrames(id, texture2Ds[1], data.atlas)
        playframes = {}
        for assetId in *data.playframes
          table.insert(playframes, (assetFrames[assetId + 1] or assetFrames[1]))
        animation = cc.Animation\createWithSpriteFrames(playframes, SPF)
        AnimationCache\addAnimation(animation, id)  -- 加入到缓存，避免再次计算

      gamaAnimation = GamaAnimation(texture2Ds[1], animation)

      callback nil, gamaAnimation

    return


  -- 根据给定的 texture , arrangement 生产出 sprite frame
  -- @return frames[]
  makeSpriteFrames: (assetId, texture, arrangement)->

    count = 1

    assetFrames = {}

    for frameInfo in *arrangement

      frameName = "#{assetId}/#{count}"
      count += 1

      frame = SpriteFrameCache\getSpriteFrame(frameName)

      if frame
        --print "[animation::buildSpriteFrameCache] find frame in cache, asset frame name: #{frameName}"
        table.insert assetFrames, frame

      else
        --print "[animation::buildSpriteFrameCache] build up from json, asset frame name: #{frameName}"
        rect = cc.rect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h)

        frame = cc.SpriteFrame\createWithTexture(texture, rect)
        frame\setOriginalSizeInPixels(cc.size(512, 512))
        frame\setOffset(cc.p(frameInfo.ox, frameInfo.oy))
        -- push the frame into cache
        SpriteFrameCache\addSpriteFrame frame, frameName

        table.insert assetFrames, frame

    return assetFrames



gama.tilemap =

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

    return




