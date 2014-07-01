local async = require("async")
local sharedTextureCache = CCTextureCache:sharedTextureCache()
local asset = { }
local ROOT_PATH = tostring(device.cachePath) .. "gama" .. tostring(device.directorySeparator)
os.execute("mkdir -p " .. tostring(ROOT_PATH))
device.writablePath = CCFileUtils:sharedFileUtils():addSearchPath(ROOT_PATH)
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
asset.getURLById = function(id)
  return "http://" .. tostring(gama.HOST) .. "/fetch/" .. tostring(id)
end
asset.getPathToFileById = function(id, extname)
  if extname == nil then
    extname = ""
  end
  return tostring(ROOT_PATH) .. tostring(id) .. tostring(extname)
end
asset.fetchById = function(id, extname, callback)
  printf("[asset::fetchById] id:" .. tostring(id))
  if type(extname) == "function" and callback == nil then
    callback = extname
    extname = ""
  end
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  extname = tostring(extname)
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  local destination = asset.getPathToFileById(id, extname)
  if io.exists(destination) then
    return callback(nil, destination)
  end
  local remote = asset.getURLById(id)
  gama.http.download(remote, destination, function(err)
    if err then
      return callback(err)
    end
    return callback(nil, destination)
  end)
end
asset.fetchByIds = function(ids, callback)
  return async.eachSeries(ids, asset.fetchById, callback)
end
asset.readById = function(id, callback)
  printf("[asset::readById] id:" .. tostring(id))
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  asset.fetchById(id, function(err)
    if err then
      return callback(err)
    end
    return callback(nil, io.readfile(asset.getPathToFileById(id)))
  end)
end
asset.getTextureById = function(id, extname, callback)
  printf("[asset::getTextureById] id:" .. tostring(id))
  if type(extname) == "function" and callback == nil then
    callback = extname
    extname = ""
  end
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  extname = tostring(extname)
  local pathToFile = asset.getPathToFileById(id, extname)
  printf("[asset::getTextureById] pathToFile:" .. tostring(pathToFile))
  local texture = sharedTextureCache:textureForKey(pathToFile)
  if texture then
    printf("[asset::getTextureById] texture avilable for id:" .. tostring(id) .. tostring(extname))
    return callback(nil, texture)
  end
  asset.fetchById(id, extname, function(err, pathToFile)
    if err then
      return callback(err)
    end
    display.addImageAsync(pathToFile, function(funcname, texture)
      printf("[asset::getTextureById] texture init:" .. tostring(texture))
      if texture then
        return callback(nil, texture)
      end
      return callback("fail to load texture:" .. tostring(id) .. tostring(extname))
    end)
  end)
end
return asset
