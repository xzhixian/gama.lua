local async = require("async")
local asset = { }
local ROOT_PATH = tostring(device.cachePath) .. "assets" .. tostring(device.directorySeparator)
os.execute("mkdir -p " .. tostring(ROOT_PATH))
device.writablePath = CCFileUtils:sharedFileUtils():addSearchPath(ROOT_PATH)
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
asset.getURLById = function(id)
  return "http://" .. tostring(gama.HOST) .. "/fetch/" .. tostring(id)
end
asset.fetchById = function(id, callback)
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  local remote = getURLById(id)
  local destination = tostring(ROOT_PATH) .. tostring(id)
  gama.http.download(remote, destination, function(err)
    if err then
      return callback(err)
    end
  end)
end
asset.fetchByIds = function(ids, callback)
  return async.eachSeries(ids, asset.fetchById, callback)
end
return asset
