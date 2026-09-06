-- BULDACITY Modern/Legacy compatibility facade.
-- Keeps existing *_Modern.lua files untouched while routing their legacy
-- Network API through network-modern.Network.
local Modern=require("network-modern.Network")
local Protocol=require("network-modern.Protocol")
local Registry=require("network-modern.Registry")

local M={}
M.PROTOCOL=Protocol.NAME
M.VERSION=Protocol.VERSION
M.PORT=Protocol.PORT

local function normalize(packet,sender,distance)
  if type(packet)~="table" then return nil end
  return {
    kind=packet.type,
    type=packet.type,
    source=packet.source,
    destination=packet.destination,
    id=packet.id,
    hops=packet.hops,
    ttl=packet.ttl,
    data=packet.payload or {},
    payload=packet.payload or {},
    sender=sender,
    distance=distance
  }
end

function M.valid(packet)
  if type(packet)~="table" then return false end
  if packet.kind and not packet.type then packet.type=packet.kind end
  if packet.data and not packet.payload then packet.payload=packet.data end
  return Protocol.valid(packet)
end

function M.send(address,kind,data)
  return Modern.send(kind,address,data,address)
end

function M.sendReliable(address,kind,data)
  return Modern.sendReliable(kind,address,data,address)
end

function M.broadcast(kind,data)
  return Modern.send(kind,"*",data)
end

function M.startServer(callback)
  return Modern.startServer(function(packet,sender,distance)
    if callback then
      local p=normalize(packet,sender,distance)
      if p then pcall(callback,sender,p,distance) end
    end
  end)
end

function M.startClient(name,data,callback)
  return Modern.startClient(name,data,function(packet,sender,distance)
    if callback then
      local p=normalize(packet,sender,distance)
      if p then pcall(callback,p,sender,distance) end
    end
  end)
end

function M.getDiagnostics()
  local result={}
  for _,node in ipairs(Registry.all()) do
    local address=node.address or node.nodeId or node.name
    if address then
      result[address]={}
      for k,v in pairs(node) do result[address][k]=v end
      result[address].address=address
    end
  end
  return result
end

function M.registry()
  return Modern.registry()
end

function M.status()
  return Modern.status()
end

function M.hello()
  return Modern.hello()
end

function M.heartbeat()
  return Modern.heartbeat()
end

return M
