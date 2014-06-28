local http = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
http.getJSON = function(url, callback)
  http.request(url, function(err, text)
    if err and type(callback) == "function" then
      return callback(err)
    end
    return JSON.parse(text, function(err, data)
      if err and type(callback) == "function" then
        return callback(err)
      end
      if type(callback) == "function" then
        return callback(nil, data)
      end
    end)
  end)
end
http.request = function(option, callback)
  local url = option.url or option
  assert(url, "invalid url")
  local method
  if (string.upper(option.method or "") == "POST") then
    method = kCCHTTPRequestMethodPOST
  else
    method = kCCHTTPRequestMethodGET
  end
  printf("[http::request] method:" .. tostring(method) .. " url:" .. tostring(url))
  callback = callback or DUMMY_CALLBACK
  local innerCallback
  innerCallback = function(event)
    local response = event.request
    local statusCode = response:getResponseStatusCode()
    printf("[http::response::innerCallback] event:" .. tostring(event.name) .. ", status:" .. tostring(statusCode))
    if event and event.name == "completed" then
      if statusCode == 200 then
        if type(callback) == "function" then
          callback(nil, response:getResponseData())
        end
      else
        if type(callback) == "function" then
          callback("bad server response. status:" .. tostring(statusCode))
        end
      end
    else
      if type(callback) == "function" then
        callback("http request failed. error(" .. tostring(response:getErrorCode()) .. ") : " .. tostring(request:getErrorMessage()))
      end
    end
  end
  local req = CCHTTPRequest:createWithUrl(innerCallback, url, method)
  if req then
    req:setTimeout(option.waittime or 30)
    req:start()
  else
    if callback then
      callback("fail to init http request")
    end
  end
end
return http
