print("[gama] init")
local fs = cc.FileUtils:getInstance()
fs:addSearchPath("gama/")
local ASSET_ID_TO_TYPE_KV = { }
gama = gama or { }
gama.VERSION = "0.1.0"
gama.HOST = "gamagama.cn"
gama.getTypeById = function(id)
  id = tostring(id)
  local type = ASSET_ID_TO_TYPE_KV[id]
  if type then
    return type
  end
  local path = "assets/" .. tostring(id)
  if not (fs:isFileExist(path)) then
    return nil
  end
  local content = fs:getStringFromFile(path)
  local obj = json.decode(content)
  local assetType = obj["type"]
  ASSET_ID_TO_TYPE_KV[id] = assetType
  return assetType
end
