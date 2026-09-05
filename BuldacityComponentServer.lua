-- BuldacityComponentServer.lua
-- Central component inventory + modem diagnostics for BULDACITY/2.
-- Detects EVERY modem type on the machine (wired/wireless) and exposes it to the UI.

local component=require("component")
local event=require("event")
local computer=require("computer")
local PORT=4242
local PROTOCOL="BULDACITY/2"
local LOG="/home/BuldacityComponents.log"
local REQUEST_INTERVAL=5
local M=_G.BuldacityComponents or {server={},clients={}}
_G.BuldacityComponents=M
M.server=M.server or {};M.clients=M.clients or {};M.modems={}

local function scanModems()
  local list={}
  for addr,kind in component.list("modem",true) do
    local m=component.proxy(addr)
    if m then
      local strength=nil
      local wireless=false
      if type(m.getStrength)=="function" or type(m.setStrength)=="function" then wireless=true end
      if type(m.getStrength)=="function" then pcall(function() strength=m.getStrength() end) end
      if wireless and type(m.setStrength)=="function" then pcall(function() m.setStrength(400) end);pcall(function() strength=m.getStrength() end) end
      pcall(function() m.open(PORT) end)
      list[#list+1]={address=addr,type=kind,wireless=wireless,strength=tonumber(strength) or 0,port=PORT,open=true}
    end
  end
  M.modems=list
  M.modemCount=#list
  M.wirelessCount=0
  for _,m in ipairs(list) do if m.wireless then M.wirelessCount=M.wirelessCount+1 end end
  return list
end

local function scanLocal()
  local list={};local byType={}
  for addr,kind in component.list() do
    list[#list+1]={address=addr,type=kind}
    byType[kind]=(byType[kind] or 0)+1
  end
  table.sort(list,function(a,b) return a.type==b.type and a.address<b.address or a.type<b.type end)
  scanModems()
  M.server={address=computer.address(),uptime=computer.uptime(),count=#list,components=list,byType=byType,modems=M.modems,modemCount=M.modemCount,wirelessCount=M.wirelessCount}
end

local function save()
  scanLocal()
  local f=io.open(LOG,"w");if not f then return end
  f:write("BULDACITY COMPONENT INVENTORY v3\n")
  f:write("SERVER ",tostring(M.server.address)," | ",tostring(M.server.count)," components | MODEMS ",tostring(M.modemCount)," | WIRELESS ",tostring(M.wirelessCount),"\n")
  for _,m in ipairs(M.modems) do f:write("  MODEM ",m.type," = ",m.address," | ",m.wireless and "WIRELESS" or "WIRED"," | strength=",m.strength," | port=",m.port,"\n") end
  for _,c in ipairs(M.server.components or {}) do f:write("  ",tostring(c.type)," = ",tostring(c.address),"\n") end
  f:write("\nCLIENTS\n")
  for addr,d in pairs(M.clients) do
    f:write("CLIENT ",addr," | ",tostring(d.name or "unknown")," | ",tostring(d.count or 0)," components | ",d.wireless and "WIRELESS" or "WIRED"," | MODEMS ",tostring(d.modemCount or 0),"\n")
    for _,m in ipairs(d.modems or {}) do f:write("  MODEM ",m.type," = ",m.address," | ",m.wireless and "WIRELESS" or "WIRED"," | strength=",m.strength or 0,"\n") end
    for _,c in ipairs(d.components or {}) do f:write("  ",tostring(c.type)," = ",tostring(c.address),"\n") end
    f:write("\n")
  end
  f:close()
end

local function packet(kind,data) return {protocol=PROTOCOL,kind=kind,sender=computer.address(),time=computer.uptime(),data=data or {}} end
local function broadcast(kind,data)
  local sent=false
  for _,m in ipairs(M.modems) do local p=component.proxy(m.address);if p then local ok=pcall(function() p.open(PORT);return p.broadcast(PORT,packet(kind,data)) end);sent=sent or ok end end
  return sent
end

event.listen("modem_message",function(_,receiver,sender,port,distance,p)
  if port~=PORT or type(p)~="table" or p.protocol~=PROTOCOL then return end
  if p.kind=="COMPONENT_DATA" and type(p.data)=="table" then
    local d=p.data;local c=M.clients[sender] or {}
    for k,v in pairs(d) do c[k]=v end
    c.address=sender;c.distance=tonumber(distance) or 0;c.last=computer.uptime();c.wireless=c.distance>0 or d.wireless==true
    M.clients[sender]=c;save()
  end
end)

local function requestAll()
  scanModems()
  broadcast("COMPONENT_REQUEST",{requestId=tostring(math.floor(computer.uptime()*1000)),serverAddress=computer.address()})
  save()
end

requestAll()
M.timer=M.timer or event.timer(REQUEST_INTERVAL,requestAll,math.huge)
return M
