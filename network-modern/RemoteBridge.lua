-- Modern Tier-3 remote bridge
-- Internet Card bridge for remote commands and Modern UI scenes.
local component=require("component")
local event=require("event")
local serialization=require("serialization")
local Network=require("network-modern.Network")
local GATEWAY=os.getenv("MODERN_GATEWAY") or "http://127.0.0.1:8080"
local TOKEN=os.getenv("MODERN_GATEWAY_TOKEN") or ""
local POLL_SECONDS=2
if not component.isAvailable("internet") then error("Modern RemoteBridge: Internet Card missing") end
if TOKEN=="" then error("Modern RemoteBridge: MODERN_GATEWAY_TOKEN missing") end
local internet=component.internet
Network.startServer(function(packet,sender)
  if packet.type=="UI_FRAME" and packet.payload then
    local body=serialization.serialize(packet.payload)
    local url=GATEWAY.."/api/ui?token="..TOKEN
    pcall(function()
      local h=internet.request(url,body,{["Content-Type"]="application/json"},"POST")
      if h then for _ in h do end; pcall(function()h.close()end) end
    end)
  end
end)

local function get(url)
  local ok,handle=pcall(function()return internet.request(url)end)
  if not ok or not handle then return nil,"HTTP_REQUEST_FAILED" end
  local data="";local rok=pcall(function()for chunk in handle do data=data..chunk end end)
  pcall(function()handle.close()end)
  if not rok then return nil,"HTTP_READ_FAILED" end
  return data
end

local function poll()
  local body,err=get(GATEWAY.."/bridge/poll?token="..TOKEN)
  if not body then return false,err end
  local line=body:gsub("%s+$","")
  if line=="NOOP" or line=="" then return true end
  local id,destination,action,value=line:match("^COMMAND|([^|]+)|([^|]+)|([^|]+)|(.*)$")
  if not id then return false,"INVALID_COMMAND" end
  return Network.sendReliable("COMMAND",destination,{action=action,value=value,remote=true,remoteId=id})
end

print("Modern RemoteBridge online | gateway "..GATEWAY)
event.timer(POLL_SECONDS,function()
  local ok,err=poll();if not ok then io.stderr:write("RemoteBridge: "..tostring(err).."\n") end
end,math.huge)
while true do local _,reason=event.pull(30);if reason=="interrupted" then break end end
