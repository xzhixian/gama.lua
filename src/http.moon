--- 这个模块：
-- 扩充 Cocos 的 http 功能，提供一系列自动化的操作

http = {}

DUMMY_CALLBACK = -> -- just do nothing

--- getJSON
-- load json from the given url
-- @param url target url
-- @param callback, signature: callback(err, data)
http.getJSON = (url, callback)->
  http.request url, (err, text)->
    return callback err if err and type(callback) == "function"

    JSON.parse text, (err, data)->
      --printf "[http::getJSON] err:#{err}, data:#{data}"
      return callback err if err and type(callback) == "function"
      return callback(nil, data) if type(callback) == "function"

  return

--- request
-- 创建一个异步的HTTP请求，这是对 CCHTTPRequest 的封装，将 callback 后置以利于多级异步调用
-- @param option, 可以是一个字符串 url 。也可以是一个 table。如果是 table 的话，支持： option.url, option.method
-- @param callback, 回调方法
-- @return http request handler
http.request = (option, callback)->

  url = option.url or option

  assert url, "invalid url:#{url}"

  callback = callback or DUMMY_CALLBACK
  assert(type(callback) == "function", "invalid callback:#{callback}")

  method = if(string.upper(option.method or "") == "POST") then kCCHTTPRequestMethodPOST else kCCHTTPRequestMethodGET

  printf "[http::request] method:#{method} url:#{url}"

  callback = callback or DUMMY_CALLBACK

  -- 为当前的调用构建一个闭包
  innerCallback = (event) ->

    printf "[http::response::innerCallback] event:#{event.name}"
    response = event.request  -- NOTE: event.request 明明是一个 response 对象啊！

    statusCode = if event.name == "failed" then -1 else response\getResponseStatusCode!

    printf "[http::response::innerCallback] event:#{event.name}, status:#{statusCode}"

    if event and event.name == "completed" -- http response completed
      if statusCode == 200  -- server returns OK
        callback(nil, response\getResponseData!)
      else                  -- server says not good
        callback "bad server response. status:#{statusCode}"
    else
      callback "http request failed. error(#{response\getErrorCode!}) : #{response\getErrorMessage!}"
    return

  req = CCHTTPRequest\createWithUrl(innerCallback, url, method)
  if req then
    req\setTimeout(option.waittime or  30)
    req\start!
  else
    callback "fail to init http request"

  return


return http


