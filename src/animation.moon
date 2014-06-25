--- 这个模块：
--  1. 是一个单例
--  2. 对应 gama 网站上的动画功能

animation = {}


--- loadById
--
-- @param id asset id
-- @param callback, callback method, signature: callback(err, animation)
animation.loadById = (id, callback)->
  assert id, "invalid id:#{id}"




return animation


