-- BuldacityComponentAgent.lua
-- BULDACITY/2 component inventory agent for OpenComputers 1.7.10.
-- Runs on every CLIENT PC and reports every attached component address/type to the Tier-3 server.
-- All files are loaded from /home.

local component=require("component")
local event=require("event")
local computer=require("computer")

local HOME="/home/"
local PORT=4242
local PROTOCOL="BULDACITY/2"
local AGENT_VERSION="1.0"

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
  io.stderr:write("BULDACITY COMPONENT AGENT: no modem found\n")
  return
end
pcall(function() modem.open(PORT) end)

local function address()
  local ok,a=pcall(computer.address)
  return ok and a or "unknown"
end

local function inventory()
  local list={}
  for addr,kind in component.list() do
    list[#list+1]={address=addr,type=kind}
  end
  table.sort(list,function(a,b)
    if a.type==b.type then return a.address<b.address end
    return a.type<b.type
  end)
  return list
end

local function send(server,kind,data)
  local packet={protocol=PROTOCOL,kind=kind,sender=address(),time=computer.uptime(),data=data or {}}
  local ok,err=pcall(function() modem.send(server,PORT,packet) end)
  return ok,err
end

local function report(server,requestId)
  local list=inventory()
  local byType={}
  for _,c in ipairs(list) do byType[c.type]=(byType[c.type] or 0)+1 end
  send(server,"COMPONENT_DATA",{
    requestId=requestId,
    agentVersion=AGENT_VERSION,
    clientAddress=address(),
    uptime=computer.uptime(),
    count=#list,
    components=list,
    byType=byType
  })
end

event.listen("modem_message",function(_,receiver,sender,port,distance,p)
  if port~=PORT or type(p)~="table" or p.protocol~=PROTOCOL then return end
  if p.kind=="COMPONENT_REQUEST" then
    report(sender,p.data and p.data.requestId or nil)
  end
end)

-- Announce immediately and then periodically so the server can recover after a restart.
local function announce()
  report("", "announce")
end
-- A broadcast is used for the initial announcement because the server address may not be known yet.
local function broadcastReport()
  local list=inventory()
  local byType={}
  for _,c in ipairs(list) do byType[c.type]=(byType[c.type] or 0)+1 end
  local packet={protocol=PROTOCOL,kind="COMPONENT_DATA",sender=address(),time=computer.uptime(),data={requestId="broadcast",agentVersion=AGENT_VERSION,clientAddress=address(),uptime=computer.uptime(),count=#list,components=list,byType=byType}}
  pcall(function() modem.broadcast(PORT,packet) end)
end

broadcastReport()
event.timer(10,broadcastReport,math.huge)
