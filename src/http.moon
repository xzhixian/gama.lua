--- 这个模块：
-- 扩充 Cocos 的 http 功能，提供一系列自动化的操作

http = {}

DUMMY_CALLBACK = -> -- just do nothing

--- getJSON
-- load json from the given url
-- @param url target url
-- @param callback
http.getJSON = (url, callback)->

  return

--- request
-- 创建一个异步的HTTP请求，这是对 CCHTTPRequest 的封装，将 callback 后置以利于多级异步调用
-- @param option, 可以是一个字符串 url 。也可以是一个 table。如果是 table 的话，支持： option.url, option.method
-- @param callback, 回调方法
-- @return http request handler
http.request = (option, callback)->

  url = option.url or option

  assert url, "invalid url"

  method = if(string.upper(option.method or "") == "GET") then kCCHTTPRequestMethodGET else kCCHTTPRequestMethodPOST

  callback = callback or DUMMY_CALLBACK


  innerCallback = (event, index, dumpResponse) ->
    printf "[http::innerCallback] index:#{index}  event:"
    dump event
    return

  return CCHTTPRequest\createWithUrl(callback, url, method)


return http


