
print "[gama] init"

fs = cc.FileUtils\getInstance!
fs\addSearchPath "gama/"

-- key: asset id
-- value: asset type
ASSET_ID_TO_TYPE_KV = {}


------------ 补丁 : start --------------------
export gama = gama or {}
gama.VERSION = "0.1.0"
gama.HOST = "gamagama.cn"


-- return the asset type of given asset id
-- @param id
-- @return asset type, or nil
gama.getTypeById = (id)->
  id = tostring(id)

  type = ASSET_ID_TO_TYPE_KV[id]
  return type if type

  path = "assets/#{id}"

  return nil unless fs\isFileExist path

  content = fs\getStringFromFile path

  -- TODO: use sting.match
  obj = json.decode content
  assetType = obj["type"]
  ASSET_ID_TO_TYPE_KV[id] = assetType
  return assetType

--###
-- bootstrap modules
-- NOTE: require 的次序不能乱
--gama.http = require "http" unless gama.http
--gama.asset = require "asset" unless gama.asset
--gama.animation = require "animation" unless gama.animation




