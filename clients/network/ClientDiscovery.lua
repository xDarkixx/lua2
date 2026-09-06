-- BULDACITY client discovery
local Network=require("network-modern.Network")
local Protocol=require("clients.network.ClientProtocol")
local M={}

function M.announce(name,extra)
  local payload=extra or {}
  payload.role="CLIENT"
  payload.name=name or payload.name or "BULDACITY MODERN CLIENT"
  payload.protocol=Protocol.NAME
  payload.port=Protocol.PORT
  return Network.send("HELLO","*",payload)
end

function M.ping()
  return Network.send("PING","TIER3-CORE",{role="CLIENT"})
end

function M.status()
  return Network.status()
end

return M
