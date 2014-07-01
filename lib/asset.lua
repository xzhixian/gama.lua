local async = require("async")
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
return asset
