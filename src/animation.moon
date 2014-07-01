--- 这个模块：
--  1. 是一个单例
--  2. 对应 gama 网站上的动画功能

async = require "async"

animation = {}

DUMMY_CALLBACK = ->

EMPTY_TABLE = {}

TEXT_FIELD_ID = switch device.platform
  when "android"
    "pkm"
  when "ios"
    "pvrct4"
  else
    "png8"

--- loadById
--
-- @param id asset id
-- @param callback, callback method, signature: callback(err, animation)
animation.loadById = (id, callback)->

  -- make sure callback is firable
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: #{callback}")

  id = string.trim("#{id or ""}")
  return callback "missing id" if id == ""

  url = gama.getDescUrl id

  printf "[animation::loadById] url:#{url}"

  gama.http.getJSON url, (err, data)->
    return callback err if err

    printf "[animation::loadById] data:"
    dump data

    -- work out required texture ids
    textureIds = (data["texture"] or EMPTY_TABLE)[TEXT_FIELD_ID]

    unless type(textureIds) == table and #textureIds > 0
      return callback "invalid textureIds:#{textureIds}, field:#{TEXT_FIELD_ID}"

    -- fetch texture assets


    -- load into texture cache

    callback nil


  return




return animation


