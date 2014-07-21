__DEFINED = __DEFINED or {
  __get = function(id)
    assert(id, "__DEFINED.__get() failed. invalid id:"..tostring(id))
    assert(__DEFINED and __DEFINED[id], "__DEFINED.__get() failed. missing module:"..tostring(id))
    return __DEFINED[id]
  end
}


---------------------------------------


__DEFINED["underscore"] = (function()
undefined
end)()

---------------------------------------


__DEFINED["async"] = (function()
undefined
end)()

---------------------------------------


__DEFINED["animation"] = (function()
local async = __DEFINED.__get("async")
local _ = __DEFINED.__get("underscore")
local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()
local animation = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
local EMPTY_TABLE = { }
local EXTNAME = ".png"
local TEXT_FIELD_ID = "png8"
animation.loadById = function(id, callback)
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  gama.asset.readById(id, function(err, text)
    if err then
      return callback(err)
    end
    JSON.parse(text, function(err, data)
      local textureIds = (data["texture"] or EMPTY_TABLE)[TEXT_FIELD_ID]
      if not (type(textureIds) == "table" and #textureIds > 0) then
        return callback("invalid textureIds:" .. tostring(textureIds) .. ", field:" .. tostring(TEXT_FIELD_ID))
      end
      local processTexture
      processTexture = function(textureId, next)
        return gama.asset.getTextureById(textureId, EXTNAME, function(err, texture2D)
          if err then
            return next(err)
          end
          printf("[animation::loadById] texture2D:" .. tostring(texture2D))
          return next(nil, texture2D)
        end)
      end
      async.mapSeries(textureIds, processTexture, function(err, texture2Ds)
        if err then
          return callback(err)
        end
        local frames = animation.makeSpriteFrames(id, texture2Ds, data["arrangment"], animation.parsePlayScript(data.playscript))
        animation = display.newAnimation(frames, 0.3 / 8)
        return callback(nil, {
          animation,
          data,
          texture2Ds
        })
      end)
    end)
  end)
end
animation.parsePlayScript = function(playscript)
  if not (type(playscript) == "string") then
    return nil
  end
  local result = string.split(playscript, ",")
  return _.map(result, function(i)
    return (tonumber(i) or 0) + 1
  end)
end
animation.makeSpriteFrames = function(assetId, textures, arrangement, playscript)
  local count = 1
  local assetFrames = _.map(arrangement, function(frameInfo)
    local frameName = tostring(assetId) .. "/" .. tostring(count)
    count = count + 1
    printf("[animation::buildSpriteFrameCache] frameName:" .. tostring(frameName))
    local frame = sharedSpriteFrameCache:spriteFrameByName(frameName)
    if frame then
      printf("[animation::buildSpriteFrameCache] find frame in cache")
      return frame
    else
      printf("[animation::buildSpriteFrameCache] build up from json frameInfo:")
      local texture = textures[frameInfo.texture + 1]
      printf("[animation::buildSpriteFrameCache] texture:" .. tostring(texture))
      frame = CCSpriteFrame:createWithTexture(texture, CCRect(frameInfo.l, frameInfo.t, frameInfo.w, frameInfo.h))
      sharedSpriteFrameCache:addSpriteFrame(frame, frameName)
      return frame
    end
  end)
  if not (type(playscript) == "table" and #playscript > 0) then
    return assetFrames
  end
  local playFrames = { }
  for i, assetFrameId in ipairs(playscript) do
    table.insert(playFrames, assetFrames[assetFrameId])
  end
  return playFrames
end
return animation

end)()

---------------------------------------


__DEFINED["asset"] = (function()
local async = __DEFINED.__get("async")
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

end)()

---------------------------------------


__DEFINED["http"] = (function()
local http = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
http.getJSON = function(url, callback)
  http.request(url, function(err, text)
    if err and type(callback) == "function" then
      return callback(err)
    end
    return JSON.parse(text, function(err, data)
      if err and type(callback) == "function" then
        return callback(err)
      end
      if type(callback) == "function" then
        return callback(nil, data)
      end
    end)
  end)
end
http.request = function(option, callback)
  local url = option.url or option
  assert(url, "invalid url:" .. tostring(url))
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback:" .. tostring(callback))
  local method
  if (string.upper(option.method or "") == "POST") then
    method = kCCHTTPRequestMethodPOST
  else
    method = kCCHTTPRequestMethodGET
  end
  printf("[http::request] method:" .. tostring(method) .. " url:" .. tostring(url))
  callback = callback or DUMMY_CALLBACK
  local innerCallback
  innerCallback = function(event)
    printf("[http::response::innerCallback] event:" .. tostring(event.name))
    local response = event.request
    local statusCode
    if event.name == "failed" then
      statusCode = -1
    else
      statusCode = response:getResponseStatusCode()
    end
    printf("[http::response::innerCallback] event:" .. tostring(event.name) .. ", status:" .. tostring(statusCode))
    if event and event.name == "completed" then
      if statusCode == 200 then
        callback(nil, response:getResponseData())
      else
        callback("bad server response. status:" .. tostring(statusCode))
      end
    else
      callback("http request failed. error(" .. tostring(response:getErrorCode()) .. ") : " .. tostring(response:getErrorMessage()))
    end
  end
  local req = CCHTTPRequest:createWithUrl(innerCallback, url, method)
  if req then
    req:setTimeout(option.waittime or 30)
    req:start()
  else
    callback("fail to init http request")
  end
end
http.download = function(url, saveTo, callback)
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback:" .. tostring(callback))
  http.request(url, function(err, data)
    if err then
      return callback(err)
    end
    if io.writefile(saveTo, data) then
      return callback(nil)
    else
      return callback("http.download fail to open file for writing. url:" .. tostring(url))
    end
  end)
end
return http

end)()

---------------------------------------


print("[gama] init")
gama = gama or { }
gama.VERSION = "0.1.0"
gama.HOST = "gamagama.cn"
if not (gama.http) then
  gama.http = __DEFINED.__get("http")
end
if not (gama.asset) then
  gama.asset = __DEFINED.__get("asset")
end
if not (gama.animation) then
  gama.animation = __DEFINED.__get("animation")
end
