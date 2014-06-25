
printf "[init::gama]"

fix = loadstring "function quick_class(classname, super) return class(classname, super) end "
fix!

export gama = gama or {}
gama.VERSION = "0.1.0"
--gama.HOST = "gamagama.cn"
gama.HOST = "localhost:8080"

gama.getAssetUrl = (id)-> "http://#{gama.HOST}/#{id}"

--- getDescUrl
-- this is a temporary solution
-- @param id asset id
-- @return desc json url
gama.getDescUrl = (id)-> "http://#{gama.HOST}/#{id}.json"

gama.animation = require "gama.animation" unless gama.animation



