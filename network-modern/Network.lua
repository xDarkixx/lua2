-- BULDACITY Modern Network API
-- Centralized mode: Modern node -> Relay -> TIER3-CORE -> Relay -> destination.
-- Legacy Network.lua is intentionally untouched.
local component=require("component")
local serialization=require("serialization")
local event=require("event")
local computer=require("computer")
local Protocol=require("network-modern.Protocol")
local Transport=require("network-modern.Transport")
local Registry=require("network-modern.Registry")

local M={nodeId=nil,sequence=0,seen={},pending={},clientListening=false,serverListening=false,serverAddress=nil}
local SEEN_LIMIT=512
local ACK_TIMEOUT=3
local RETRIES=3
local TIER3_ID="TIER3-CORE"

local function now() return computer.uptime() end
local function nextId()
  M.sequence=M.sequence+1
  return string.format("%s-%d-%d",M.nodeId or "NODE",math.floor(now()*1000),M.sequence)
end
local function remember(id)
  M.seen[id]=now()
  local n=0;local oldestId=nil;local oldest=math.huge
  for k,t in pairs(M.seen) do n=n+1;if t<oldest then oldest=t;oldestId=k end end
  if n>SEEN_LIMIT and oldestId then M.seen[oldestId]=nil end
end

function M.init(nodeId,port)
  if nodeId and tostring(nodeId)~="" then M.nodeId=tostring(nodeId)
  else
    local ok,a=pcall(computer.address);M.nodeId=ok and a or "NODE"
  end
  return Transport.init(port or Protocol.PORT)
end

local function sendPacket(packet,address,broadcast)
  local raw=serialization.serialize(packet)
  if #raw>Protocol.MAX_PACKET_BYTES then return false,"PACKET_TOO_LARGE" end
  if address then return Transport.send(address,raw) end
  if broadcast then return Transport.broadcast(raw) end
  return false,"NO_ROUTE"
end

-- Central routing is the default. Direct hardware addressing is only used
-- for the Tier-3 server itself or when explicitly requested by the caller.
function M.send(kind,destination,payload,address)
  if not M.nodeId then local ok,err=M.init();if not ok then return false,err end end
  destination=destination or "*"
  local packet=Protocol.new(kind,M.nodeId,destination,nextId(),payload)
  if address then return sendPacket(packet,address,false) end
  if destination=="*" then return sendPacket(packet,nil,true) end
  if M.serverAddress then return sendPacket(packet,M.serverAddress,false) end
  return false,"TIER3_NOT_CONNECTED"
end

function M.sendReliable(kind,destination,payload,address)
  if not M.nodeId then local ok,err=M.init();if not ok then return false,err end end
  destination=destination or "*"
  local packet=Protocol.new(kind,M.nodeId,destination,nextId(),payload)
  local raw=serialization.serialize(packet)
  if #raw>Protocol.MAX_PACKET_BYTES then return false,"PACKET_TOO_LARGE" end
  local target=address or (destination=="*" and nil or M.serverAddress)
  if destination~="*" and not target then return false,"TIER3_NOT_CONNECTED" end
  M.pending[packet.id]={packet=packet,raw=raw,address=target,retries=0,deadline=now()+ACK_TIMEOUT}
  local ok,err
  if target then ok,err=Transport.send(target,raw) else ok,err=Transport.broadcast(raw) end
  if not ok then M.pending[packet.id]=nil;return false,err end
  return true,packet.id
end

function M.hello()
  return M.send("HELLO","*",{role="CLIENT",node=M.nodeId,central=true})
end
function M.heartbeat()
  return M.send("HEARTBEAT",TIER3_ID,{role="CLIENT",node=M.nodeId,central=true})
end

local function handleAck(p)
  local d=p.payload or{};local ackId=d.ackId or d.id
  if ackId and M.pending[ackId] then M.pending[ackId]=nil end
end

local function ack(r,p)
  if p.type=="ACK" or p.type=="NACK" then return end
  local response=Protocol.new("ACK",M.nodeId,p.source,nextId(),{ackId=p.id,ackType=p.type})
  local raw=serialization.serialize(response)
  if #raw<=Protocol.MAX_PACKET_BYTES then pcall(Transport.send,r.sender,raw) end
end

