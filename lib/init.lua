print("[gama] init")
local spriteFrameCache = cc.SpriteFrameCache:getInstance()
local fs = cc.FileUtils:getInstance()
fs:addSearchPath("gama/")
local ASSET_ID_TO_TYPE_KV = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local TEXTURE_FIELD_ID = "png8"
gama = gama or { }
gama.VERSION = "0.1.0"
gama.getAssetPath = function(id)
  return "assets/" .. tostring(id)
end
gama.getTypeById = function(id)
  id = tostring(id)
  local type = ASSET_ID_TO_TYPE_KV[id]
  if type then
    return type
  end
  local path = gama.getAssetPath(id)
  if not (fs:isFileExist(path)) then
    return nil
  end
  local content = fs:getStringFromFile(path)
  local obj = json.decode(content)
  local assetType = obj["type"]
  ASSET_ID_TO_TYPE_KV[id] = assetType
  return assetType
end
gama.animation = { }
gama.animation.getById = function(id, callback)
  callback = callback or DUMMY_CALLBACK
  return assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
end
