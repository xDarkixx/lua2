-- BULDACITY Modern Network Relay
-- Put this program on a computer with TWO network cards/modems.
-- Segment A and B stay physically separated; only BULDACITY packets cross.
local component=require("component")
local event=require("event")
local serialization=require("serialization")
local computer=require("computer")
local Protocol=require("network-modern.Protocol")

local PORT=Protocol.PORT
local MAX_SEEN=1024
local routes={}
local seen={}
local stats={received=0,forwarded=0,dropped=0,invalid=0}
local modems={}

for address,_ in component.list("modem",true) do
  local m=component.proxy(address)
  if m then modems[#modems+1]=m end
end

if #modems<2 then
  io.stderr:write("BULDACITY RELAY: two modem/network-card interfaces are required.\n")
  return false
end

local function trimSeen()
  local count=0;local oldestId=nil;local oldest=math.huge
  for id,t in pairs(seen) do
    count=count+1
    if t<oldest then oldest=t;oldestId=id end
  end
  if count>MAX_SEEN and oldestId then seen[oldestId]=nil end
end

local function markSeen(id)
  seen[id]=computer.uptime()
  trimSeen()
end

local function interfaceByAddress(address)
  for i,m in ipairs(modems) do
    if m.address==address then return i,m end
  end
  return nil,nil
end

local function other(i)
  for j,m in ipairs(modems) do if j~=i then return j,m end end
end

local function sendOn(m,address,raw,broadcast)
  if broadcast then
    return pcall(function()m.broadcast(PORT,raw)end)
  end
  return pcall(function()m.send(address,PORT,raw)end)
end

for _,m in ipairs(modems) do pcall(function()m.open(PORT)end) end

local function forward(sourceInterface,p,raw)
  local targetInterface,target=other(sourceInterface)
  if not target then return false end
  local nextPacket=Protocol.forward(p)
  if not nextPacket then return false end
  local ok,reason=Protocol.valid(p)
  if not ok then return false end
  if tonumber(nextPacket.hops or 0)>=tonumber(nextPacket.maxHops or Protocol.MAX_HOPS) then
    stats.dropped=stats.dropped+1
    return false
  end
  local nextRaw=serialization.serialize(nextPacket)
  if #nextRaw>Protocol.MAX_PACKET_BYTES then stats.dropped=stats.dropped+1;return false end

  if p.destination=="*" then
    local sent=sendOn(target,nil,nextRaw,true)
    if sent then stats.forwarded=stats.forwarded+1 end
    return sent
  end

  local route=routes[p.destination]
  if route and route.interface==targetInterface then
    local sent=sendOn(target,route.address,nextRaw,false)
    if sent then stats.forwarded=stats.forwarded+1 end
    return sent
  end

  -- Unknown destination: discover it on the opposite segment without
  -- flooding the segment from which the packet came.
  local sent=sendOn(target,nil,nextRaw,true)
  if sent then stats.forwarded=stats.forwarded+1 end
  return sent
end

event.listen("modem_message",function(_,receiver,sender,port,distance,raw)
  if port~=PORT then return end
  local sourceInterface=interfaceByAddress(receiver)
  if not sourceInterface then return end
  stats.received=stats.received+1

  local ok,p=pcall(serialization.unserialize,raw)
  if not ok or type(p)~="table" then stats.invalid=stats.invalid+1;return end
  local valid=Protocol.valid(p)
  if not valid then stats.invalid=stats.invalid+1;return end
  if seen[p.id] then return end
  markSeen(p.id)

  routes[p.source]={interface=sourceInterface,address=sender,last=computer.uptime(),distance=tonumber(distance)or 0}

  -- Never reflect traffic back onto its incoming segment.
  forward(sourceInterface,p,raw)
end)

local function announce()
  local packet=Protocol.new("STATUS","RELAY","*",string.format("RELAY-%d",math.floor(computer.uptime()*1000)),{
    role="RELAY",relay=true,interfaces=#modems,received=stats.received,forwarded=stats.forwarded,
    dropped=stats.dropped,invalid=stats.invalid
  })
  local raw=serialization.serialize(packet)
  for _,m in ipairs(modems) do pcall(function()m.broadcast(PORT,raw)end) end
end

announce()
event.timer(10,announce,math.huge)

print("BULDACITY RELAY online | port "..tostring(PORT).." | interfaces "..tostring(#modems))
while true do
  local _,reason=event.pull(30)
  if reason=="interrupted" then break end
end
