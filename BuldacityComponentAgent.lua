-- BuldacityComponentAgent.lua
-- BULDACITY/2 client hardware inventory + complete modem diagnostics.
local component=require("component")
local event=require("event")
local computer=require("computer")
local PORT=4242;local PROTOCOL="BULDACITY/2";local VERSION="3.0"
local function modems()local r={};for a,k in component.list("modem",true)do local m=component.proxy(a);if m then local wireless=(type(m.getStrength)=="function" or type(m.setStrength)=="function");local strength=0;if wireless and type(m.setStrength)=="function"then pcall(function()m.setStrength(400)end)end;if wireless and type(m.getStrength)=="function"then pcall(function()strength=m.getStrength()or 0 end)end;pcall(function()m.open(PORT)end);r[#r+1]={address=a,type=k,wireless=wireless,strength=tonumber(strength)or 0,port=PORT,open=true}end end;return r end
local ms=modems()
local function address()local ok,a=pcall(computer.address);return ok and a or"unknown"end
local function inventory()local r={};for a,k in component.list()do r[#r+1]={address=a,type=k}end;table.sort(r,function(a,b)return a.type==b.type and a.address<b.address or a.type<b.type end);return r end
local function data()local list=inventory();local byType={};for _,c in ipairs(list)do byType[c.type]=(byType[c.type]or 0)+1 end;local m=modems();local wireless=false;for _,x in ipairs(m)do wireless=wireless or x.wireless end;return{agentVersion=VERSION,clientAddress=address(),uptime=computer.uptime(),count=#list,components=list,byType=byType,modems=m,modemCount=#m,wirelessCount=(function()local n=0;for _,x in ipairs(m)do if x.wireless then n=n+1 end end;return n end)(),wireless=wireless,wirelessReady=wireless}end
local function packet(sender,kind,d)return{protocol=PROTOCOL,kind=kind,sender=address(),time=computer.uptime(),data=d or {}}end
local function broadcast(kind,d)local p=packet(address(),kind,d);for _,m in ipairs(modems())do pcall(function()m.broadcast(PORT,p)end)end end
local function send(server,d)for _,m in ipairs(modems())do pcall(function()m.send(server,PORT,packet(address(),"COMPONENT_DATA",d))end)end end
local function report(requestId)return data()end
event.listen("modem_message",function(_,receiver,sender,port,distance,p)if port~=PORT or type(p)~="table"or p.protocol~=PROTOCOL then return end;if p.kind=="COMPONENT_REQUEST"then send(sender,report(p.data and p.data.requestId or"request"))end end)
if#ms>0 then broadcast("COMPONENT_DATA",report("broadcast"));event.timer(10,function()broadcast("COMPONENT_DATA",report("broadcast"))end,math.huge)else io.stderr:write("BULDACITY COMPONENT AGENT: NO MODEM DETECTED\n")end