function M.poll(timeout)
  local r=Transport.receive(timeout);if not r then return nil end
  local ok,p=pcall(serialization.unserialize,r.payload);if not ok then return nil,"INVALID_PACKET" end
  local valid,reason=Protocol.valid(p);if not valid then return nil,"INVALID_PACKET_"..tostring(reason) end
  if p.destination~="*" and p.destination~=M.nodeId and p.destination~=TIER3_ID then return nil,"NOT_FOR_US" end
  if M.seen[p.id] then return nil,"DUPLICATE" end
  remember(p.id)
  Registry.touch(p.source,r.sender,p.payload and p.payload.kind)
  if p.source==TIER3_ID then M.serverAddress=r.sender end
  if p.type=="HEARTBEAT" then Registry.heartbeat(p.source) end
  if p.type=="ACK" or p.type=="NACK" then handleAck(p) else ack(r,p) end
  return p,r
end

function M.registry() Registry.expire(10);return Registry.all() end

local function installClientListener(callback)
  if M.clientListening then return end
  M.clientListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,raw)
    if port~=Protocol.PORT then return end
    local ok,p=pcall(serialization.unserialize,raw);if not ok then return end
    local valid=Protocol.valid(p);if not valid then return end
    if p.destination~="*" and p.destination~=M.nodeId then return end
    if M.seen[p.id] then return end
    remember(p.id)
    Registry.touch(p.source,sender,p.payload and p.payload.kind)
    if p.source==TIER3_ID or (p.payload and p.payload.server) then M.serverAddress=sender end
    if p.type=="ACK" or p.type=="NACK" then handleAck(p);if callback then pcall(callback,p,sender,distance) end;return end
    if p.type=="HELLO" then
      M.serverAddress=sender
      M.send("ACK",p.source,{ackId=p.id,ackType="HELLO",server=true},sender)
    elseif p.type=="STATUS" then
      if p.payload and p.payload.role=="SERVER" then M.serverAddress=sender end
    elseif p.type=="PING" then
      M.serverAddress=sender
      M.send("PONG",p.source,{name=M.clientName,nodeId=M.nodeId,id=p.id},sender)
    end
    if callback then pcall(callback,p,sender,distance) end
  end)
end

function M.startClient(name,extra,callback)
  local ok,err=M.init();if not ok then return false,err end
  M.clientName=name or "BULDACITY MODERN CLIENT"
  M.clientExtra=extra or{};M.clientExtra.name=M.clientName;M.clientExtra.role="CLIENT"
  M.clientExtra.nodeId=M.nodeId;M.clientExtra.protocol=Protocol.NAME;M.clientExtra.port=Protocol.PORT
  installClientListener(callback)
  local function announce() M.hello() end
  announce()
  if not M.helloTimer then M.helloTimer=event.timer(5,announce,math.huge) end
  if not M.heartbeatTimer then M.heartbeatTimer=event.timer(3,function()M.heartbeat();M.retryPending() end,math.huge) end
  return true,Protocol.PORT
end

function M.retryPending()
  local t=now()
  for id,q in pairs(M.pending) do
    if t>=q.deadline then
      if q.retries>=RETRIES then M.pending[id]=nil
      else
        q.retries=q.retries+1;q.deadline=t+ACK_TIMEOUT
        if q.address then Transport.send(q.address,q.raw) else Transport.broadcast(q.raw) end
      end
    end
  end
end

function M.startServer(callback)
  local ok,err=M.init(TIER3_ID);if not ok then return false,err end
  if M.serverListening then return true,Protocol.PORT end
  M.serverListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,raw)
    if port~=Protocol.PORT then return end
    local ok,p=pcall(serialization.unserialize,raw);if not ok then return end
    local valid=Protocol.valid(p);if not valid then return end
    if p.destination~="*" and p.destination~=M.nodeId then return end
    if M.seen[p.id] then return end
    remember(p.id);Registry.touch(p.source,sender,p.payload and p.payload.kind)
    if p.type=="HELLO" then
      M.send("STATUS",p.source,{role="SERVER",nodeId=TIER3_ID,protocol=Protocol.NAME,port=Protocol.PORT,route="CENTRAL"},sender)
      M.send("ACK",p.source,{ackId=p.id,ackType="HELLO",server=true},sender)
    elseif p.type=="PING" then
      M.send("PONG",p.source,{id=p.id,server=true,nodeId=TIER3_ID},sender)
    elseif p.type~="ACK" and p.type~="NACK" then
      M.send("ACK",p.source,{ackId=p.id,ackType=p.type,server=true},sender)
    end
    if callback then pcall(callback,p,sender,distance) end
  end)
  return true,Protocol.PORT
end

function M.status()
  local ok,info=pcall(function()return Transport.status()end)
  return {ok=ok,transport=info,nodeId=M.nodeId,server=TIER3_ID,serverAddress=M.serverAddress,protocol=Protocol.NAME,port=Protocol.PORT,pending=M.pending}
end

return M
