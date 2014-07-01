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
asset.getPathToFileById = function(id)
  return tostring(ROOT_PATH) .. tostring(id)
end
asset.fetchById = function(id, callback)
  printf("[asset::fetchById] id:" .. tostring(id))
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  local destination = asset.getPathToFileById(id)
  if io.exists(destination) then
    return callback(nil, id)
  end
  local remote = asset.getURLById(id)
  gama.http.download(remote, destination, function(err)
    if err then
      return callback(err)
    end
    return callback(nil, id)
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
