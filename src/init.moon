
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

gama.animation = require "framework.gama.animation" unless gama.animation



