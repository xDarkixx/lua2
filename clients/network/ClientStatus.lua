-- BULDACITY client status helper
local Network=require("network-modern.Network")
local M={}

function M.send(status)
  status=status or {}
  status.role="CLIENT"
  return Network.send("STATUS","TIER3-CORE",status)
end

function M.snapshot(extra)
  local s=Network.status()
  for k,v in pairs(extra or {}) do s[k]=v end
  s.role="CLIENT"
  return s
end

function M.ping()
  return Network.send("PING","TIER3-CORE",{role="CLIENT"})
end

return M
