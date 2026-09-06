-- BULDACITY TIER-3 CENTRAL SERVER
-- One authoritative routing core for all Modern devices.
-- Topology: Modern node -> Relay -> Tier-3 -> Relay -> destination.
local event=require("event")
local serialization=require("serialization")
local computer=require("computer")
local Protocol=require("network-modern.Protocol")
local Transport=require("network-modern.Transport")

local NODE_ID="TIER3-CORE"
local PORT=Protocol.PORT
local ROUTE_TIMEOUT=20
local MAX_SEEN=2048
local nodes={}
local relays={}
local seen={}
local stats={received=0,routed=0,dropped=0,invalid=0,noRoute=0}

local function now() return computer.uptime() end
local function nextId(kind) return string.format("%s-%s-%d",NODE_ID,kind or "MSG",math.floor(now()*1000)) end
local function remember(id)
  seen[id]=now();local n=0;local oldestId=nil;local oldest=math.huge
  for k,t in pairs(seen) do n=n+1;if t<oldest then oldest=t;oldestId=k end end
  if n>MAX_SEEN and oldestId then seen[oldestId]=nil end
end
local function send(packet,address,broadcast)
  local raw=serialization.serialize(packet);if #raw>Protocol.MAX_PACKET_BYTES then return false,"PACKET_TOO_LARGE" end
  if address then return Transport.send(address,raw) end
  if broadcast then return Transport.broadcast(raw) end
  return false,"NO_DESTINATION"
end
local function directNodeRoute(nodeId)
  local n=nodes[nodeId];if not n or now()-n.last>ROUTE_TIMEOUT then return nil end
  return n.address
end
local function nack(p,reason,address)
  stats.dropped=stats.dropped+1
  send(Protocol.new("NACK",NODE_ID,p.source,nextId("NACK"),{ackId=p.id,reason=reason,server=true}),address or directNodeRoute(p.source))
end
local function registerNode(p,sender,distance)
  local payload=p.payload or {};local role=payload.role or "NODE";local nodeId=p.source;local entry=nodes[nodeId] or {}
  entry.address=sender;entry.last=now();entry.distance=tonumber(distance) or 0;entry.role=role
  entry.app=payload.app or payload.name or entry.app;entry.status=payload.status or entry.status
  local route=p.route or {}
  if route.relay then entry.relayId=route.relay;entry.segment=tonumber(route.segment) end
  if payload.relayAddress then entry.relayAddress=payload.relayAddress end
  nodes[nodeId]=entry
  if role=="RELAY" or payload.relay then relays[nodeId]=entry end
end
local function sendViaTier3(p)
  local destination=p.destination;if destination=="*" then return false,"BROADCAST_NOT_ROUTED" end
  local n=nodes[destination];if not n or now()-n.last>ROUTE_TIMEOUT then return false,"NO_ROUTE" end
  local out=Protocol.forward(p);if not out or out.hops>=out.maxHops then return false,"TTL" end
  out.route={via=NODE_ID,central=true,target=destination,targetSegment=n.segment,targetRelay=n.relayId}
  -- If destination is on the same physical segment as its relay, the relay
  -- uses targetSegment to send only to that interface.
  return send(out,n.relayAddress or n.address)
end
local function handle(p,sender,distance)
  stats.received=stats.received+1;registerNode(p,sender,distance)
  if p.type=="HELLO" or p.type=="HEARTBEAT" then
    send(Protocol.new("STATUS",NODE_ID,p.source,nextId("STATUS"),{role="SERVER",server=true,nodeId=NODE_ID,protocol=Protocol.NAME,port=PORT,route="CENTRAL",registered=true}),sender)
    send(Protocol.new("ACK",NODE_ID,p.source,nextId("ACK"),{ackId=p.id,ackType=p.type,server=true}),sender);return
  end
  if p.type=="PING" then send(Protocol.new("PONG",NODE_ID,p.source,nextId("PONG"),{id=p.id,server=true,nodeId=NODE_ID}),sender);return end
  if p.type=="ACK" or p.type=="NACK" then return end
  if p.type=="COMMAND" or p.type=="EMERGENCY_STOP" or p.type=="STATUS" then
    local ok,reason=sendViaTier3(p)
    if ok then stats.routed=stats.routed+1;send(Protocol.new("ACK",NODE_ID,p.source,nextId("ACK"),{ackId=p.id,ackType=p.type,server=true,routed=true}),sender)
    else stats.noRoute=stats.noRoute+1;nack(p,reason,sender) end
  end
end
event.listen("modem_message",function(_,receiver,sender,port,distance,raw)
  if port~=PORT then return end
  local ok,p=pcall(serialization.unserialize,raw);if not ok or type(p)~="table" then stats.invalid=stats.invalid+1;return end
  local valid=Protocol.valid(p);if not valid then stats.invalid=stats.invalid+1;return end
  if p.source==NODE_ID or seen[p.id] then return end
  remember(p.id);handle(p,sender,distance)
end)
local function announce()
  send(Protocol.new("STATUS",NODE_ID,"*",nextId("ANNOUNCE"),{role="SERVER",server=true,nodeId=NODE_ID,protocol=Protocol.NAME,port=PORT,route="CENTRAL",stats=stats}),nil,true)
end
event.timer(5,announce,math.huge)
event.timer(5,function()
  local t=now();for id,n in pairs(nodes) do if t-n.last>ROUTE_TIMEOUT then nodes[id]=nil;relays[id]=nil end end
end,math.huge)
print("BULDACITY TIER-3 CORE online | node "..NODE_ID.." | port "..PORT)
while true do local _,reason=event.pull(30);if reason=="interrupted" then break end end
