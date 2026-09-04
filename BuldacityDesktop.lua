-- BuldacityDesktop.lua
-- BULDACITY OS Tier-3 central desktop for OpenComputers 1.7.10.
-- All BULDACITY programs are loaded from /home.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local shell=require("shell")
local network=require("Network")
local gpu=component.gpu

local HOME="/home/"
local PORT=4242
local VERSION="8.1"
pcall(function() shell.setWorkingDirectory(HOME) end)
package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")

local W,H=gpu.getResolution()
local page="DESKTOP"
local selected=1
local appSelected=1
local componentSelected=1
local running=true
local dirty=true
local status="STARTING"
local devices={}
local frames={}
local frameSize={}
local logs={}
local pingId=0
local lastScan=0
local reactor={}

local C={bg=0x060A12,bar=0x0B1220,panel=0x111B2B,panel2=0x192944,line=0x29415F,
 cyan=0x00E5FF,purple=0xA66CFF,pink=0xFF3EBB,green=0x35F59A,yellow=0xFFD34E,
 red=0xFF5572,white=0xEAF6FF,dim=0x71859E,orange=0xFF9D45}
local function now() return computer.uptime() end
local function fit(s,n) s=tostring(s or "");n=math.max(1,n or 1);if #s<=n then return s end;if n<=1 then return s:sub(1,1) end;return s:sub(1,n-1).."…" end
local function clamp(v,a,b) v=tonumber(v) or a;return math.max(a,math.min(b,v)) end
local function fill(x,y,w,h,c) if x<1 then w=w+x-1;x=1 end;if y<1 then h=h+y-1;y=1 end;if x<=W and y<=H and w>0 and h>0 then gpu.setBackground(c or C.bg);gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ") end end
local function text(x,y,s,fg,bg) if x>=1 and y>=1 and x<=W and y<=H then gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or "")) end end
local function rule(x,y,w,c) fill(x,y,w,1,c or C.line) end
local function log(s) table.insert(logs,1,os.date("%H:%M:%S").."  "..tostring(s));if #logs>30 then table.remove(logs) end;dirty=true end
local function panel(x,y,w,h,title,c) fill(x,y,w,h,C.panel);fill(x,y,w,1,c or C.cyan);text(x+2,y+1,"◆ "..fit(title,w-5),c or C.cyan,C.panel);if h>3 then rule(x+2,y+2,w-4,C.line) end end
local function button(x,y,w,label,c,active) local bg=active and C.panel2 or C.bar;fill(x,y,w,3,bg);fill(x,y,w,1,c or C.cyan);text(x+2,y+1,fit(label,w-4),active and C.white or (c or C.cyan),bg) end
local function online(d) return d and now()-(d.last or 0)<12 end
local function listDevices() local r={};for _,d in pairs(devices) do r[#r+1]=d end;table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address) end);return r end
local function selectedDevice() local l=listDevices();if #l==0 then return nil end;selected=clamp(selected,1,#l);return l[selected] end
local function componentList(d)
 local r={}
 if d and type(d.components)=="table" then for _,c in ipairs(d.components) do if type(c)=="table" then r[#r+1]=c end end end
 table.sort(r,function(a,b) if tostring(a.type)==tostring(b.type) then return tostring(a.address)<tostring(b.address) end return tostring(a.type)<tostring(b.type) end)
 return r
end
local function syncComponentInventory()
 local inv=_G.BuldacityComponents
 if type(inv)~="table" then return end
 for address,d in pairs(inv.clients or {}) do
  if type(d)=="table" then
   devices[address]=devices[address] or {address=address}
   local localD=devices[address]
   for k,v in pairs(d) do localD[k]=v end
   localD.address=address
   if d.last then localD.last=tonumber(d.last) or localD.last end
   localD.componentCount=tonumber(d.count) or (type(d.components)=="table" and #d.components or 0)
  end
 end
end

local function remember(sender,p,distance)
 if not sender or not p then return end
 local d=devices[sender] or {address=sender};devices[sender]=d
 local data=type(p.data)=="table" and p.data or {}
 for k,v in pairs(data) do d[k]=v end
 d.address=sender;d.last=now();d.distance=tonumber(distance) or 0
 d.wireless=d.distance>0 or data.wireless==true
 d.link=d.wireless and "WIRELESS" or "WIRED"
 if p.kind=="LINK_CONFIRM" then d.linked=true;d.result="LINKED" end
 if p.kind=="PONG" then d.lastPong=now();d.result=d.linked and "LINKED" or "PASS";if d.pingSent then d.latency=(now()-d.pingSent)*1000 end end
 if type(data.reactor)=="table" and data.reactor.available then reactor=data.reactor end
 dirty=true
end

local function syncDiagnostics()
 local ok,diag=pcall(network.getDiagnostics)
 if not ok or type(diag)~="table" then return end
 for address,d in pairs(diag) do
  if type(d)=="table" then
   devices[address]=devices[address] or {address=address}
   local localD=devices[address]
   for k,v in pairs(d) do localD[k]=v end
   localD.address=address
   localD.last=tonumber(d.last) or localD.last or 0
   localD.distance=tonumber(d.distance) or 0
   localD.wireless=localD.wireless==true or localD.distance>0
   localD.link=localD.wireless and "WIRELESS" or "WIRED"
   localD.linked=d.linked==true or d.result=="LINKED"
  end
 end
 syncComponentInventory()
end

local function scan()
 syncDiagnostics()
 network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol="BULDACITY/2",port=PORT,discover=true})
 for _,d in ipairs(listDevices()) do
  if online(d) then pingId=pingId+1;d.pingSent=now();d.testStatus="TESTING";network.send(d.address,"PING",{from="BULDACITY OS",id=pingId}) end
 end
 lastScan=now();status="DISCOVERY SENT";log("Discovery + ping broadcast sent")
end

local function localApps()
 local r={}
 local ok,it=pcall(filesystem.list,HOME)
 if not ok or not it then return r end
 while true do
  local ok2,f=pcall(it)
  if not ok2 or not f then break end
  f=tostring(f):gsub("/$","")
  if f:match("_Modern%.lua$") or f=="BuldacityApps_Modern.lua" or f=="BuldacityNetworkTest.lua" or f=="BuldacityWirelessCheck_Modern.lua" or f=="ReactorBigReactors043A_Touch_Responsive.lua" then r[#r+1]=f end
 end
 table.sort(r);return r
end
local function launchApp()
 local f=localApps()[appSelected]
 if not f then status="NO APP";return end
 status="STARTING APP";log("Launching /home/"..f)
 local ok,err=pcall(dofile,HOME..f)
 if not ok then status="APP ERROR";log("APP ERROR: "..tostring(err)) else status="APP EXIT" end
 dirty=true
end
local function requestScreen(d) if d and online(d) then network.send(d.address,"SCREEN_REQUEST",{from="BULDACITY OS"}) end end

local function top(title,sub)
 fill(1,1,W,5,C.bar);fill(1,5,W,1,C.cyan);text(2,2,"◈ BULDACITY",C.cyan,C.bar);text(17,2,title,C.white,C.bar);text(2,3,fit(sub,W-30),C.dim,C.bar);text(math.max(1,W-27),2,"● SERVER ONLINE",C.green,C.bar);text(math.max(1,W-13),3,os.date("%H:%M"),C.white,C.bar)
end
local function taskbar()
 fill(1,H-3,W,4,C.bar)
 local items={{"HOME","DESKTOP"},{"NET","NETWORK"},{"DEV","DEVICES"},{"APP","APPS"},{"PC","REMOTE"},{"RX","REACTOR"}}
 local x=2;for _,v in ipairs(items) do local a=page==v[2];text(x,H-1,"["..v[1].."]",a and C.cyan or C.dim,C.bar);x=x+10 end
 text(math.max(1,W-24),H-1,fit(status,20),status=="APP ERROR" and C.red or C.green,C.bar)
end

local function desktop()
 top("DESKTOP","WORKSPACE // REAL-TIME CLIENT FLEET")
 local l=listDevices();local up=0;for _,d in ipairs(l) do if online(d) then up=up+1 end end
 panel(3,7,25,11,"SYSTEM",C.cyan);text(6,10,"CLIENTS",C.dim);text(16,10,up.." / "..#l,C.cyan);text(6,12,"NETWORK",C.dim);text(16,12,"BULDACITY/2",C.green);text(6,14,"PORT",C.dim);text(16,14,PORT,C.yellow);text(6,16,"SCAN",C.dim);text(16,16,lastScan>0 and string.format("%.0fs ago",now()-lastScan) or "never",C.white);button(5,18,21,"SCAN CLIENTS",C.cyan)
 panel(31,7,24,11,"PC FLEET",C.purple);text(34,10,"LINKED",C.dim);local linked=0;for _,d in ipairs(l) do if d.linked then linked=linked+1 end end;text(44,10,linked,C.green);text(34,12,"ONLINE",C.dim);text(44,12,up,C.cyan);text(34,14,"OFFLINE",C.dim);text(44,14,#l-up,C.red);text(34,16,"COMPONENTS",C.dim);local cc=0;for _,d in ipairs(l) do cc=cc+(tonumber(d.componentCount) or 0) end;text(44,16,cc,C.purple)
 panel(61,7,18,11,"QUICK",C.pink);button(63,10,14,"[APP] APPS",C.pink);button(63,14,14,"[PC] REMOTE",C.cyan);button(63,18,14,"[RX] REACTOR",C.green)
 panel(3,21,76,12,"LIVE CLIENTS",C.green)
 if #l==0 then text(7,26,"NO CLIENTS YET",C.yellow);text(7,28,"Press R or click SCAN CLIENTS. Check /home/autorun.lua on each client.",C.dim) end
 for i,d in ipairs(l) do if i>7 then break end;local y=21+i;local st=online(d) and (d.linked and "LINKED" or d.result or "ONLINE") or "OFFLINE";local sc=st=="LINKED" and C.green or st=="OFFLINE" and C.red or C.yellow;text(6,y,string.format("%02d",i),C.dim);text(11,y,fit(d.name or "CLIENT",25),C.white);text(38,y,fit(d.controller or d.app or "NETWORK",18),C.dim);text(58,y,fit(d.link or "--",9),d.wireless and C.purple or C.cyan);text(68,y,st,sc) end
 panel(3,35,76,math.max(5,H-38),"EVENT LOG",C.yellow);for i=1,math.min(#logs,H-40) do text(6,35+i,fit(logs[i],W-10),C.dim) end;taskbar()
end

local function networkPage()
 top("NETWORK","DISCOVERY // WIRED + WIRELESS + RELAY")
 local ns=network.status();local inv=_G.BuldacityComponents or {};local sc=inv.server or {};panel(3,7,76,8,"NETWORK CORE",C.cyan);text(6,10,"PORT",C.dim);text(14,10,PORT,C.yellow);text(25,10,"LOCAL",C.dim);text(33,10,ns.wireless and "WIRELESS" or "WIRED",ns.wireless and C.purple or C.cyan);text(49,10,"RELAY",C.dim);text(57,10,ns.relayPathType or "NONE",ns.relayDetected and C.green or C.dim);text(6,12,"SERVER COMPONENTS",C.dim);text(25,12,tostring(sc.count or 0),C.purple);text(37,12,"CLIENT INVENTORIES",C.dim);text(58,12,tostring((function() local n=0;for _ in pairs(inv.clients or {}) do n=n+1 end;return n end)()),C.green);button(62,12,14,"SCAN",C.yellow)
 panel(3,17,76,math.max(8,H-21),"CLIENT DIAGNOSTICS",C.purple);local l=listDevices();if #l==0 then text(7,22,"No HELLO/HEARTBEAT received.",C.yellow) end
 for i,d in ipairs(l) do local y=19+i;if y>H-6 then break end;local st=online(d) and (d.linked and "LINKED" or d.result or "ONLINE") or "OFFLINE";local cs=st=="LINKED" and C.green or st=="OFFLINE" and C.red or C.yellow;text(6,y,fit(d.name or "CLIENT",20),C.white);text(27,y,st,cs);text(38,y,fit(d.link or "--",9),d.wireless and C.purple or C.cyan);text(48,y,tostring(d.distance or 0),C.yellow);text(55,y,d.latency and string.format("%.0fms",d.latency) or "--",C.white);text(65,y,tostring(d.componentCount or 0),C.purple) end;taskbar()
end

local function devicesPage()
 top("DEVICES","DEVICE MANAGER // CLIENT + COMPONENT IDS")
 local l=listDevices();panel(3,7,38,H-11,"CLIENT PCs",C.purple);if #l==0 then text(7,12,"No clients discovered.",C.yellow) end
 for i,d in ipairs(l) do local y=9+i;if y>H-6 then break end;local a=i==selected;if a then fill(5,y,34,2,C.panel2);fill(5,y,2,2,C.cyan) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(d.name or "CLIENT",16),a and C.cyan or C.white);text(31,y,online(d) and "ON" or "OFF",online(d) and C.green or C.red) end
 local d=selectedDevice();panel(43,7,36,H-11,"COMPONENT INVENTORY",C.cyan)
 if d then
  text(46,10,"PC",C.dim);text(51,10,fit(d.name or d.address,25),C.white);text(46,12,"PC ADDRESS",C.dim);text(46,13,fit(d.address,30),C.cyan);text(46,15,"COMPONENTS",C.dim);text(58,15,tostring(d.componentCount or 0),C.purple)
  local cl=componentList(d);componentSelected=clamp(componentSelected,1,math.max(1,#cl));if #cl==0 then text(46,18,"Waiting for component inventory...",C.yellow) else for i,c in ipairs(cl) do local y=17+i;if y>H-5 then break end;local a=i==componentSelected;if a then fill(45,y,31,2,C.panel2) end;text(47,y,fit(c.type or "unknown",12),a and C.cyan or C.white);text(60,y,fit(c.address or "?",16),C.dim) end end
  text(46,H-5,"↑/↓ select component",C.dim)
 else text(46,12,"Select a client PC.",C.yellow) end
taskbar()
end

local function appsPage()
 top("APPS","APPLICATION CENTER // /home")
 local f=localApps();panel(3,7,76,H-11,"INSTALLED BULDACITY APPS",C.pink);if #f==0 then text(7,12,"No BULDACITY apps found in /home.",C.yellow) end
 appSelected=clamp(appSelected,1,math.max(1,#f));for i,name in ipairs(f) do local y=9+i;if y>H-7 then break end;local a=i==appSelected;if a then fill(5,y,70,2,C.panel2);fill(5,y,2,2,C.pink) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(name,52),a and C.white or C.dim);text(68,y,"RUN",C.green) end;text(7,H-5,"ENTER / click = launch from /home",C.dim);taskbar()
end

local function remotePage()
 top("REMOTE","REMOTE PC // LIVE DESKTOP")
 local d=selectedDevice();if not d then panel(3,7,76,H-11,"REMOTE DISPLAY",C.cyan);text(7,13,"No client selected.",C.yellow);taskbar();return end
 panel(3,7,59,H-11,"LIVE DESKTOP",C.cyan);local f=frames[d.address];if not f then text(7,13,"Requesting /home client screen...",C.dim);requestScreen(d) else local sz=frameSize[d.address] or {w=0,h=0};text(6,10,"LIVE "..sz.w.."x"..sz.h,C.green);local syStep=math.max(1,math.ceil((sz.h or 1)/20));local sxStep=math.max(1,math.ceil((sz.w or 1)/54));local yy=12;for sy=1,sz.h,syStep do if yy>H-6 then break end;local row=f[sy] or {};local out="";for sx=1,sz.w,sxStep do local cell=row[sx];if type(cell)=="table" then out=out..tostring(cell[1] or cell.ch or " ") else out=out.." " end end;text(6,yy,fit(out,55),C.white);yy=yy+1 end end
 panel(64,7,15,H-11,"INPUT",C.purple);button(66,11,11,"UP",C.cyan);button(66,15,11,"DOWN",C.cyan);button(66,19,11,"LEFT",C.cyan);button(66,23,11,"RIGHT",C.cyan);button(66,27,11,"ENTER",C.green);button(66,31,11,"CLICK",C.pink);text(66,35,"R refresh",C.dim);taskbar()
end

local function reactorPage()
 top("REACTOR","BIG REACTORS // REMOTE CONTROL")
 panel(3,7,76,10,"REACTOR STATUS",C.green);if not reactor.available then text(7,12,"Waiting for Big Reactors telemetry...",C.dim) else text(7,10,"STATUS",C.dim);text(18,10,reactor.active and "RUNNING" or "STOPPED",reactor.active and C.green or C.red);text(38,10,"FUEL",C.dim);text(48,10,string.format("%.0f / %.0f",reactor.fuel or 0,reactor.fuelMax or 0),C.yellow);text(7,12,"TEMP",C.dim);text(18,12,string.format("%.1f",reactor.temperature or 0),C.orange);text(38,12,"ENERGY",C.dim);text(48,12,tostring(reactor.energy or 0),C.cyan) end
 text(7,20,"Use the Big Reactors controller on the selected client PC.",C.dim);taskbar()
end

local function render()
 W,H=gpu.getResolution();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");syncDiagnostics()
 if page=="DESKTOP" then desktop() elseif page=="NETWORK" then networkPage() elseif page=="DEVICES" then devicesPage() elseif page=="APPS" then appsPage() elseif page=="REMOTE" then remotePage() elseif page=="REACTOR" then reactorPage() else page="DESKTOP";desktop() end;dirty=false
end

local ok,mode=network.startServer(function(sender,p,distance)
 remember(sender,p,distance)
 if p.kind=="SCREEN_BEGIN" and type(p.data)=="table" then frames[sender]={};frameSize[sender]={w=tonumber(p.data.width) or W,h=tonumber(p.data.height) or H};dirty=true
 elseif p.kind=="SCREEN_ROW" and type(p.data)=="table" then frames[sender]=frames[sender] or {};frames[sender][tonumber(p.data.y) or 1]=p.data.cells or {};dirty=true
 elseif p.kind=="SCREEN_END" then dirty=true
 elseif p.kind=="REACTOR_TELEMETRY" and type(p.data)=="table" then reactor=p.data;dirty=true end
end)
if not ok then error("BULDACITY: modem/network card required: "..tostring(mode)) end
network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol="BULDACITY/2",port=PORT,discover=true})
log("BULDACITY OS v"..VERSION.." started; discovery + component inventory active")

event.timer(2,function() syncDiagnostics();dirty=true end,math.huge)
event.timer(4,function() scan() end,math.huge)
event.timer(2,function() local d=selectedDevice();if d and online(d) and (d.mod=="Big Reactors" or tostring(d.name):find("Reactor")) then network.send(d.address,"REACTOR_REQUEST",{from="BULDACITY OS"}) end end,math.huge)

while running do
 if dirty then render() end
 local e,a,b,c,d=event.pull(0.20)
 if e=="key_down" then
  local char,code=b,c
  if code==16 or char==113 or char==81 then running=false
  elseif char==49 or code==2 then page="DESKTOP"
  elseif char==50 or code==3 then page="NETWORK"
  elseif char==51 or code==4 then page="DEVICES"
  elseif char==52 or code==5 then page="APPS"
  elseif char==53 or code==6 then page="REMOTE"
  elseif char==54 or code==7 then page="REACTOR"
  elseif char==114 or char==82 then scan()
  elseif code==200 then if page=="DEVICES" then selected=math.max(1,selected-1) elseif page=="APPS" then appSelected=math.max(1,appSelected-1) end
  elseif code==208 then if page=="DEVICES" then selected=math.min(#listDevices(),selected+1) elseif page=="APPS" then appSelected=appSelected+1 end
  elseif code==28 then if page=="APPS" then launchApp() elseif page=="DEVICES" then page="REMOTE" end
  elseif char==114 or char==82 then scan() end
  dirty=true
 elseif e=="touch" then
  local x,y,button=b,c,d
  if y>=H-3 then if x<12 then page="DESKTOP" elseif x<22 then page="NETWORK" elseif x<32 then page="DEVICES" elseif x<42 then page="APPS" elseif x<52 then page="REMOTE" elseif x<62 then page="REACTOR" end
  elseif page=="DESKTOP" and x>=5 and x<=26 and y>=18 and y<=20 then scan()
  elseif page=="NETWORK" and x>=60 and y>=12 and y<=15 then scan()
  elseif page=="DEVICES" then if x<42 and y>=10 and y<10+#listDevices() then selected=clamp(y-9,1,#listDevices()) elseif x>=43 and y>=7 then page="REMOTE" end
  elseif page=="APPS" and y>=10 and y<10+#localApps() then appSelected=clamp(y-9,1,#localApps());launchApp()
  elseif page=="REMOTE" then local rd=selectedDevice();if rd and x>=64 then local kind;if y<15 then kind="UP" elseif y<19 then kind="DOWN" elseif y<23 then kind="LEFT" elseif y<27 then kind="RIGHT" elseif y<31 then kind="ENTER" else kind="touch" end;network.send(rd.address,"INPUT",{event=kind,x=x,y=y,button=button}) elseif rd then network.send(rd.address,"INPUT",{event="touch",x=x,y=y,button=button}) end end
  dirty=true
 elseif e=="scroll" and page=="REMOTE" then local rd=selectedDevice();if rd then network.send(rd.address,"INPUT",{event="scroll",x=b,y=c,button=d}) end;dirty=true
 end
end

gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");text(3,3,"BULDACITY OS stopped.",C.cyan,C.bg)
