local animation = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
animation.loadById = function(id, callback)
  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback: " .. tostring(callback))
  id = string.trim(tostring(id or ""))
  if id == "" then
    return callback("missing id")
  end
  local url = gama.getDescUrl(id)
  printf("[animation::loadById] url:" .. tostring(url))
  gama.http.getJSON(url, function(err, data)
    if err then
      return callback(err)
    end
    printf("[animation::loadById] data:")
    dump(data)
    return callback(nil)
  end)
end
return animation
