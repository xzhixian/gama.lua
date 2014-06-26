local http = { }
local DUMMY_CALLBACK
DUMMY_CALLBACK = function() end
http.getJSON = function(url, callback) end
http.request = function(option, callback)
  local url = option.url or option
  assert(url, "invalid url")
  local method
  if (string.upper(option.method or "") == "GET") then
    method = kCCHTTPRequestMethodGET
  else
    method = kCCHTTPRequestMethodPOST
  end
  callback = callback or DUMMY_CALLBACK
  local innerCallback
  innerCallback = function(event, index, dumpResponse)
    printf("[http::innerCallback] index:" .. tostring(index) .. "  event:")
    dump(event)
  end
  return CCHTTPRequest:createWithUrl(callback, url, method)
end
return http
