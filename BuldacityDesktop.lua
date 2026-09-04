-- BuldacityDesktop.lua
-- Full graphical desktop shell for BuldacityOS_Tier3.lua
-- Minecraft 1.7.10 / OpenComputers
-- Designed as a real desktop: windows, taskbar, apps, network diagnostics,
-- device manager, remote PC, storage and system monitor.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local network=require("Network")
local gpu=component.gpu

local PORT=4242
local VERSION="7.0"
local ok,mode=network.startServer()
if not ok then error("BULDACITY: modem/network card required") end

local W,H=gpu.getResolution()
local running=true
local page="DESKTOP"
local selected=1
local appSelected=1
local driveSelected=1
local dirty=true
local status="READY"
local devices={}
local logs={}
local frames={}
local frameSize={}
local pingSeq=0
local reactor={}
local lastReactor=0
local lastScan=0
local task={name="BULDACITY OS",page="DESKTOP"}

local C={
 bg=0x060A12,bar=0x0B1220,panel=0x111B2B,panel2=0x192944,line=0x29415F,
 cyan=0x00E5FF,purple=0xA66CFF,pink=0xFF3EBB,green=0x35F59A,yellow=0xFFD34E,
 red=0xFF5572,white=0xEAF6FF,dim=0x71859E,orange=0xFF9D45,black=0x000000
}

local function now() return computer.uptime() end
local function clamp(v,a,b) v=tonumber(v) or 0;return math.max(a,math.min(b,v)) end
local function fit(s,n)
 s=tostring(s or "");n=math.max(1,n or 1)
 if #s<=n then return s end
 if n<=1 then return s:sub(1,1) end
 return s:sub(1,n-1).."…"
end
local function fill(x,y,w,h,c)
 if x<1 then w=w+x-1;x=1 end
 if y<1 then h=h+y-1;y=1 end
 if x<=W and y<=H and w>0 and h>0 then gpu.setBackground(c or C.bg);gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ") end
end
local function text(x,y,s,fg,bg)
 if x>=1 and y>=1 and x<=W and y<=H then gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or "")) end
end
local function rule(x,y,w,c) fill(x,y,w,1,c or C.line) end
local function log(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..tostring(s));if #logs>30 then table.remove(logs) end;dirty=true
end
local function panel(x,y,w,h,title,c)
 fill(x,y,w,h,C.panel);fill(x,y,w,1,c or C.cyan);text(x+2,y+1,"◆ "..fit(title,w-5),c or C.cyan,C.panel)
 if h>3 then rule(x+2,y+2,w-4,C.line) end
end
local function button(x,y,w,label,c,active)
 local bg=active and C.panel2 or C.bar;fill(x,y,w,3,bg);fill(x,y,w,1,c or C.cyan);text(x+2,y+1,fit(label,w-4),active and C.white or (c or C.cyan),bg)
end
local function bar(x,y,w,v,m,c)
 local p=(tonumber(m) or 0)>0 and clamp((tonumber(v) or 0)/m,0,1) or 0;fill(x,y,w,2,C.bar);if p>0 then fill(x,y,math.max(1,math.floor(w*p)),2,c or C.cyan) end
end
local function online(d) return d and now()-(d.last or 0)<12 end
local function deviceList()
 local r={};for _,d in pairs(devices) do r[#r+1]=d end
 table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address) end);return r
end
local function selectedDevice()
 local l=deviceList();if #l==0 then return nil end;selected=clamp(selected,1,#l);return l[selected]
end
local function send(d,k,data)
 if d and online(d) then return network.send(d.address,k,data) end
 return false
end
local function remember(sender,p,distance)
 local d=devices[sender] or {address=sender};devices[sender]=d
 for k,v in pairs(p.data or {}) do d[k]=v end
 d.address=sender;d.last=now();d.distance=tonumber(distance) or 0
 d.link=(d.distance>0) and "WIRELESS" or (d.wireless and "WIRELESS" or "WIRED")
 if p.kind=="PONG" then
  d.lastPong=now();d.testStatus="PASS";d.latency=d.pingSent and math.max(0,(now()-d.pingSent)*1000) or d.latency
  if p.data and p.data.id then d.pongId=p.data.id end
 end
 if type(d.reactor)=="table" and d.reactor.available then reactor=d.reactor;lastReactor=now() end
 dirty=true
