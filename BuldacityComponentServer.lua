-- BuldacityComponentServer.lua
-- Central inventory + modem diagnostics for BULDACITY/2.
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
 local r={}
 for a,k in component.list("modem",true)do local m=component.proxy(a);if m then local w=type(m.setStrength)=="function"or type(m.getStrength)=="function";local s=0;local opened=pcall(function()m.open(PORT)end);if w and type(m.setStrength)=="function"then pcall(function()m.setStrength(400)end)end;if w and type(m.getStrength)=="function"then pcall(function()s=tonumber(m.getStrength())or 0 end)end;r[#r+1]={address=a,type=tostring(k),wireless=w,strength=s,port=PORT,open=opened}end end
 M.modems=r;M.modemCount=#r;M.wirelessCount=0;for _,m in ipairs(r)do if m.wireless then M.wirelessCount=M.wirelessCount+1 end end;return r
end
local function scanLocal()
 local list={};local byType={};for a,k in component.list()do list[#list+1]={address=a,type=tostring(k)};byType[k]=(byType[k]or 0)+1 end;table.sort(list,function(a,b)return a.type==b.type and a.address<b.address or a.type<b.type end);scanModems();M.server={address=computer.address(),uptime=computer.uptime(),count=#list,components=list,byType=byType,modems=M.modems,modemCount=M.modemCount,wirelessCount=M.wirelessCount}
end
local function save()
 scanLocal();local f=io.open(LOG,"w");if not f then return end;f:write("BULDACITY COMPONENT INVENTORY v4\n");f:write("SERVER ",tostring(M.server.address)," | ",tostring(M.server.count)," components | MODEMS ",tostring(M.modemCount)," | WIRELESS ",tostring(M.wirelessCount),"\n");for _,m in ipairs(M.modems)do f:write("  MODEM ",m.type," = ",m.address," | ",m.wireless and"WIRELESS"or"WIRED"," | strength=",m.strength," | port=",m.port," | open=",tostring(m.open),"\n")end;for _,c in ipairs(M.server.components or{})do f:write("  ",c.type," = ",c.address,"\n")end;f:write("\nCLIENTS\n");for addr,d in pairs(M.clients)do f:write("CLIENT ",addr," | ",tostring(d.name or"unknown")," | ",tostring(d.count or 0)," components | ",d.wireless and"WIRELESS"or"WIRED"," | MODEMS ",tostring(d.modemCount or 0)," | last=",tostring(d.last or 0),"\n");for _,m in ipairs(d.modems or{})do f:write("  MODEM ",m.type," = ",m.address," | ",m.wireless and"WIRELESS"or"WIRED"," | strength=",m.strength or 0," | open=",tostring(m.open),"\n")end end;f:close()
end
local function packet(kind,data)return{protocol=PROTOCOL,kind=kind,sender=computer.address(),time=computer.uptime(),data=data or{}}end
local function broadcast(kind,data)local sent=0;for _,m in ipairs(M.modems)do local p=component.proxy(m.address);if p then local ok,res=pcall(function()return p.broadcast(PORT,packet(kind,data))end);if ok and res~=false then sent=sent+1 end end end;return sent>0 end
event.listen("modem_message",function(_,receiver,sender,port,distance,p)if port~=PORT or type(p)~="table"or p.protocol~=PROTOCOL then return end;if p.kind=="COMPONENT_DATA"and type(p.data)=="table"then local d=p.data;local c=M.clients[sender]or{};for k,v in pairs(d)do c[k]=v end;c.address=sender;c.distance=tonumber(distance)or 0;c.last=computer.uptime();c.wireless=c.distance>0 or d.wireless==true;c.result=c.modemCount and c.modemCount>0 and"PASS"or"NO_MODEM";M.clients[sender]=c;save()end end)
local function requestAll()scanModems();local id=tostring(math.floor(computer.uptime()*1000));broadcast("COMPONENT_REQUEST",{requestId=id,serverAddress=computer.address(),scan="ALL_MODEMS"});M.lastScan={stage="REQUEST_BROADCAST",ok=M.modemCount>0,time=computer.uptime(),requestId=id};save()end
requestAll();M.timer=M.timer or event.timer(REQUEST_INTERVAL,requestAll,math.huge);return M
