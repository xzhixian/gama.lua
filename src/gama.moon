
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
ASSET_ID_TO_ANIMATION_KV = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXTURE_FIELD_ID = "png_8bit"

SPF = 1 / 15


class GamaAnimation
  new: (texture, ccAnimation)=>
    @texture = texture
    @ccAnimation = ccAnimation

  playOnSprite: (target)=>
    animate = cc.Animate\create @ccAnimation
    action = cc.RepeatForever\create(animate)
    target\runAction(action)
    return

  createSprite: =>
    sprite = cc.Sprite\createWithTexture @texture
    return sprite


------------ 补丁 : start --------------------
export gama = gama or {}
gama.VERSION = "0.1.0"

gama.getAssetPath = (id)-> "assets/#{id}"

gama.readJSON = (id)->
  path = gama.getAssetPath id
  return nil unless fs\isFileExist path

  content = fs\getStringFromFile path

  -- TODO: use sting.match
  return json.decode content

-- return the asset type of given asset id
-- @param id
-- @return asset type, or nil
gama.getTypeById = (id)->

  type = ASSET_ID_TO_TYPE_KV[id]
  return type if type

  obj = gama.readJSON id
  return nil unless obj

  return obj["type"]


--- getTextureById
-- 获取纹理
-- @param id asset id
-- @param extname
-- @param callback , signature: callback(err, texture2D)
gama.getTextureById = (id, callback)->

  print "[gama::getTextureById] id:#{id}"

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  pathToFile = gama.getAssetPath id

  print "[gama::getTextureById] pathToFile:#{pathToFile}"

  texture = TextureCache\getTextureForKey(pathToFile)

  -- require texture is avilable
  if texture
    print "[gama::getTextureById] texture avilable for id:#{id}#{extname}"
    return  callback(nil, texture)

  return callback "missing file at:#{pathToFile}" unless fs\isFileExist pathToFile

  texture = TextureCache\addImage pathToFile
  print "[gama::getTextureById] texture:#{texture}"

  return callback(nil, texture)

gama.animation =

  -- @param {function} callback, signature: callback(err, gamaAnimation)
  getById:  (id, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    if ASSET_ID_TO_ANIMATION_KV[id]
      print "[gama::animation::getById] found in lua cache:#{id}"
      return callback nil, ASSET_ID_TO_ANIMATION_KV[id]

    data = gama.readJSON id

    return callback "fail to parse json data from id:#{id}" unless data

    -- work out required texture ids
    textureIds = (data.texture or EMPTY_TABLE)[TEXTURE_FIELD_ID]

    textureIds = {textureIds} if type(textureIds) == "string"

    unless type(textureIds) == "table" and #textureIds > 0
      return callback "invalid textureIds:#{textureIds}, field:#{TEXTURE_FIELD_ID}"

    -- 根据 textureIds 准备好 texture2D 实例
    async.mapSeries textureIds, gama.getTextureById, (err, texture2Ds)->
      return callback err if err

      animation = AnimationCache\getAnimation id   -- 先到缓存里面找

      unless animation
        assetFrames = gama.animation.makeSpriteFrames(id, texture2Ds, data.atlas, data.playback)
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
  makeSpriteFrames: (assetId, textures, arrangement)->

    count = 1

    assetFrames = {}

    texture = textures[1]

    for frameInfo in *arrangement

    --assetFrames = _.map arrangement, (frameInfo)->

      frameName = "#{assetId}/#{count}"
      count += 1

      frame = SpriteFrameCache\getSpriteFrame(frameName)

      if frame
        print "[animation::buildSpriteFrameCache] find frame in cache, asset frame name: #{frameName}"
        table.insert assetFrames, frame

      else

        print "[animation::buildSpriteFrameCache] build up from json, asset frame name: #{frameName}"

        rect = cc.rect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h)

        frame = cc.SpriteFrame\createWithTexture(texture, rect)
        frame\setOriginalSizeInPixels(cc.size(512, 512))
        frame\setOffset(cc.p(frameInfo.ox, frameInfo.oy))
        -- push the frame into cache
        SpriteFrameCache\addSpriteFrame frame, frameName

        table.insert assetFrames, frame

    return assetFrames

