-- BuldacityComponentServer.lua
-- Central component inventory service for the Tier-3 BULDACITY server.
-- It requests and stores the complete component address/type list from every client.
-- Data is kept in memory and mirrored to /home/BuldacityComponents.log.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")

local PORT=4242
local PROTOCOL="BULDACITY/2"
local LOG="/home/BuldacityComponents.log"
local REQUEST_INTERVAL=5

local M=_G.BuldacityComponents or {clients={}}
_G.BuldacityComponents=M

local function findModem()
  for address in component.list("modem",true) do
    local m=component.proxy(address)
    if m then
      if type(m.setStrength)=="function" then pcall(function() m.setStrength(400) end) end
      return m
    end
  end
  return nil
end

local modem=findModem()
if not modem then
  io.stderr:write("BULDACITY COMPONENT SERVER: no modem found\n")
  return M
end
pcall(function() modem.open(PORT) end)

local function save()
  local f=io.open(LOG,"w")
  if not f then return end
  f:write("BULDACITY COMPONENT INVENTORY v1\n")
  f:write("Updated uptime: ",tostring(computer.uptime()),"\n\n")
  for addr,d in pairs(M.clients) do
    f:write("CLIENT ",addr," | ",tostring(d.name or "unknown")," | ",tostring(d.count or 0)," components\n")
    for _,c in ipairs(d.components or {}) do
      f:write("  ",tostring(c.type)," = ",tostring(c.address),"\n")
    end
    f:write("\n")
  end
  f:close()
end

local function requestAll()
  local id=tostring(math.floor(computer.uptime()*1000))
  pcall(function() modem.broadcast(PORT,{protocol=PROTOCOL,kind="COMPONENT_REQUEST",sender="SERVER",time=computer.uptime(),data={requestId=id}}) end)
end

event.listen("modem_message",function(_,receiver,sender,port,distance,p)
  if port~=PORT or type(p)~="table" or p.protocol~=PROTOCOL then return end
  if p.kind=="COMPONENT_DATA" and type(p.data)=="table" then
    local d=p.data
    local c=M.clients[sender] or {}
    for k,v in pairs(d) do c[k]=v end
    c.address=sender
    c.distance=tonumber(distance) or 0
    c.last=computer.uptime()
    c.wireless=c.distance>0
    M.clients[sender]=c
    save()
  end
end)

if not M.timer then
  M.timer=event.timer(REQUEST_INTERVAL,requestAll,math.huge)
end
requestAll()
save()

return M