end
local function ping(d)
 if not d or not online(d) then return false end
 pingSeq=pingSeq+1;d.pingSent=now();d.pingId=pingSeq;d.testStatus="TESTING"
 return network.send(d.address,"PING",{from="BULDACITY OS",id=pingSeq})
end
local function scan()
 network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol="BULDACITY/2",port=PORT})
 lastScan=now();status="SCANNING";log("Network discovery + diagnostics started")
 for _,d in ipairs(deviceList()) do ping(d) end
end
local function fmtBytes(n)
 n=tonumber(n) or 0;if n>=1073741824 then return string.format("%.1f GB",n/1073741824) elseif n>=1048576 then return string.format("%.1f MB",n/1048576) elseif n>=1024 then return string.format("%.1f KB",n/1024) end;return string.format("%d B",n)
end
local function drives()
 local r={};local it=filesystem.mounts();if not it then return r end
 while true do local fs,path=it();if not fs then break end;local total,used,label=0,0,"";pcall(function() total=fs.spaceTotal() or 0 end);pcall(function() used=fs.spaceUsed() or 0 end);pcall(function() label=fs.getLabel() or "" end);r[#r+1]={fs=fs,path=path,total=total,used=used,label=label} end;return r
end
local function driveInfo(d)
 if not d then return 0,0,0 end;local t,u=tonumber(d.total) or 0,tonumber(d.used) or 0
 if t<=0 then pcall(function() t=d.fs.spaceTotal() or 0 end) end;if u<=0 then pcall(function() u=d.fs.spaceUsed() or 0 end) end
 return t,u,t>0 and clamp(u/t*100,0,100) or 0
end
local function localApps()
 local r={};for f in filesystem.list("/") do f=f:gsub("/$","");if f:match("_Modern%.lua$") or f:match("Network%.lua$") or f=="BuldacityNetworkTest.lua" or f=="ReactorBigReactors043A_Touch_Responsive.lua" then r[#r+1]=f end end;table.sort(r);return r
end
local function requestScreen(d) if d and online(d) then network.send(d.address,"SCREEN_REQUEST",{from="BULDACITY OS"}) end end
local function launchApp()
 local files=localApps();local f=files[appSelected];if not f then status="NO APP";return end
 status="STARTING APP";log("Launching "..f);task={name=f,page="APP"}
 local ok,err=pcall(dofile,"/"..f);if not ok then log("APP ERROR: "..tostring(err));status="APP ERROR" else status="APP EXIT" end;task={name="BULDACITY OS",page="DESKTOP"};dirty=true
end
local function reactorClient()
 for _,d in ipairs(deviceList()) do if online(d) and (d.mod=="Big Reactors" or tostring(d.name):find("Reactor")) then return d end end;return nil
end
local function reactorCommand(cmd,data)
 local d=reactorClient();if not d then status="REACTOR OFFLINE";return end;local p=data or {};p.command=cmd;if send(d,"REACTOR_COMMAND",p) then status="COMMAND SENT";log("Reactor: "..cmd) else status="SEND ERROR" end
end

local function top(title,sub)
 fill(1,1,W,5,C.bar);fill(1,5,W,1,C.cyan);text(2,2,"◈ BULDACITY",C.cyan,C.bar);text(17,2,title,C.white,C.bar);text(2,3,fit(sub or "TIER-3 CENTRAL CONTROL",W-30),C.dim,C.bar)
 text(math.max(1,W-27),2,"● SYSTEM ONLINE",C.green,C.bar);text(math.max(1,W-13),3,os.date("%H:%M"),C.white,C.bar)
end
local function taskbar()
 fill(1,H-3,W,4,C.bar)
 local items={{"HOME","DESKTOP"},{"NET","NETWORK"},{"DEV","DEVICES"},{"APP","APPS"},{"DISK","DISKS"},{"PC","REMOTE"},{"SYS","SYSTEM"},{"RX","REACTOR"}}
 local x=2;for _,v in ipairs(items) do local a=page==v[2];text(x,H-1,"["..v[1].."]",a and C.cyan or C.dim,C.bar);x=x+9 end
 text(math.max(1,W-24),H-1,fit(status,20),status=="APP ERROR" and C.red or C.green,C.bar)
end
local function desktop()
 top("DESKTOP","WORKSPACE // REAL-TIME CONTROL CENTER")
 local l=deviceList();local up,pass=0,0;for _,d in ipairs(l) do if online(d) then up=up+1 end;if d.testStatus=="PASS" then pass=pass+1 end end
 panel(3,7,25,10,"SYSTEM",C.cyan);text(6,10,"STATUS",C.dim);text(15,10,"ONLINE",C.green);text(6,12,"CLIENTS",C.dim);text(15,12,up.." / "..#l,C.cyan);text(6,14,"LINK TEST",C.dim);text(15,14,pass.." PASS",pass==#l and C.green or C.yellow);text(6,16,"UPTIME",C.dim);text(15,16,string.format("%.0fs",now()),C.white);button(5,18,21,"SCAN + TEST ALL",C.cyan)
 panel(31,7,24,10,"COMPUTER",C.purple);local e=0;local me=0;pcall(function() e=computer.energy();me=computer.maxEnergy() end);text(34,10,"TIER",C.dim);text(44,10,"TIER-3",C.cyan);text(34,12,"ENERGY",C.dim);text(44,12,math.floor(e),C.green);text(34,14,"VERSION",C.dim);text(44,14,VERSION,C.white);if me>0 then bar(34,16,17,e,me,C.green) end
 panel(61,7,18,10,"QUICK",C.pink);button(63,10,14,"[APP] APPS",C.pink);button(63,14,14,"[PC] REMOTE",C.cyan);button(63,18,14,"[RX] REACTOR",C.green)
 panel(3,20,76,12,"LIVE FLEET",C.green)
 for i,d in ipairs(l) do if i>7 then break end;local y=21+i;local st=online(d) and (d.testStatus=="PASS" and "PASS" or "TEST") or "OFFLINE";local sc=st=="PASS" and C.green or st=="OFFLINE" and C.red or C.yellow;text(6,y,string.format("%02d",i),C.dim);text(11,y,fit(d.name or "CLIENT",23),C.white);text(36,y,fit(d.controller or d.app or "NETWORK CLIENT",17),C.dim);text(55,y,fit(d.link or "--",9),d.link=="WIRELESS" and C.purple or C.cyan);text(66,y,st,sc) end
 panel(3,34,76,math.max(5,H-37),"EVENT LOG",C.yellow);for i=1,math.min(#logs,H-39) do text(6,34+i,fit(logs[i],W-10),C.dim) end
 taskbar()
end
local function networkPage()
 top("NETWORK","LIVE LINK MONITOR // AUTO WIRED + WIRELESS + RELAY")
 panel(3,7,76,7,"NETWORK CORE",C.cyan);local ns=network.status();text(6,10,"SERVER",C.dim);text(16,10,"ONLINE",C.green);text(31,10,"PORT",C.dim);text(38,10,PORT,C.yellow);text(47,10,"MODE",C.dim);text(54,10,mode,C.cyan);text(6,12,"LOCAL LINK",C.dim);text(16,12,ns.wireless and "WIRELESS" or "WIRED",ns.wireless and C.purple or C.cyan);text(31,12,"RELAY",C.dim);text(38,12,ns.relayPathType or "NONE",ns.relayDetected and C.green or C.dim);text(60,12,"TEST ALL",C.yellow)
 panel(3,16,76,math.max(8,H-20),"CLIENT DIAGNOSTICS",C.purple)
 text(6,19,"NAME",C.dim);text(29,19,"STATUS",C.dim);text(39,19,"LINK",C.dim);text(50,19,"DIST",C.dim);text(58,19,"LAT",C.dim);text(68,19,"RELAY",C.dim);rule(5,20,71,C.line)
 local l=deviceList();for i,d in ipairs(l) do local y=20+i;if y>H-6 then break end;local st=online(d) and (d.testStatus or "WAIT") or "OFFLINE";local sc=st=="PASS" and C.green or st=="OFFLINE" and C.red or C.yellow;text(6,y,fit(d.name or "CLIENT",21),C.white);text(29,y,st,sc);text(39,y,fit(d.link or "--",9),d.link=="WIRELESS" and C.purple or C.cyan);text(50,y,tonumber(d.distance or 0)>0 and tostring(d.distance) or "0",C.yellow);text(57,y,d.latency and string.format("%.0fms",d.latency) or "--",C.white);text(68,y,(d.relayDetected or d.relayPathType) and "YES" or "--",C.green) end
 text(6,H-5,"R = full discovery/test   click a client in DEVICES for details",C.dim);taskbar()
end
local function devicesPage()
 top("DEVICES","DEVICE MANAGER // CONTROLLERS + NETWORK TOPOLOGY")
 panel(3,7,46,H-11,"DEVICE FLEET",C.purple);local l=deviceList();if #l==0 then text(7,12,"Waiting for client PCs...",C.dim) end
 for i,d in ipairs(l) do local y=9+i;if y>H-6 then break end;local a=i==selected;if a then fill(5,y,42,2,C.panel2);fill(5,y,2,2,C.cyan) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(d.name or "CLIENT",19),a and C.cyan or C.white);text(34,y,online(d) and "● ON" or "○ OFF",online(d) and C.green or C.red);text(42,y,fit(d.link or "--",5),C.dim) end
 local d=selectedDevice();panel(52,7,27,H-11,"DEVICE DETAILS",C.cyan);if d then text(55,11,"NAME",C.dim);text(55,12,fit(d.name,20),C.white);text(55,15,"ADDRESS",C.dim);text(55,16,fit(d.address,20),C.white);text(55,19,"LINK",C.dim);text(55,20,d.link or "--",d.link=="WIRELESS" and C.purple or C.cyan);text(55,23,"DISTANCE",C.dim);text(55,24,tostring(d.distance or 0),C.yellow);text(55,27,"LATENCY",C.dim);text(55,28,d.latency and string.format("%.1f ms",d.latency) or "--",C.white);text(55,31,"DIAGNOSTIC",C.dim);text(55,32,d.testStatus or "WAIT",d.testStatus=="PASS" and C.green or C.yellow);text(55,35,"RELAY",C.dim);text(55,36,fit(d.relayPathType or "NONE",20),d.relayDetected and C.green or C.dim);button(55,39,20,"PING DEVICE",C.cyan) else text(55,13,"No device selected.",C.dim) end
 taskbar()
end
local function appsPage()
 top("APPS","APPLICATION CENTER // LOCAL OPENCOMPUTERS PROGRAMS")
 panel(3,7,76,H-11,"INSTALLED APPLICATIONS",C.pink);local f=localApps();appSelected=clamp(appSelected,1,math.max(1,#f));if #f==0 then text(7,12,"No applications found.",C.dim) end
 for i,name in ipairs(f) do local y=9+i;if y>H-7 then break end;local a=i==appSelected;if a then fill(5,y,70,2,C.panel2);fill(5,y,2,2,C.pink) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(name,52),a and C.white or C.dim);text(68,y,"RUN",C.green) end
 text(7,H-5,"ENTER / click = launch selected application",C.dim);taskbar()
end
local function disksPage()
 top("DISKS","STORAGE MANAGER // MOUNTED FILESYSTEMS")
 panel(3,7,76,H-11,"STORAGE",C.cyan);local l=drives();driveSelected=clamp(driveSelected,1,math.max(1,#l));if #l==0 then text(7,12,"No mounted filesystems.",C.dim) end
 for i,d in ipairs(l) do local y=9+i;if y>H-8 then break end;local t,u,p=driveInfo(d);local a=i==driveSelected;if a then fill(5,y,70,3,C.panel2) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(d.label~="" and d.label or d.path or "DISK",19),a and C.cyan or C.white);text(34,y,fmtBytes(u).." / "..fmtBytes(t),C.white);text(59,y,string.format("%5.1f%%",p),p>90 and C.red or C.green);bar(34,y+1,22,u,t,p>90 and C.red or C.green) end
 taskbar()
end
local function remotePage()
 top("REMOTE","REMOTE PC // LIVE SCREEN + INPUT")
 local d=selectedDevice();if not d then panel(3,7,76,H-11,"REMOTE",C.cyan);text(7,12,"Select a device first.",C.dim);taskbar();return end
 panel(3,7,59,H-11,"REMOTE DISPLAY",C.cyan);local f=frames[d.address];if f then local sz=frameSize[d.address] or {w=0,h=0};text(6,10,"LIVE "..sz.w.."x"..sz.h,C.green);local syStep=math.max(1,math.ceil(sz.h/20));local sxStep=math.max(1,math.ceil(sz.w/54));local yy=12;for sy=1,sz.h,syStep do if yy>H-6 then break end;local row=f[sy] or {};local out="";for sx=1,sz.w,sxStep do local cell=row[sx];out=out..(cell and tostring(cell.ch or " ") or " ") end;text(6,yy,fit(out,55),C.white);yy=yy+1 end else text(7,14,"Requesting remote screen...",C.dim);requestScreen(d) end
 panel(64,7,15,H-11,"INPUT",C.purple);button(66,11,11,"UP",C.cyan);button(66,15,11,"DOWN",C.cyan);button(66,19,11,"LEFT",C.cyan);button(66,23,11,"RIGHT",C.cyan);button(66,27,11,"ENTER",C.green);button(66,31,11,"CLICK",C.pink);text(66,35,"R refresh",C.dim);taskbar()
end
local function systemPage()
 top("SYSTEM","SYSTEM MONITOR // POWER + MEMORY + SERVICES")
 local e,me,tm,fm=0,0,0,0;pcall(function() e=computer.energy();me=computer.maxEnergy();tm=computer.totalMemory();fm=computer.freeMemory() end)
 panel(3,7,37,12,"POWER",C.green);text(7,10,"ENERGY",C.dim);text(20,10,math.floor(e),C.green);text(7,12,"CAPACITY",C.dim);text(20,12,math.floor(me),C.white);if me>0 then bar(7,14,27,e,me,C.green) end;text(7,17,"UPTIME",C.dim);text(20,17,string.format("%.0fs",now()),C.white)
 panel(42,7,37,12,"MEMORY",C.purple);local used=math.max(0,tm-fm);text(46,10,"USED",C.dim);text(58,10,fmtBytes(used),C.white);text(46,12,"TOTAL",C.dim);text(58,12,fmtBytes(tm),C.white);if tm>0 then bar(46,14,27,used,tm,C.purple) end
 panel(3,21,76,H-25,"SERVICES",C.cyan);text(7,24,"NETWORK",C.dim);text(20,24,"BULDACITY/2",C.cyan);text(40,24,"SERVER",C.green);text(7,26,"CLIENTS",C.dim);text(20,26,#deviceList(),C.white);text(40,26,"LAST SCAN",C.dim);text(51,26,lastScan>0 and string.format("%.0fs",now()-lastScan) or "never",C.yellow);text(7,28,"RELAY PATH",C.dim);local ns=network.status();text(20,28,ns.relayPathType or "NONE",ns.relayDetected and C.green or C.dim);taskbar()
end
local function reactorPage()
 top("REACTOR","BIG REACTORS // TELEMETRY + CONTROL")
 local r=reactor;panel(3,7,76,10,"REACTOR STATUS",C.green);if not r or not r.available then text(7,12,"Waiting for Big Reactor client telemetry...",C.dim) else text(7,10,"STATUS",C.dim);text(18,10,r.active and "RUNNING" or "STOPPED",r.active and C.green or C.red);text(38,10,"FUEL",C.dim);text(48,10,string.format("%.0f / %.0f",r.fuel or 0,r.fuelMax or 0),C.yellow);text(7,12,"TEMP",C.dim);text(18,12,string.format("%.1f",r.temperature or 0),C.orange);text(38,12,"ENERGY",C.dim);text(48,12,fmtBytes(r.energy or 0),C.cyan) end
 panel(3,19,76,12,"CONTROLS",C.pink);button(7,22,15,"START",C.green);button(24,22,15,"STOP",C.red);button(41,22,17,"RODS 0%",C.cyan);button(61,22,13,"RODS 100%",C.yellow);text(7,27,"Commands are sent only to the discovered online reactor controller.",C.dim);taskbar()
end
local function render()
 W,H=gpu.getResolution();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")
 if page=="DESKTOP" then desktop() elseif page=="NETWORK" then networkPage() elseif page=="DEVICES" then devicesPage() elseif page=="APPS" then appsPage() elseif page=="DISKS" then disksPage() elseif page=="REMOTE" then remotePage() elseif page=="SYSTEM" then systemPage() elseif page=="REACTOR" then reactorPage() else page="DESKTOP";desktop() end;dirty=false
end

network.startServer(function(sender,p,distance)
 if p.kind=="HELLO" or p.kind=="HEARTBEAT" or p.kind=="PONG" then remember(sender,p,distance);return end
 if p.kind=="REACTOR_TELEMETRY" and type(p.data)=="table" then reactor=p.data;reactor.address=reactor.address or sender;lastReactor=now();remember(sender,p,distance);return end
 if p.kind=="SCREEN_BEGIN" and type(p.data)=="table" then frames[sender]={};frameSize[sender]={w=tonumber(p.data.width) or W,h=tonumber(p.data.height) or H};dirty=true;return end
 if p.kind=="SCREEN_ROW" and type(p.data)=="table" then frames[sender]=frames[sender] or {};frames[sender][tonumber(p.data.y) or 1]=p.data.cells or {};dirty=true;return end
 if p.kind=="SCREEN_END" then dirty=true;return end
end)

network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol="BULDACITY/2",port=PORT})
log("BULDACITY OS v"..VERSION.." started")

event.timer(4,function()
 network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol="BULDACITY/2",port=PORT})
 for _,d in ipairs(deviceList()) do if online(d) then ping(d) elseif d.testStatus=="TESTING" then d.testStatus="FAIL" end end
 dirty=true
end,math.huge)
event.timer(2,function() local d=reactorClient();if d then send(d,"REACTOR_REQUEST",{from="BULDACITY OS"}) end end,math.huge)
event.timer(1,function() dirty=true end,math.huge)

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
  elseif char==53 or code==6 then page="DISKS"
  elseif char==54 or code==7 then page="REMOTE"
  elseif char==55 or code==8 then page="SYSTEM"
  elseif char==56 or code==9 then page="REACTOR"
  elseif char==114 or char==82 then scan()
  elseif code==200 or char==72 then if page=="DEVICES" then selected=math.max(1,selected-1) elseif page=="APPS" then appSelected=math.max(1,appSelected-1) elseif page=="DISKS" then driveSelected=math.max(1,driveSelected-1) end
  elseif code==208 or char==80 then if page=="DEVICES" then selected=math.min(#deviceList(),selected+1) elseif page=="APPS" then appSelected=appSelected+1 elseif page=="DISKS" then driveSelected=driveSelected+1 end
  elseif code==28 then if page=="APPS" then launchApp() elseif page=="DEVICES" then page="REMOTE" elseif page=="REACTOR" then reactorCommand("start") end
  elseif char==115 or char==83 then if page=="REACTOR" then reactorCommand("stop") end end
  dirty=true
 elseif e=="touch" then
  local x,y,button=b,c,d
  if y>=H-3 then if x<11 then page="DESKTOP" elseif x<20 then page="NETWORK" elseif x<29 then page="DEVICES" elseif x<38 then page="APPS" elseif x<47 then page="DISKS" elseif x<56 then page="REMOTE" elseif x<65 then page="SYSTEM" elseif x<78 then page="REACTOR" end
  elseif page=="DESKTOP" and x>=5 and x<=26 and y>=18 and y<=20 then scan()
  elseif page=="NETWORK" then if y>=10 and y<=14 and x>=58 then scan() end
  elseif page=="DEVICES" then if x<=49 and y>=10 and y<10+#deviceList() then selected=clamp(y-9,1,#deviceList()) elseif x>=54 and y>=39 then ping(selectedDevice()) end
  elseif page=="APPS" and y>=10 and y<10+#localApps() then appSelected=clamp(y-9,1,#localApps());if button==0 or button==1 then launchApp() end
  elseif page=="DISKS" and y>=10 and y<10+#drives() then driveSelected=clamp(y-9,1,#drives())
  elseif page=="REMOTE" then local rd=selectedDevice();if rd and x>=64 then local kind=(y<15 and "key_down") or (y<19 and "key_down") or (y<23 and "key_down") or (y<27 and "key_down") or (y<31 and "key_down") or "touch";network.send(rd.address,"INPUT",{event=kind,x=x,y=y,button=button}) else if rd then network.send(rd.address,"INPUT",{event="touch",x=x,y=y,button=button}) end end
  elseif page=="REACTOR" then local rc=reactorClient();if y>=22 and y<=25 then if x>=7 and x<22 then reactorCommand("start") elseif x>=24 and x<39 then reactorCommand("stop") elseif x>=41 and x<59 then reactorCommand("all_rods",{level=0}) elseif x>=61 and x<75 then reactorCommand("all_rods",{level=100}) end end end
  dirty=true
 elseif e=="scroll" and page=="REMOTE" then local rd=selectedDevice();if rd then network.send(rd.address,"INPUT",{event="scroll",x=b,y=c,button=d}) end;dirty=true
 elseif e=="modem_message" then dirty=true end
end

gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");text(3,3,"BULDACITY OS stopped.",C.cyan,C.bg)
