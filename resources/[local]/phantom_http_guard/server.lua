-- screencapture owns SetHttpHandler; dashboard routes are proxied there.
CreateThread(function()
  Wait(2000)
  print('[phantom_http_guard] dashboard HTTP is proxied via screencapture (/phantom-dashboard/*)')
end)
