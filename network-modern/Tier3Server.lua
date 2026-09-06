-- BULDACITY TIER-3 CENTRAL SERVER
-- Authoritative core: Modern node -> Relay -> TIER3-CORE -> Relay -> destination.
local event=require("event")
local serialization=require("serialization")
local computer=require("computer")
local Protocol=require("network-modern.Protocol")
local Transport=require("network-modern.Transport")
local Config=require("network-modern.Tier3Config")
local Logger=require("network-modern.Tier3Logger")
local Storage=require("network-modern.Tier3Storage")
local Security=require("network-modern.Tier3Security")
local Monitor=require("network-modern.Tier3Monitor")

local NODE_ID=Config.nodeId
local PORT=Config.port
local ROUTE_TIMEOUT=Config.routeTimeout
local nodes={}
local relays={}
local seen={}
local stats={received=0,routed=0,dropped=0,invalid=0,noRoute=0,denied=0}

Logger.init(Config.logFile)
Storage.init(Config.stateFile)
local saved=Storage.load({})

local function now() return computer.uptime() end
local function nextId(kind) return string.format("%s-%s-%d",NODE_ID,kind or "MSG",math.floor(now()*1000)) end
local function remember(id)
  seen[id]=now();local n=0;local oldestId=nil;local oldest=math.huge
  for k,t in pairs(seen) do n=n+1;if t<oldest then oldest=t;oldestId=k end end
  if n>Config.maxSeen and oldestId then seen[oldestId]=nil end
end
local function send(packet,address,broadcast)
  local raw=serialization.serialize(packet)
  if #raw>Config.maxPacketBytes then return false,"PACKET_TOO_LARGE" end
  if address then return Transport.send(address,raw) end
  if broadcast then return Transport.broadcast(raw) end
  return false,"NO_DESTINATION"
end
local function registerNode(p,sender,distance)
  local payload=p.payload or {};local role=payload.role or "NODE";local id=p.source
  local entry=nodes[id] or saved.nodes and saved.nodes[id] or {}
  entry.address=sender;entry.last=now();entry.distance=tonumber(distance) or 0;entry.role=role
  entry.app=payload.app or payload.name or entry.app;entry.status=payload.status or entry.status
  local route=p.route or {};if route.relay then entry.relayId=route.relay;entry.segment=tonumber(route.segment) end
  if role=="RELAY" or payload.relay then relays[id]=entry end
  nodes[id]=entry
end
local function destinationRoute(id)
  local n=nodes[id];if not n or now()-n.last>ROUTE_TIMEOUT then return nil end
  if n.relayId and relays[n.relayId] and relays[n.relayId].address then return relays[n.relayId].address end
  return n.address
end
local function reply(p,kind,payload,address)
  return send(Protocol.new(kind,NODE_ID,p.source,nextId(kind),payload),address)
end
local function nack(p,reason,address)
  stats.dropped=stats.dropped+1;reply(p,"NACK",{ackId=p.id,reason=reason,server=true},address or p._sender)
end
local function route(p)
  if p.destination=="*" then return false,"BROADCAST_NOT_ROUTED" end
  local address=destinationRoute(p.destination);if not address then return false,"NO_ROUTE" end
  local out=Protocol.forward(p);if not out or out.hops>=out.maxHops then return false,"TTL" end
  out.route={via=NODE_ID,central=true,target=p.destination,targetRelay=nodes[p.destination] and nodes[p.destination].relayId}
  return send(out,address)
end
local function persist()
  local snapshot={bootCount=saved.bootCount or 0,nodes={}}
  for id,n in pairs(nodes) do snapshot.nodes[id]={role=n.role,app=n.app,relayId=n.relayId,segment=n.segment,status=n.status} end
  Storage.save(snapshot)
end
local function state()
  local nc=0;for _ in pairs(nodes) do nc=nc+1 end
  local rc=0;for _ in pairs(relays) do rc=rc+1 end
  return {nodes=nodes,relays=relays,stats=stats,nodeCount=nc,relayCount=rc,nodeId=NODE_ID,port=PORT}
end
local function handle(p,sender,distance)
  stats.received=stats.received+1;p._sender=sender
  registerNode(p,sender,distance)
  if p.type=="HELLO" or p.type=="HEARTBEAT" then
    reply(p,"STATUS",{role="SERVER",server=true,nodeId=NODE_ID,protocol=Protocol.NAME,port=PORT,route="CENTRAL",registered=true},sender)
    reply(p,"ACK",{ackId=p.id,ackType=p.type,server=true},sender);return
  end
  if p.type=="PING" then reply(p,"PONG",{id=p.id,server=true,nodeId=NODE_ID},sender);return end
  if p.type=="ACK" or p.type=="NACK" then return end
  local allowed,reason=Security.commandAllowed(p.source,p.type)
  if not allowed then stats.denied=stats.denied+1;Logger.warn("Command denied",{reason=reason,id=p.source});nack(p,reason,sender);return end
  if p.type=="COMMAND" or p.type=="EMERGENCY_STOP" or p.type=="STATUS" then
    local ok,r=route(p)
    if ok then stats.routed=stats.routed+1;reply(p,"ACK",{ackId=p.id,ackType=p.type,server=true,routed=true},sender);Logger.info("Packet routed",{id=p.id})
    else stats.noRoute=stats.noRoute+1;nack(p,r,sender);Logger.warn("No route",{reason=r,id=p.id}) end
  end
end
local ok,err=Transport.init(PORT)
if not ok then error("BULDACITY TIER-3: Transport init failed: "..tostring(err)) end
Monitor.start(state,Config.dashboardRefresh)
Logger.info("Tier-3 online",{event="ONLINE"})
event.listen("modem_message",function(_,receiver,sender,port,distance,raw)
  if port~=PORT then return end
  local good,p=pcall(serialization.unserialize,raw);if not good or type(p)~="table" then stats.invalid=stats.invalid+1;return end
  local valid=Protocol.valid(p);if not valid then stats.invalid=stats.invalid+1;return end
  if p.source==NODE_ID or seen[p.id] then return end
  remember(p.id);handle(p,sender,distance)
end)
event.timer(Config.announceInterval,function()
  send(Protocol.new("STATUS",NODE_ID,"*",nextId("ANNOUNCE"),{role="SERVER",server=true,nodeId=NODE_ID,protocol=Protocol.NAME,port=PORT,route="CENTRAL",stats=stats}),nil,true)
end,math.huge)
event.timer(5,function()
  local t=now();for id,n in pairs(nodes) do if t-n.last>ROUTE_TIMEOUT then nodes[id]=nil;relays[id]=nil end end;persist()
end,math.huge)
print("BULDACITY TIER-3 CORE online | node "..NODE_ID.." | port "..PORT)
while true do local _,reason=event.pull(30);if reason=="interrupted" then break end end
Logger.info("Tier-3 stopped",{event="STOP"})
