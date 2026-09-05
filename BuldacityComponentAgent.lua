-- BuldacityComponentAgent.lua
-- BULDACITY/2 client inventory + real OpenComputers modem diagnostics.
local component=require("component")
local event=require("event")
local computer=require("computer")
local PORT=4242
local PROTOCOL="BULDACITY/2"
local VERSION="4.0"
local function address()local ok,a=pcall(computer.address);return ok and a or"unknown"end
local function modems()
 local r={}
 for a,k in component.list("modem",true)do local m=component.proxy(a);if m then local w=type(m.setStrength)=="function"or type(m.getStrength)=="function";local s=0;local opened=pcall(function()m.open(PORT)end);if w and type(m.setStrength)=="function"then pcall(function()m.setStrength(400)end)end;if w and type(m.getStrength)=="function"then pcall(function()s=tonumber(m.getStrength())or 0 end)end;r[#r+1]={address=a,type=tostring(k),wireless=w,strength=s,port=PORT,open=opened}end end
 return r
end
local function inventory()local r={};for a,k in component.list()do r[#r+1]={address=a,type=tostring(k)}end;table.sort(r,function(a,b)return a.type==b.type and a.address<b.address or a.type<b.type end);return r end
local function data(requestId)local cs=inventory();local ms=modems();local byType={};local wc=0;for _,c in ipairs(cs)do byType[c.type]=(byType[c.type]or 0)+1 end;for _,m in ipairs(ms)do if m.wireless then wc=wc+1 end end;return{agentVersion=VERSION,clientAddress=address(),uptime=computer.uptime(),count=#cs,components=cs,byType=byType,modems=ms,modemCount=#ms,wirelessCount=wc,wireless=wc>0,wirelessReady=wc>0,requestId=requestId}end
local function packet(kind,d)return{protocol=PROTOCOL,kind=kind,sender=address(),time=computer.uptime(),data=d or{}}end
local function broadcast(kind,d)local sent=0;for _,m in ipairs(modems())do local ok,res=pcall(function()return m.broadcast(PORT,packet(kind,d))end);if ok and res~=false then sent=sent+1 end end;return sent>0 end
local function send(server,d)local sent=0;for _,m in ipairs(modems())do local ok,res=pcall(function()return m.send(server,PORT,packet("COMPONENT_DATA",d))end);if ok and res~=false then sent=sent+1 end end;return sent>0 end
local function report(id)return data(id)end
event.listen("modem_message",function(_,receiver,sender,port,distance,p)if port~=PORT or type(p)~="table"or p.protocol~=PROTOCOL then return end;if p.kind=="COMPONENT_REQUEST"then send(sender,report(p.data and p.data.requestId or"request"))end end)
local ms=modems()
if#ms>0 then broadcast("COMPONENT_DATA",report("broadcast"));event.timer(10,function()broadcast("COMPONENT_DATA",report("broadcast"))end,math.huge)else io.stderr:write("BULDACITY COMPONENT AGENT: NO MODEM DETECTED\n")end
