--- 这个模块：
-- 对接 gama 的 asset 素材池

async = require "async"

asset = {}

-- crate local assets directory
-- use cache path to avoid iOS cloud backup
ROOT_PATH = "#{device.cachePath}gama#{device.directorySeparator}"
os.execute "mkdir -p #{ROOT_PATH}"
device.writablePath = CCFileUtils\sharedFileUtils!\addSearchPath ROOT_PATH

DUMMY_CALLBACK = -> -- just do nothing

asset.getURLById = (id)-> "http://#{gama.HOST}/fetch/#{id}"

asset.getPathToFileById = (id)-> "#{ROOT_PATH}#{id}"

--- fetchById
-- 根据给定的 id 从远程服务器上拉回来素材，如果本地已经存在德话就不拉了
-- @param id, asset id
-- @param callback, signature: callback(err, assetId)
asset.fetchById = (id, callback)->

  printf "[asset::fetchById] id:#{id}"

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  destination = asset.getPathToFileById id

  -- required file already exists in local
  return callback nil, id if io.exists(destination)

  remote = asset.getURLById(id)

  gama.http.download remote, destination, (err)->
    return callback err if err

    -- remote file downloaded
    return callback nil, id

  return

--- fetchByIds
-- 批量将给定的 id 列表中的 asset 下载到本地
asset.fetchByIds = (ids, callback)-> async.eachSeries ids, asset.fetchById, callback

--- readById
-- 读出给定的 id 的 asset 的内容
-- @param id, asset id
-- @param callback, signature: callback(err, content:String)
asset.readById = (id, callback)->

  printf "[asset::readById] id:#{id}"

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  asset.fetchById id, (err)->
    return callback err if err
    return callback nil, io.readfile(asset.getPathToFileById(id))

  return


return asset



