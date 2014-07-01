
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

    printf "[init::JSON::parse] status:#{status}, result:#{result}"

    if status
      callback(nil, result)
    else
      callback "JSON.parse failed, error:#{result}"
  else
    -- sync call
    return cjson.decode(text)
  return

------------ 补丁 : end   --------------------

export gama = gama or {}
gama.VERSION = "0.1.0"
--gama.HOST = "gamagama.cn"
gama.HOST = "127.0.0.1:8080"

--###
-- bootstrap modules
-- NOTE: require 的次序不能乱
gama.http = require "gama.http" unless gama.http
gama.asset = require "gama.asset" unless gama.asset
gama.animation = require "gama.animation" unless gama.animation




