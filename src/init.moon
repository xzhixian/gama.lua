
print "[gama] init"

spriteFrameCache = cc.SpriteFrameCache\getInstance!

fs = cc.FileUtils\getInstance!
fs\addSearchPath "gama/"

-- key: asset id
-- value: asset type
ASSET_ID_TO_TYPE_KV = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXTURE_FIELD_ID = "png8"

------------ 补丁 : start --------------------
export gama = gama or {}
gama.VERSION = "0.1.0"

gama.getAssetPath = (id)-> "assets/#{id}"

-- return the asset type of given asset id
-- @param id
-- @return asset type, or nil
gama.getTypeById = (id)->
  id = tostring(id)

  type = ASSET_ID_TO_TYPE_KV[id]
  return type if type

  path = gama.getAssetPath id

  return nil unless fs\isFileExist path

  content = fs\getStringFromFile path

  -- TODO: use sting.match
  obj = json.decode content
  assetType = obj["type"]
  ASSET_ID_TO_TYPE_KV[id] = assetType
  return assetType


gama.animation = {}

gama.animation.getById = (id, callback)->

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")






