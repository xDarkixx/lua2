-- BULDACITY Modern Network API
local component=require("component")
local serialization=require("serialization")
local Protocol=require("network-modern.Protocol")
local Transport=require("network-modern.Transport")
local Registry=require("network-modern.Registry")

local M={nodeId=nil, sequence=0, seen={}}

local function nextId()
  M.sequence=M.sequence+1
  return string.format("%s-%d-%d",M.nodeId or "NODE",os.time(),M.sequence)
end

function M.init(nodeId,port)
  M.nodeId=nodeId or (component.computer and component.computer.getDeviceInfo().product or "NODE")
  return Transport.init(port)
end

function M.send(kind,destination,payload,address)
  local packet=Protocol.new(kind,M.nodeId,destination,nextId(),payload)
  local raw=serialization.serialize(packet)
  if address then return Transport.send(address,raw) end
  return Transport.broadcast(raw)
end

function M.hello()
  return M.send("HELLO","*",{kind="CONTROL"})
end

function M.heartbeat()
  return M.send("HEARTBEAT","*",{})
end

function M.poll(timeout)
  local r=Transport.receive(timeout)
  if not r then return nil end
  local ok,p=pcall(serialization.unserialize,r.payload)
  if not ok or not Protocol.valid(p) then return nil,"INVALID_PACKET" end
  if p.destination~="*" and p.destination~=M.nodeId then return nil,"NOT_FOR_US" end
  if M.seen[p.id] then return nil,"DUPLICATE" end
  M.seen[p.id]=os.time()
  Registry.touch(p.source,r.sender,p.payload and p.payload.kind)
  if p.type=="HEARTBEAT" then Registry.heartbeat(p.source) end
  return p,r
end

function M.registry() Registry.expire(10); return Registry.all() end

return M
