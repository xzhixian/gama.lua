--- 这个模块：
-- 对接 gama 的 asset 素材池

async = require "async"

asset = {}

-- crate local assets directory
-- use cache path to avoid iOS cloud backup
ROOT_PATH = "#{device.cachePath}assets#{device.directorySeparator}"
os.execute "mkdir -p #{ROOT_PATH}"
device.writablePath = CCFileUtils\sharedFileUtils!\addSearchPath ROOT_PATH

DUMMY_CALLBACK = -> -- just do nothing

asset.getURLById = (id)-> "http://#{gama.HOST}/fetch/#{id}"

--- fetchById
-- 根据给定的 id 从远程服务器上拉回来素材，如果本地已经存在德话就不拉了
-- @param id, asset id
-- @param callback, signature: callback(err, filename)
asset.fetchById = (id, callback)->

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  remote = getURLById(id)
  destination = "#{ROOT_PATH}#{id}"

  gama.http.download remote, destination, (err)->
    return callback err if err

  return

asset.fetchByIds = (ids, callback)-> async.eachSeries ids, asset.fetchById, callback

return asset



