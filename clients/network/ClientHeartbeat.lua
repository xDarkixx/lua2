-- BULDACITY client heartbeat service
local event=require("event")
local Network=require("network-modern.Network")
local Config=require("clients.Config")
local M={timer=nil}

function M.start(interval)
  interval=interval or Config.heartbeatInterval
  if M.timer then return true end
  M.timer=event.timer(interval,function()
    Network.heartbeat()
    Network.retryPending()
  end,math.huge)
  return true
end

function M.stop()
  if M.timer then event.cancel(M.timer);M.timer=nil end
end

return M
