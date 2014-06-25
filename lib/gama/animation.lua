local animation = { }
animation.loadById = function(id, callback)
  return assert(id, "invalid id:" .. tostring(id))
end
return animation
