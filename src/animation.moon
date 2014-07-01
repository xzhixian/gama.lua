--- 这个模块：
--  1. 是一个单例
--  2. 对应 gama 网站上的动画功能

animation = {}

DUMMY_CALLBACK = ->

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

    callback nil


  return




return animation


