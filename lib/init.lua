print("[gama] init")
gama = gama or { }
gama.VERSION = "0.1.0"
gama.HOST = "gamagama.cn"
if not (gama.http) then
  gama.http = require("http")
end
if not (gama.asset) then
  gama.asset = require("asset")
end
if not (gama.animation) then
  gama.animation = require("animation")
end
