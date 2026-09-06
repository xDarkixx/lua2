-- Modern Tier-3 Remote Bridge
-- Single-main-PC architecture:
--   Modern clients -> TIER3-CORE -> this bridge -> Main PC gateway
-- The bridge uploads Modern UI frames and polls commands/UI input.
local component=require("component")
local event=require("event")
local serialization=require("serialization")
local Network=require("network-modern.Network")
local GATEWAY=os.getenv("MODERN_GATEWAY") or "http://127.0.0.1:8080"
local TOKEN=os.getenv("MODERN_GATEWAY_TOKEN") or ""
local POLL_SECONDS=1
if not component.isAvailable("internet") then error("Modern RemoteBridge: Internet Card fehlt") end
if TOKEN=="" then error("Modern RemoteBridge: MODERN_GATEWAY_TOKEN fehlt") end
local internet=component.internet
Network.init("TIER3-CORE")
local function request(method,url,body)
  local ok,handle=pcall(function() return internet.request(url,body or nil,{method=method,headers={['Content-Type']='application/json'}}) end)
  if not ok or not handle then return nil,"HTTP_REQUEST_FAILED" end
  local data="";local rok=pcall(function() for chunk in handle do data=data..chunk end end)
  pcall(function() handle.close() end)
  if not rok then return nil,"HTTP_READ_FAILED" end
  return data
end
local function post(path,payload)
  return request("POST",GATEWAY..path.."?token="..TOKEN,serialization.serialize(payload or {}))
end
local function poll()
  local body,err=request("GET",GATEWAY.."/bridge/poll?token="..TOKEN)
  if not body then return false,err end
  local line=body:gsub("%s+$","")
  if line=="NOOP" or line=="" then return true end
  local kind,destination,action,value=line:match("^([A-Z]+)|([^|]+)|([^|]+)|(.*)$")
  if not kind then return false,"INVALID_BRIDGE_COMMAND" end
  if kind=="COMMAND" then return Network.sendReliable("COMMAND",destination,{action=action,value=value,remote=true,remoteId=os.time()}) end
  if kind=="UIINPUT" then return Network.sendReliable("UI_INPUT",destination,{action=action,value=value,remote=true}) end
  return false,"UNKNOWN_BRIDGE_COMMAND"
end
local function onPacket(packet)
  if type(packet)~="table" then return end
  if packet.type=="UI_FRAME" and type(packet.payload)=="table" then
    local ok,err=post("/api/ui",packet.payload)
    if not ok then io.stderr:write("ModernRemote UI upload failed: "..tostring(err).."\n") end
  elseif packet.type=="STATUS" and type(packet.payload)=="table" then
    post("/api/status",packet.payload)
  end
end
local ok,err=Network.startClient("MODERN TIER3 BRIDGE",{service="RemoteBridge",role="TIER3_BRIDGE"},onPacket)
if not ok then error("Modern RemoteBridge network unavailable: "..tostring(err)) end
print("Modern Tier-3 Remote Bridge online | Main PC: "..GATEWAY)
event.timer(POLL_SECONDS,function() local good,e=poll();if not good then io.stderr:write("RemoteBridge: "..tostring(e).."\n") end end,math.huge)
while true do local _,reason=event.pull(30);if reason=="interrupted" then break end end
