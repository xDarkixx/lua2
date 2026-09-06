-- BULDACITY Tier-3 remote bridge
-- Runs on the Tier-3 host when an Internet Card is available.
-- The bridge polls the HTTPS/VPN-protected Python gateway and converts
-- queued web commands into normal central COMMAND packets.
local component=require("component")
local event=require("event")
local Network=require("network-modern.Network")
local GATEWAY=os.getenv("BULDACITY_GATEWAY") or "http://127.0.0.1:8080"
local TOKEN=os.getenv("BULDACITY_GATEWAY_TOKEN") or ""
local POLL_SECONDS=2
if not component.isAvailable("internet") then error("BULDACITY RemoteBridge: Internet Card fehlt") end
if TOKEN=="" then error("BULDACITY RemoteBridge: BULDACITY_GATEWAY_TOKEN fehlt") end
local internet=component.internet
Network.init("TIER3-CORE")
local function get(url)
  local ok,handle=pcall(function()return internet.request(url)end)
  if not ok or not handle then return nil,"HTTP_REQUEST_FAILED" end
  local data="";local rok=pcall(function()for chunk in handle do data=data..chunk end end);pcall(function()handle.close()end)
  if not rok then return nil,"HTTP_READ_FAILED" end;return data
end
local function poll()
  local body,err=get(GATEWAY.."/bridge/poll?token="..TOKEN);if not body then return false,err end
  local line=body:gsub("%s+$","");if line=="NOOP" or line=="" then return true end
  local id,destination,action,value=line:match("^COMMAND|([^|]+)|([^|]+)|([^|]+)|(.*)$")
  if not id then return false,"INVALID_COMMAND" end
  local ok,sendErr=Network.sendReliable("COMMAND",destination,{action=action,value=value,remote=true,remoteId=id})
  return ok,sendErr
end
print("BULDACITY RemoteBridge online | gateway "..GATEWAY)
event.timer(POLL_SECONDS,function()local ok,err=poll();if not ok then io.stderr:write("RemoteBridge: "..tostring(err).."\n") end end,math.huge)
while true do local _,reason=event.pull(30);if reason=="interrupted" then break end end
