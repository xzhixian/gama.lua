--- 这个模块：
-- 对接 gama 的 asset 素材池

async = require "async"
sharedTextureCache = CCTextureCache\sharedTextureCache!

asset = {}

-- crate local assets directory
-- use cache path to avoid iOS cloud backup
ROOT_PATH = "#{device.cachePath}gama#{device.directorySeparator}"
os.execute "mkdir -p #{ROOT_PATH}"
device.writablePath = CCFileUtils\sharedFileUtils!\addSearchPath ROOT_PATH

DUMMY_CALLBACK = -> -- just do nothing

asset.getURLById = (id)-> "http://#{gama.HOST}/fetch/#{id}"

asset.getPathToFileById = (id, extname = "")-> "#{ROOT_PATH}#{id}#{extname}"

--- fetchById
-- 根据给定的 id 从远程服务器上拉回来素材，如果本地已经存在德话就不拉了
-- @param id, asset id
-- @param extname , extension name 由于 cocos2dx 的 addImageAsync 是根据文件后缀名来判断数据类型，因此在这里先补上后缀名
-- @param callback, signature: callback(err, pathToFile)
asset.fetchById = (id, extname, callback)->

  console.log "[asset::fetchById] id:#{id}"

  if type(extname) == "function" and callback == nil
    callback = extname
    extname = ""

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  extname = "#{extname}"

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  destination = asset.getPathToFileById id, extname

  -- required file already exists in local
  return callback nil, destination if io.exists(destination)

  remote = asset.getURLById(id)

  gama.http.download remote, destination, (err)->
    return callback err if err

    -- remote file downloaded
    return callback nil, destination

  return

--- fetchByIds
-- 批量将给定的 id 列表中的 asset 下载到本地
asset.fetchByIds = (ids, callback)-> async.eachSeries ids, asset.fetchById, callback

--- readById
-- 读出给定的 id 的 asset 的内容
-- @param id, asset id
-- @param callback, signature: callback(err, content:String)
asset.readById = (id, callback)->

  console.log "[asset::readById] id:#{id}"

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  asset.fetchById id, (err)->
    return callback err if err
    return callback nil, io.readfile(asset.getPathToFileById(id))

  return

--- getTextureById
-- 获取纹理
-- @param id asset id
-- @param extname
-- @param callback , signature: callback(err, texture2D)
asset.getTextureById = (id, extname, callback)->

  console.log "[asset::getTextureById] id:#{id}"

  if type(extname) == "function" and callback == nil
    callback = extname
    extname = ""

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  extname = "#{extname}"

  pathToFile = asset.getPathToFileById id, extname

  console.log "[asset::getTextureById] pathToFile:#{pathToFile}"

  texture = sharedTextureCache\textureForKey(pathToFile)

  -- require texture is avilable
  if texture
    console.log "[asset::getTextureById] texture avilable for id:#{id}#{extname}"
    return  callback(nil, texture)

  -- fetch the asset from remote server
  asset.fetchById id, extname, (err, pathToFile)->
    return callback err if err

    display.addImageAsync pathToFile, (funcname, texture)->
      console.log "[asset::getTextureById] texture init:#{texture}"

      return callback(nil, texture) if texture

      return callback "fail to load texture:#{id}#{extname}"

    return

  return

return asset

