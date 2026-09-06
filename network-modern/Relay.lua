-- BULDACITY MODERN CENTRAL RELAY
-- Two isolated modem segments. Client traffic always goes to TIER3-CORE.
-- A relay never routes client A directly to client B.
local component=require("component")
local event=require("event")
local serialization=require("serialization")
local computer=require("computer")
local Protocol=require("network-modern.Protocol")
local PORT=Protocol.PORT;local TIER3_ID="TIER3-CORE";local MAX_SEEN=2048
local seen={};local stats={received=0,forwarded=0,dropped=0,invalid=0};local modems={};local tier3={}
for address,_ in component.list("modem",true) do local m=component.proxy(address);if m then modems[#modems+1]=m end end
if #modems<2 then io.stderr:write("BULDACITY RELAY: two modem/network-card interfaces are required.\n");return false end
local RELAY_ID="RELAY-"..tostring(modems[1].address)
local function now() return computer.uptime() end
local function markSeen(id) seen[id]=now();local n=0;local oldestId=nil;local oldest=math.huge;for k,t in pairs(seen) do n=n+1;if t<oldest then oldest=t;oldestId=k end end;if n>MAX_SEEN and oldestId then seen[oldestId]=nil end end
local function interfaceByAddress(address) for i,m in ipairs(modems) do if m.address==address then return i,m end end end
local function send(m,address,raw,broadcast) if broadcast then return pcall(function()m.broadcast(PORT,raw)end) end;if not address then return false end;return pcall(function()m.send(address,PORT,raw)end) end
for _,m in ipairs(modems) do pcall(function()m.open(PORT)end) end
local function centralPacket(p) return p.route and p.route.central==true and p.route.via==TIER3_ID end
local function forwardToTier3(sourceInterface,p)
  if not tier3.address then return false,"TIER3_NOT_FOUND" end
  local out=Protocol.forward(p);if not out or out.hops>=out.maxHops then return false,"TTL" end
  out.route=out.route or {};out.route.relay=RELAY_ID;out.route.segment=sourceInterface
  local raw=serialization.serialize(out);if #raw>Protocol.MAX_PACKET_BYTES then return false,"PACKET_TOO_LARGE" end
  local _,target=interfaceByAddress(tier3.receiver);target=target or modems[sourceInterface]
  local ok=send(target,tier3.address,raw,false);if ok then stats.forwarded=stats.forwarded+1 end;return ok
end
local function forwardCentralPacket(sourceInterface,p)
  if not centralPacket(p) then stats.dropped=stats.dropped+1;return false end
  local targetInterface=tonumber(p.route.targetSegment)
  local target
  if targetInterface and modems[targetInterface] then target=modems[targetInterface]
  else targetInterface,target=1,modems[1];if targetInterface==sourceInterface then targetInterface,target=2,modems[2] end end
  local out=Protocol.forward(p);if not out or out.hops>=out.maxHops then stats.dropped=stats.dropped+1;return false end
  local raw=serialization.serialize(out);if #raw>Protocol.MAX_PACKET_BYTES then stats.dropped=stats.dropped+1;return false end
  local ok=send(target,nil,raw,true);if ok then stats.forwarded=stats.forwarded+1 end;return ok
end
event.listen("modem_message",function(_,receiver,sender,port,distance,raw)
  if port~=PORT then return end
  local sourceInterface=interfaceByAddress(receiver);if not sourceInterface then return end
  stats.received=stats.received+1
  local ok,p=pcall(serialization.unserialize,raw);if not ok or type(p)~="table" then stats.invalid=stats.invalid+1;return end
  local valid=Protocol.valid(p);if not valid or seen[p.id] then if not valid then stats.invalid=stats.invalid+1 end;return end
  markSeen(p.id)
  if p.source==TIER3_ID or centralPacket(p) then if p.source==TIER3_ID then tier3.address=sender;tier3.receiver=receiver end;forwardCentralPacket(sourceInterface,p);return end
  if p.type=="HELLO" or p.type=="HEARTBEAT" or p.type=="STATUS" or p.type=="COMMAND" or p.type=="EMERGENCY_STOP" then forwardToTier3(sourceInterface,p) end
end)
local function announce()
  local p=Protocol.new("HELLO",RELAY_ID,"*",string.format("%s-%d",RELAY_ID,math.floor(now()*1000)),{role="RELAY",relay=true,interfaces=#modems,nodeId=RELAY_ID,tier3=TIER3_ID})
  local raw=serialization.serialize(p);for _,m in ipairs(modems) do pcall(function()m.broadcast(PORT,raw)end) end
end
event.timer(10,announce,math.huge);announce()
print("BULDACITY CENTRAL RELAY online | "..RELAY_ID.." | port "..PORT)
while true do local _,reason=event.pull(30);if reason=="interrupted" then break end end
