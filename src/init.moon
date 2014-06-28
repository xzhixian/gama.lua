
printf "[gama] init"

------------ 补丁 : start --------------------

--###
-- 解决 quick-x/framework/functions.lua 中使用 `class` 关键词做方法名，导致 moonscript class() 解析错误的问题
fix = loadstring "function quick_class(classname, super) return class(classname, super) end "
fix!

--###
-- quick-x d的 json 封装无法将错误抛出给应用层面，所以参考 JavaScript 的方式重新封装
export JSON = JSON or {}
cjson = require("cjson")

--- JSON.stringify
-- turn data table into json string
-- @param value , data talbe
-- @param callback, simulate an async call when provide withe a callback,
JSON.stringify = (value, callback)->
  if type(callback) == "function"
    -- simulate async
    status, result = pcall(cjson.encode, var)
    if status
      callback nil, result
    else
      callback "JSON.stringify failed, error:#{result}"
  else
    -- sync call
    return cjson.encode value
  return

--- JSON.parse
-- turn text into data table
JSON.parse = (text, callback)->
  if type(callback) == "function"
    -- simulate async
    status, result = pcall(cjson.decode, text)
    if status
      callback nil, result
    else
      callback "JSON.parse failed, error:#{result}"
  else
    -- sync call
    return cjson.decode(text)
  return

------------ 补丁 : end   --------------------

export gama = gama or {}
gama.VERSION = "0.1.0"
gama.HOST = "gamagama.cn"
--gama.HOST = "localhost:8080"

gama.getAssetUrl = (id)-> "http://#{gama.HOST}/#{id}"

--- getDescUrl
-- this is a temporary solution
-- @param id asset id
-- @return desc json url
gama.getDescUrl = (id)-> "http://#{gama.HOST}/#{id}.json"

--- gama.getAssetInfo
-- load asset information from the server
gama.getAssetInfo = (id, callback)->
  printf "[init::method] #{type(id)}"

  -- make sure callback is supplied
  assert type(callback) == "function", "invalid callback: #{callback}"
  -- make sure id is given
  return callback "invalid id: #{id}" if id == nil or id == ""

  url = gama.getAssetUrl id

  gama.http.getJSON url, (err, data)->
    printf "[init::getAssetInfo] err:#{err}, data:"
    dump data
    return

  return

--###
-- bootstrap modules
-- NOTE: require 的次序不能乱
gama.http = require "gama.http" unless gama.http
gama.animation = require "gama.animation" unless gama.animation




