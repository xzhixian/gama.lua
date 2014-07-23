
async = require "async"

print "[gama] init"

SpriteFrameCache = cc.SpriteFrameCache\getInstance!
TextureCache = cc.Director\getInstance!\getTextureCache!

fs = cc.FileUtils\getInstance!
fs\addSearchPath "gama/"

-- key: asset id
-- value: asset type
ASSET_ID_TO_TYPE_KV = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXTURE_FIELD_ID = "png_8bit"

SPF = 0.3 / 8

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


gama.asset =

  --- getTextureById
  -- 获取纹理
  -- @param id asset id
  -- @param extname
  -- @param callback , signature: callback(err, texture2D)
  getTextureById: (id, callback)->

    print "[asset::getTextureById] id:#{id}"

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    pathToFile = gama.getAssetPath id

    print "[asset::getTextureById] pathToFile:#{pathToFile}"

    texture = TextureCache\getTextureForKey(pathToFile)

    -- require texture is avilable
    if texture
      print "[asset::getTextureById] texture avilable for id:#{id}#{extname}"
      return  callback(nil, texture)

    return callback "missing file at:#{pathToFile}" unless fs\isFileExist pathToFile

    texture = TextureCache\addImage pathToFile
    print "[asset::getTextureById] texture:#{texture}"

    return callback(nil, texture)

gama.animation =

  -- @param {function} callback, signature: callback(err, animation)
  getById:  (id, callback)->

    -- make sure callback is firable
    callback = callback or DUMMY_CALLBACK
    assert(type(callback) == "function", "invalid callback: #{callback}")

    data = gama.readJSON id

    return callback "fail to parse json data from id:#{id}" unless data

    -- work out required texture ids
    textureIds = (data.texture or EMPTY_TABLE)[TEXTURE_FIELD_ID]

    textureIds = {textureIds} if type(textureIds) == "string"

    unless type(textureIds) == "table" and #textureIds > 0
      return callback "invalid textureIds:#{textureIds}, field:#{TEXTURE_FIELD_ID}"

    -- fetch texture assets
    processTexture = (textureId, next)->

      gama.asset.getTextureById textureId, (err, texture2D)->
        return next err if err
        print "[animation::loadById] texture2D:#{texture2D}"
        return next(nil, texture2D)

    -- 根据 textureIds 准备好 texture2D 实例
    async.mapSeries textureIds, processTexture, (err, texture2Ds)->
      return callback err if err

      --print "[animation::loadById] after texture processed, texture2Ds:"
      --dump texture2Ds

      assetFrames = gama.animation.makeSpriteFrames(id, texture2Ds, data.atlas, data.playback)

      animation = cc.Animation\createWithSpriteFrames(assetFrames, SPF)

      callback nil, {animation, data, texture2Ds}

    return


  -- 根据给定的 texture , arrangement 生产出 sprite frame
  -- @return frames[]
  makeSpriteFrames: (assetId, textures, arrangement, playscript)->

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

        frame = cc.SpriteFrame\createWithTexture(texture, cc.rect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h))

        -- push the frame into cache
        SpriteFrameCache\addSpriteFrame frame, frameName

        table.insert assetFrames, frame

    return assetFrames
