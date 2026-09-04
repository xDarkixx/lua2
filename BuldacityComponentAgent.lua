-- BuldacityComponentAgent.lua
-- BULDACITY/2 client hardware inventory agent.
-- v2: opens and uses every attached modem (wired + wireless).
local component=require("component")
local event=require("event")
local computer=require("computer")
local PORT=4242;local PROTOCOL="BULDACITY/2";local VERSION="2.0"
local function modems()local r={};for a in component.list("modem",true)do local m=component.proxy(a);if m then r[#r+1]=m end end;return r end
local ms=modems();if#ms==0 then io.stderr:write("BULDACITY COMPONENT AGENT: no modem found\n");return end
for _,m in ipairs(ms)do pcall(function()m.open(PORT)end);if type(m.setStrength)=="function"then pcall(function()m.setStrength(400)end)end end
local function address()local ok,a=pcall(computer.address);return ok and a or"unknown"end
local function inventory()local r={};for a,k in component.list()do r[#r+1]={address=a,type=k}end;table.sort(r,function(a,b)return a.type==b.type and a.address<b.address or a.type<b.type end);return r end
local function reportPacket()local list=inventory();local byType={};for _,c in ipairs(list)do byType[c.type]=(byType[c.type]or 0)+1 end;return{protocol=PROTOCOL,kind="COMPONENT_DATA",sender=address(),time=computer.uptime(),data={requestId="broadcast",agentVersion=VERSION,clientAddress=address(),uptime=computer.uptime(),count=#list,components=list,byType=byType}}end
local function broadcast()local p=reportPacket();for _,m in ipairs(modems())do pcall(function()m.open(PORT);m.broadcast(PORT,p)end)end end
local function send(server,data)for _,m in ipairs(modems())do pcall(function()m.open(PORT);m.send(server,PORT,{protocol=PROTOCOL,kind="COMPONENT_DATA",sender=address(),time=computer.uptime(),data=data})end)end end
event.listen("modem_message",function(_,receiver,sender,port,distance,p)if port~=PORT or type(p)~="table"or p.protocol~=PROTOCOL then return end;if p.kind=="COMPONENT_REQUEST"then local list=inventory();local byType={};for _,c in ipairs(list)do byType[c.type]=(byType[c.type]or 0)+1 end;send(sender,{requestId=p.data and p.data.requestId or"request",agentVersion=VERSION,clientAddress=address(),uptime=computer.uptime(),count=#list,components=list,byType=byType})end end)
broadcast();event.timer(10,broadcast,math.huge)
