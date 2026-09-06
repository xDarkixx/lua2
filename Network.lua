-- Network.lua
-- Single public Network API. Legacy transport is removed.
-- All traffic is handled by the Modern network and TIER3-CORE.
local Modern=require("network-modern.Network")
local Protocol=require("network-modern.Protocol")
local Registry=require("network-modern.Registry")
local component=require("component")
local computer=require("computer")
local M={PROTOCOL=Protocol.NAME,VERSION=Protocol.VERSION,PORT=Protocol.PORT,TIMEOUT=12,MAX_WIRELESS_STRENGTH=400,serverAddress=nil,linked=false,linkSince=0,lastPacketDistance=0,diagnostics={},lastScan={}}
local function addr()local ok,a=pcall(computer.address);return ok and a or "unknown"end
local function modems()local r={};for a in component.list("modem",true)do local ok,p=pcall(component.proxy,a);if ok and p then r[#r+1]=p end end;return r end
local function isWireless(m)return type(m.setStrength)=="function" or type(m.getStrength)=="function"end
function M.address()return addr()end
function M.init(_)local ms=modems();for _,m in ipairs(ms)do pcall(m.open,M.PORT)end;local ok,err=Modern.init(nil,Protocol.PORT);M.lastScan={stage=ok and "MODERN_NETWORK_READY" or "NO_MODEM",ok=ok,time=computer.uptime(),modemCount=#ms,error=err};return ok,ok and "MODERN" or err end
function M.packet(kind,data)return Protocol.new(kind,addr(),"*",string.format("%s-%d",addr(),math.floor(computer.uptime()*1000)),data or {})end
function M.valid(p)if type(p)~="table"then return false end;local ok=Protocol.valid(p);return ok==true end
function M.send(target,kind,data)if not target then return false,"NO_ADDRESS"end;local ok,err=Modern.send(kind,"*",data or{},target);if ok then M.serverAddress=target end;return ok,err end
function M.sendReliable(target,kind,data)if not target then return false,"NO_ADDRESS"end;return Modern.sendReliable(kind,"*",data or{},target)end
function M.broadcast(kind,data)return Modern.send(kind,"*",data or{})end
function M.setWirelessStrength(n)n=tonumber(n);if not n then return false,"BAD_STRENGTH"end;local found=false;for _,m in ipairs(modems())do if type(m.setStrength)=="function"then local ok=pcall(m.setStrength,math.max(0,n));found=found or ok end end;return found,M.getWirelessStrength()end
function M.getWirelessStrength()local best=0;for _,m in ipairs(modems())do if type(m.getStrength)=="function"then local ok,s=pcall(m.getStrength);if ok and tonumber(s)and tonumber(s)>best then best=tonumber(s)end end end;return best end
function M.componentCheck()local ms=modems();local w=false;for _,m in ipairs(ms)do if isWireless(m)then w=true;break end end;return{ok=#ms>0,modemCount=#ms,modems=ms,wirelessAvailable=w,wirelessReady=w,wirelessStrength=M.getWirelessStrength(),protocol=M.PROTOCOL,port=M.PORT}end
function M.status()local s=Modern.status();local c=M.componentCheck();for k,v in pairs(c)do s[k]=v end;s.protocol=M.PROTOCOL;s.port=M.PORT;s.serverAddress=Modern.serverAddress or M.serverAddress;s.diagnostics=M.diagnostics;s.lastScan=M.lastScan;return s end
function M.getDiagnostics()local r={};for a,d in pairs(M.diagnostics)do r[a]=d end;for a,d in pairs(Registry.all())do r[a]=d end;return r end
local function legacy(p)local d=p and(p.payload or p.data)or{};return{protocol=M.PROTOCOL,kind=p and(p.type or p.kind),type=p and(p.type or p.kind),sender=p and(p.source or p.sender),source=p and p.source,destination=p and p.destination,id=p and p.id,hops=p and p.hops,ttl=p and p.ttl,time=computer.uptime(),data=d,payload=d,senderAddress=p and p.source}end

-- Remote screen snapshot support. OpenComputers exposes the character/color
-- cells through gpu.get(x,y); we send small row chunks through UI_FRAME so the
-- browser can reconstruct the same terminal surface without changing a Modern controller.
local function sendScreen(target)
 if not target or not component.isAvailable("gpu") then return false,"NO_GPU" end
 local g=component.gpu;local sw,sh=g.getResolution();local w=math.min(sw,80);local h=math.min(sh,40)
 local rows={}
 for y=1,h do
   local cells={}
   for x=1,w do
     local ok,ch,fg,bg=pcall(g.get,x,y)
     if ok then cells[x]={ch or " ",fg or 0xFFFFFF,bg or 0} else cells[x]={" ",0xFFFFFF,0} end
   end
   rows[#rows+1]={y=y,cells=cells}
   if #rows>=2 or y==h then
     local ok=Modern.send("UI_FRAME",target,{kind="TEXT_SCREEN",nodeId=addr(),width=w,height=h,rows=rows},target)
     if not ok then return false,"UI_SEND_FAILED" end
     rows={}
   end
 end
 return true
end
function M.startClient(name,extra,callback)
 local function cb(p,sender,distance)
   M.serverAddress=Modern.serverAddress or M.serverAddress;M.lastPacketDistance=tonumber(distance)or 0
   local q=legacy(p);if q and q.sender then local d=M.diagnostics[q.sender]or{address=q.sender};d.last=computer.uptime();d.distance=M.lastPacketDistance;d.result="ONLINE";M.diagnostics[q.sender]=d end
   if q and q.kind=="SCREEN_REQUEST" then sendScreen(sender) end
   if callback then pcall(callback,q,sender,distance)end
 end
 return Modern.startClient(name or"MODERN CONTROLLER",extra or{},cb)
end
function M.startServer(callback)
 local function cb(p,sender,distance)M.lastPacketDistance=tonumber(distance)or 0;local q=legacy(p);local source=q and q.sender or sender;if source then local d=M.diagnostics[source]or{address=source};d.last=computer.uptime();d.distance=M.lastPacketDistance;d.result="ONLINE";if q.data then for k,v in pairs(q.data)do d[k]=v end end;M.diagnostics[source]=d end;if callback then pcall(callback,q,sender,distance)end end
 local ok,err=Modern.startServer(cb);M.serverAddress=Modern.serverAddress;return ok,err
end
return M
