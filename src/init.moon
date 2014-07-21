
print "[gama] init"

------------ 补丁 : start --------------------
export gama = gama or {}
gama.VERSION = "0.1.0"
gama.HOST = "gamagama.cn"

--###
-- bootstrap modules
-- NOTE: require 的次序不能乱
gama.http = require "http" unless gama.http
gama.asset = require "asset" unless gama.asset
gama.animation = require "animation" unless gama.animation




