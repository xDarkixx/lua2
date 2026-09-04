-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers Desktop
-- Minecraft 1.7.10 / OpenComputers
-- Central Tier-3 server with graphical fleet, storage, reactor and remote-PC views.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local network=require("Network")
local gpu=component.gpu

local PROTOCOL="BULDACITY/2"
local PORT=4242
local VERSION="6.0"
local ok,mode=network.startServer()
if not ok then error("BULDACITY OS: modem/network card required") end

local W,H=gpu.getResolution()
local running=true
local page="HOME"
local selected=1
local appSelected=1
local driveSelected=1
local dirty=true
local status="ONLINE"
local devices={}
local logs={}
local frames={}
local frameSize={}
local reactor={}
local lastReactor=0
local lastScan=0

local C={
 bg=0x050811,bar=0x0B1220,panel=0x101A2C,panel2=0x172640,line=0x263B59,
 cyan=0x00E5FF,purple=0xA66CFF,pink=0xFF3EBB,green=0x35F59A,yellow=0xFFD34E,
 red=0xFF5572,white=0xEAF6FF,dim=0x71859E,black=0x000000,orange=0xFF9D45
}

local function now() return computer.uptime() end
local function clamp(v,a,b) v=tonumber(v) or 0;return math.max(a,math.min(b,v)) end
local function fit(s,n)
 s=tostring(s or "");n=math.max(1,n or 1)
 if #s<=n then return s end
 if n==1 then return s:sub(1,1) end
 return s:sub(1,n-1).."…"
end
local function text(x,y,s,fg,bg)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or ""))
end
local function fill(x,y,w,h,c)
 if x<=W and y<=H and w>0 and h>0 then
  gpu.setBackground(c or C.bg)
  gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ")
 end
end
local function rule(x,y,w,c) if w>0 then fill(x,y,w,1,c or C.line) end end
local function log(s)
 table.insert(logs,1,os.date("%H:%M:%S").."  "..tostring(s))
 if #logs>18 then table.remove(logs) end
 dirty=true
end
local function panel(x,y,w,h,title,c)
 if w<3 or h<2 then return end
 fill(x,y,w,h,C.panel);fill(x,y,w,1,c or C.cyan)
 text(x+2,y+2,"◆ "..fit(title,w-6),c or C.cyan,C.panel)
 if h>=4 then rule(x+2,y+3,w-4,C.line) end
end
local function online(d) return d and now()-(d.last or 0)<12 end
local function deviceList()
 local r={}
 for _,d in pairs(devices) do r[#r+1]=d end
 table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address) end)
 return r
end
local function selectedDevice()
 local l=deviceList()
 if #l==0 then return nil end
 selected=clamp(selected,1,#l)
 return l[selected]
end
local function send(d,k,data)
 if d and online(d) then return network.send(d.address,k,data) end
 return false
end
local function hello()
 network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol=PROTOCOL,port=PORT})
end
local function scan()
 hello();lastScan=now()
 for _,d in ipairs(deviceList()) do if online(d) then send(d,"PING",{from="TIER3"}) end end
 status="SCAN SENT";log("Network discovery broadcast")
end
local function remember(sender,p,distance)
 local data=p.data or {}
 local d=devices[sender] or {address=sender}
 devices[sender]=d
 for k,v in pairs(data) do d[k]=v end
 d.address=sender;d.last=now();d.distance=distance
 if type(d.reactor)=="table" and d.reactor.available then reactor=d.reactor;lastReactor=now() end
 dirty=true
end

local function fmtBytes(n)
 n=tonumber(n) or 0
 if n>=1073741824 then return string.format("%.1f GB",n/1073741824) end
 if n>=1048576 then return string.format("%.1f MB",n/1048576) end
 if n>=1024 then return string.format("%.1f KB",n/1024) end
 return string.format("%d B",n)
end
local function drives()
 local r={};local it=filesystem.mounts()
 if it then
  while true do
   local fs,path=it();if not fs then break end
   local total,used,label=0,0,""
   pcall(function() total=fs.spaceTotal() or 0 end)
   pcall(function() used=fs.spaceUsed() or 0 end)
   pcall(function() label=fs.getLabel() or "" end)
   r[#r+1]={fs=fs,path=path,total=total,used=used,label=label}
  end
 end
 return r
end
local function driveInfo(d)
 if not d then return 0,0,0 end
 local total=tonumber(d.total) or 0;local used=tonumber(d.used) or 0
 if total<=0 then pcall(function() total=d.fs.spaceTotal() or 0 end) end
 if used<=0 then pcall(function() used=d.fs.spaceUsed() or 0 end) end
 local pct=total>0 and clamp(used/total*100,0,100) or 0
 return total,used,pct
end
local function safeComputer(method,default)
 local v=default
 pcall(function() if type(computer[method])=="function" then v=computer[method]() end end)
 return v
end

-- Graphical primitives: all are GPU-drawn, no external textures required.
local function bar(x,y,w,value,maxValue,c)
 local pct=maxValue and maxValue>0 and clamp(value/maxValue,0,1) or 0
 fill(x,y,w,2,C.bar)
 if pct>0 then fill(x,y,math.max(1,math.floor(w*pct)),2,c or C.cyan) end
end
local function gauge(x,y,w,label,value,maxValue,unit,c)
 value=tonumber(value) or 0;maxValue=tonumber(maxValue) or 100
 text(x,y,fit(label,w-12),C.dim)
 text(x+w-10,y,string.format("%5.1f%s",value,unit or ""),c or C.white)
 bar(x,y+1,w,value,maxValue,c)
end
local function meter(x,y,w,h,pct,c)
 pct=clamp(pct,0,1);fill(x,y,w,h,C.bar)
 if pct>0 then fill(x,y,math.max(1,math.floor(w*pct)),h,c or C.cyan) end
end
local function button(x,y,w,label,c,active)
 local bg=active and C.panel2 or C.bar
 fill(x,y,w,3,bg);fill(x,y,w,1,c or C.cyan)
 text(x+2,y+1,fit(label,w-4),active and C.white or (c or C.cyan),bg)
end
local function spark(x,y,w,values,c)
 if w<3 then return end
 local n=#values
 if n<2 then rule(x,y+3,w,C.line);return end
 local minv,maxv=values[1],values[1]
 for i=2,n do minv=math.min(minv,values[i]);maxv=math.max(maxv,values[i]) end
 if maxv==minv then maxv=minv+1 end
 for i=1,math.min(w,n) do
  local idx=math.max(1,n-math.min(w,n)+i)
  local p=(values[idx]-minv)/(maxv-minv)
  local yy=y+3-math.floor(p*3)
  text(x+i-1,yy,"•",c or C.cyan)
 end
end
local function header(title,sub)
 fill(1,1,W,5,C.bar);fill(1,5,W,1,C.cyan)
 text(3,2,"BULDACITY",C.cyan,C.bar);text(14,2,"OS",C.white,C.bar);text(18,2,title,C.purple,C.bar)
 text(3,3,fit(sub or "TIER-3 CENTRAL CONTROL",math.max(10,W-34)),C.dim,C.bar)
 text(math.max(1,W-25),2,"● ONLINE",C.green,C.bar)
 text(math.max(1,W-14),3,PROTOCOL,C.cyan,C.bar)
 text(math.max(1,W-8),4,os.date("%H:%M"),C.white,C.bar)
end
local function nav()
 local n={{"1","HOME"},{"2","NET"},{"3","DEV"},{"4","APPS"},{"5","DISK"},{"6","REMOTE"},{"7","SYS"},{"8","REACTOR"}}
 fill(1,H-3,W,4,C.bar)
 local x=2
 for _,v in ipairs(n) do
  local active=(page==v[2] or (page=="NETWORK" and v[2]=="NET") or (page=="DEVICES" and v[2]=="DEVICES") or (page=="DISKS" and v[2]=="DISK") or (page=="SYSTEM" and v[2]=="SYS"))
  text(x,H-1,"["..v[1].."]"..v[2],active and C.white or C.dim,C.bar);x=x+9
 end
 text(math.max(1,W-16),H-1,fit(status,13),C.green,C.bar)
end

local function home()
 header("HOME","CENTRAL CONTROL // GRAPHICAL TIER-3 DESKTOP")
 local l=deviceList();local up=0
 for _,d in ipairs(l) do if online(d) then up=up+1 end end
 panel(3,7,23,10,"NETWORK STATUS",C.cyan)
 text(6,10,"STATUS",C.dim);text(15,10,"ONLINE",C.green)
 text(6,12,"PORT",C.dim);text(15,12,PORT,C.yellow)
 text(6,14,"CLIENTS",C.dim);text(15,14,up.." / "..#l,C.cyan)
 text(6,16,"MODE",C.dim);text(15,16,fit(mode,9),C.green)
 button(6,18,17,"R  SCAN NETWORK",C.cyan)
 panel(28,7,23,10,"COMPUTER",C.purple)
 local energy=safeComputer("energy",0);local maxEnergy=safeComputer("maxEnergy",0)
 text(31,10,"TIER",C.dim);text(41,10,"TIER-3",C.cyan)
 text(31,12,"UPTIME",C.dim);text(41,12,string.format("%.0fs",now()),C.white)
 text(31,14,"ENERGY",C.dim);text(41,14,energy and math.floor(energy) or "N/A",C.green)
 text(31,16,"VERSION",C.dim);text(41,16,VERSION,C.white)
 if maxEnergy and maxEnergy>0 then bar(31,18,17,energy,maxEnergy,C.green) end
 panel(53,7,25,10,"QUICK LAUNCH",C.pink)
 button(56,10,19,"[4] APP LIBRARY",C.pink)
 button(56,14,19,"[6] REMOTE PC",C.cyan)
 button(56,18,19,"[8] REACTOR",C.green)
 panel(3,20,75,11,"LIVE FLEET",C.green)
 if #l==0 then text(7,25,"Waiting for normal Tier-3 controller PCs...",C.dim) end
 for i,d in ipairs(l) do
  if i>6 then break end
  local y=21+i
  text(7,y,string.format("%02d",i),C.dim)
  text(12,y,fit(d.name or "CONTROLLER",23),C.white)
  text(37,y,fit(d.controller or d.app or "NETWORK CLIENT",18),C.dim)
  text(61,y,online(d) and "● ONLINE" or "○ OFFLINE",online(d) and C.green or C.red)
 end
 panel(3,33,75,math.max(5,H-36),"SYSTEM EVENT LOG",C.yellow)
 for i=1,math.min(#logs,H-39) do text(6,33+i,fit(logs[i],W-10),C.dim) end
 nav()
end

local function networkPage()
 header("NETWORK","BULDACITY/2 // CENTRAL SERVER + NORMAL CLIENT PCS")
 panel(3,7,75,10,"NETWORK CORE",C.cyan)
 text(7,10,"ROLE",C.dim);text(19,10,"CENTRAL SERVER",C.green)
 text(7,12,"PROTOCOL",C.dim);text(19,12,PROTOCOL,C.cyan)
 text(7,14,"PORT",C.dim);text(19,14,PORT,C.yellow)
 text(40,10,"ADDRESS",C.dim);text(52,10,fit(network.address(),24),C.white)
 text(40,12,"CLIENT MODE",C.dim);text(52,12,"NORMAL TIER-3 PCs",C.green)
 text(40,14,"ACCESS CONTROL",C.dim);text(52,14,"NONE",C.orange)
 panel(3,19,75,math.max(7,H-23),"LINK MONITOR",C.purple)
 local l=deviceList()
 for i,d in ipairs(l) do
  local y=20+i;if y>H-6 then break end
  text(7,y,string.format("%02d",i),C.dim)
  text(12,y,fit(d.name or "UNKNOWN",22),C.white)
  text(36,y,fit(d.address or "",15),C.dim)
  text(53,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red)
  text(65,y,online(d) and string.format("%02ds",math.floor(now()-(d.last or now()))) or "--",C.dim)
 end
 text(7,H-5,"R = rediscover   3 = device fleet   6 = remote PC",C.dim)
 nav()
end

local function devicesPage()
 header("DEVICES","CONTROLLER FLEET // SELECT A NORMAL OPENCOMPUTERS CLIENT")
 panel(3,7,48,H-11,"CONNECTED CONTROLLERS",C.purple)
 local l=deviceList()
 if #l==0 then text(7,12,"No network controller is online.",C.dim) end
 for i,d in ipairs(l) do
  local y=9+i;if y>H-6 then break end
  local active=i==selected
  if active then fill(5,y,44,2,C.panel2);fill(5,y,2,2,C.cyan) end
  text(8,y,string.format("%02d",i),C.dim)
  text(13,y,fit(d.name or "UNKNOWN",20),active and C.cyan or C.white)
  text(35,y,online(d) and "● ONLINE" or "○ OFFLINE",online(d) and C.green or C.red)
 end
 local d=selectedDevice()
 panel(53,7,25,H-11,"SELECTED CLIENT",C.cyan)
 if d then
  text(57,11,"NAME",C.dim);text(57,12,fit(d.name,17),C.white)
  text(57,15,"APP",C.dim);text(57,16,fit(d.controller or d.app or "CLIENT",17),C.purple)
  text(57,19,"ADDRESS",C.dim);text(57,20,fit(d.address,17),C.white)
  text(57,23,"DISTANCE",C.dim);text(57,24,tostring(d.distance or "--"),C.yellow)
  text(57,27,"STATUS",C.dim);text(57,28,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red)
  button(57,31,18,"ENTER  REMOTE",C.cyan)
 else text(57,13,"Select a client.",C.dim) end
 text(7,H-5,"↑/↓ or W/S select   ENTER = remote   R = scan",C.dim)
 nav()
end

local function appFiles()
 local files={}
 for f in filesystem.list("/") do
  f=f:gsub("/$","")
  if f:match("_Modern%.lua$") or f=="ReactorBigReactors043A_Touch_Responsive.lua" then files[#files+1]=f end
 end
 table.sort(files);return files
end
local function appsPage()
 header("APPS","APPLICATION LIBRARY // LOCAL MODERN CONTROLLERS")
 panel(3,7,75,H-11,"DESKTOP APPLICATIONS",C.pink)
 local files=appFiles();appSelected=clamp(appSelected,1,math.max(1,#files))
 if #files==0 then text(7,12,"No local controller applications found.",C.dim) end
 for i,f in ipairs(files) do
  local y=8+i;if y>H-8 then break end
  local active=i==appSelected
  if active then fill(5,y,70,2,C.panel2);fill(5,y,2,2,C.pink) end
  text(8,y,string.format("%02d",i),C.dim);text(12,y,fit(f,53),active and C.white or C.dim);text(68,y,"LOCAL",C.green)
 end
 text(7,H-5,"↑/↓ select   ENTER = launch local Modern controller",C.dim);nav()
end

local function disksPage()
 header("DISK","REAL STORAGE DEVICES // CAPACITY + USED + FREE")
 panel(3,7,75,H-11,"STORAGE DEVICES",C.cyan)
 local l=drives();driveSelected=clamp(driveSelected,1,math.max(1,#l))
 if #l==0 then text(7,12,"No mounted filesystem devices detected.",C.dim) end
 for i,d in ipairs(l) do
  local y=8+i;if y>H-8 then break end
  local total,used,pct=driveInfo(d);local active=i==driveSelected
  if active then fill(5,y,70,3,C.panel2) end
  text(8,y,string.format("%02d",i),C.dim)
  text(12,y,fit((d.label~="" and d.label or d.path or "DISK"),20),active and C.cyan or C.white)
  text(34,y,fmtBytes(used).." / "..fmtBytes(total),C.white)
  text(58,y,string.format("%5.1f%%",pct),pct>90 and C.red or C.green)
  local ro=false;pcall(function() ro=d.fs.isReadOnly() end);text(68,y,ro and "RO" or "RW",C.dim)
  bar(34,y+1,30,used,total,pct>90 and C.red or C.green)
 end
 local d=l[driveSelected]
 if d then
  local total,used,pct=driveInfo(d);local free=math.max(0,total-used)
  text(7,H-5,"SELECTED",C.dim);text(17,H-5,fit(d.path or "DISK",18),C.white)
  text(38,H-5,"USED",C.dim);text(44,H-5,fmtBytes(used),C.yellow)
  text(57,H-5,"FREE",C.dim);text(63,H-5,fmtBytes(free),C.green)
 end
 nav()
end

local function remotePage()
 header("REMOTE","LIVE REMOTE PC // SCREEN + KEYBOARD + TOUCH + SCROLL")
 local d=selectedDevice()
 if not d then panel(3,7,75,H-11,"REMOTE",C.cyan);text(7,12,"No client selected.",C.dim);nav();return end
 panel(3,7,58,H-11,"REMOTE DISPLAY",C.cyan)
 local f=frames[d.address]
 if f then
  local fw=frameSize[d.address] and frameSize[d.address].w or 0
  local fh=frameSize[d.address] and frameSize[d.address].h or 0
  text(6,10,"LIVE FRAME  "..fw.."x"..fh,C.green)
  local scaleX=math.max(1,math.ceil((fw or W)/52));local scaleY=math.max(1,math.ceil((fh or H)/20))
  local yy=12
  for sy=1,fh,scaleY do
   if yy>H-6 then break end
   local row=f[sy] or {};local out=""
   for sx=1,fw,scaleX do local cell=row[sx];out=out..(cell and tostring(cell.ch or " ") or " ") end
   text(6,yy,fit(out,54),C.white);yy=yy+1
  end
 else
  text(7,14,"Requesting remote screen...",C.dim);requestScreen(d)
 end
 panel(63,7,15,H-11,"INPUT",C.purple)
 button(65,11,11,"UP",C.cyan);button(65,15,11,"DOWN",C.cyan)
 button(65,19,11,"LEFT",C.cyan);button(65,23,11,"RIGHT",C.cyan)
 button(65,27,11,"ENTER",C.green);button(65,31,11,"R CLICK",C.pink)
 text(65,35,"Touch remote",C.dim)
 text(65,36,"with mouse",C.dim)
 text(7,H-5,"Keyboard: forwards keys   Mouse: forwards touch/scroll   R = refresh",C.dim)
 nav()
end

local function systemPage()
 header("SYSTEM","LOCAL TIER-3 HEALTH // GPU + MEMORY + ENERGY")
 local energy=safeComputer("energy",0);local maxEnergy=safeComputer("maxEnergy",0)
 local totalMem=safeComputer("totalMemory",0);local freeMem=safeComputer("freeMemory",0)
 panel(3,7,36,12,"POWER",C.green)
 text(7,10,"ENERGY",C.dim);text(20,10,tostring(math.floor(tonumber(energy) or 0)),C.green)
 if maxEnergy and maxEnergy>0 then gauge(7,12,27,"CHARGE",energy,maxEnergy,"",C.green) else text(7,13,"Energy capacity unavailable",C.dim) end
 text(7,16,"UPTIME",C.dim);text(20,16,string.format("%.0f s",now()),C.white)
 panel(42,7,36,12,"MEMORY",C.purple)
 local used=math.max(0,(tonumber(totalMem) or 0)-(tonumber(freeMem) or 0))
 text(46,10,"USED",C.dim);text(58,10,fmtBytes(used),C.white)
 text(46,12,"TOTAL",C.dim);text(58,12,fmtBytes(totalMem),C.white)
 if totalMem and totalMem>0 then gauge(46,14,27,"LOAD",used,totalMem,"",C.purple) end
 text(46,17,"GPU",C.dim);text(58,17,W.."x"..H,C.cyan)
 panel(3,21,75,math.max(7,H-25),"SERVICE STATUS",C.cyan)
 text(7,24,"NETWORK",C.dim);text(20,24,"BULDACITY/2",C.cyan);text(38,24,"SERVER",C.green)
 text(7,26,"AUTOSTART",C.dim);text(20,26,"READY",C.green);text(38,26,"VERSION",C.dim);text(48,26,VERSION,C.white)
 text(7,28,"CLIENTS",C.dim);text(20,28,tostring(#deviceList()),C.white);text(38,28,"LAST SCAN",C.dim);text(48,28,lastScan>0 and string.format("%.0fs ago",now()-lastScan) or "never",C.yellow)
 text(7,30,"REACTOR TELEMETRY",C.dim);text(25,30,(lastReactor>0 and "AVAILABLE" or "WAITING"),lastReactor>0 and C.green or C.dim)
 nav()
end

local function reactorPage()
 header("REACTOR","BIG REACTORS 0.4.3A // LIVE TELEMETRY + CONTROL")
 local r=reactor
 local available=r and r.available
 panel(3,7,75,9,"REACTOR STATUS",C.green)
 if not available then
  text(7,11,"No Big Reactor telemetry received yet.",C.dim)
  text(7,13,"Start ReactorBigReactors043A_Network.lua on a normal Tier-3 client.",C.dim)
  text(7,15,"The central server will display telemetry automatically.",C.dim)
 else
  text(7,10,"STATUS",C.dim);text(18,10,r.active and "● RUNNING" or "○ STOPPED",r.active and C.green or C.red)
  text(38,10,"ADDRESS",C.dim);text(48,10,fit(r.address or "",26),C.white)
  text(7,12,"VERSION",C.dim);text(18,12,r.version or "0.4.3A",C.cyan)
  text(38,12,"RODS",C.dim);text(48,12,tostring(r.rods or 0),C.yellow)
  text(7,14,"FUEL",C.dim);text(18,14,string.format("%.0f / %.0f",r.fuel or 0,r.fuelMax or 0),C.white)
  text(38,14,"TEMP",C.dim);text(48,14,string.format("%.1f",r.temperature or 0),C.orange)
 end
 panel(3,18,36,13,"ENERGY",C.cyan)
 if available then
  gauge(7,21,27,"STORED",r.energy or 0,r.energyMax or 1,"",C.cyan)
  text(7,25,"CAPACITY",C.dim);text(20,25,fmtBytes(r.energyMax or 0),C.white)
  text(7,27,"OUTPUT VIEW",C.dim);text(20,27,"LIVE",C.green)
 else text(7,23,"waiting...",C.dim) end
 panel(42,18,36,13,"FUEL + TEMPERATURE",C.orange)
 if available then
  gauge(46,21,27,"FUEL",r.fuel or 0,r.fuelMax or 1,"",C.yellow)
  gauge(46,25,27,"TEMP",r.temperature or 0,1000,"°",C.orange)
 else text(46,23,"waiting...",C.dim) end
 panel(3,33,75,math.max(6,H-37),"REACTOR CONTROLS",C.pink)
 button(7,36,15,"START",C.green)
 button(24,36,15,"STOP",C.red)
 button(41,36,18,"RODS 0%",C.cyan)
 button(61,36,12,"ALL RODS",C.yellow)
 text(7,40,"Mouse buttons send commands to the selected Big Reactor client.",C.dim)
 text(7,41,"For safety, commands only target a discovered online client.",C.dim)
 nav()
end

local function render()
 W,H=gpu.getResolution();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")
 if page=="HOME" then home()
 elseif page=="NETWORK" or page=="NET" then networkPage()
 elseif page=="DEVICES" or page=="DEV" then devicesPage()
 elseif page=="APPS" then appsPage()
 elseif page=="DISKS" or page=="DISK" then disksPage()
 elseif page=="REMOTE" then remotePage()
 elseif page=="SYSTEM" or page=="SYS" then systemPage()
 elseif page=="REACTOR" then reactorPage()
 else page="HOME";home() end
 dirty=false
end

local function launchApp()
 local files=appFiles();local f=files[appSelected]
 if not f then status="NO APP";log("No application selected");return end
 status="LAUNCHING";log("Launching "..f)
 local ok,err=pcall(dofile,"/"..f)
 if not ok then status="APP ERROR";log("App error: "..tostring(err)) else status="APP EXIT" end
 dirty=true
end
local function reactorCommand(d,cmd,data)
 if not d or not online(d) then status="REACTOR OFFLINE";return end
 local payload=data or {};payload.command=cmd
 if send(d,"REACTOR_COMMAND",payload) then status="COMMAND SENT";log("Reactor command: "..cmd) else status="SEND ERROR" end
end
local function reactorClient()
 for _,d in ipairs(deviceList()) do
  if online(d) and d.mod=="Big Reactors" then return d end
 end
 return nil
end
local function remoteInput(d,kind,data)
 if d and online(d) then network.send(d.address,"INPUT",{event=kind,x=data.x,y=data.y,button=data.button,char=data.char,code=data.code}) end
end

network.startServer(function(sender,p,distance)
 if p.kind=="HELLO" or p.kind=="HEARTBEAT" then remember(sender,p,distance);return end
 if p.kind=="PONG" then remember(sender,p,distance);return end
 if p.kind=="REACTOR_TELEMETRY" and type(p.data)=="table" then
  reactor=p.data;reactor.address=reactor.address or sender;lastReactor=now();remember(sender,p,distance);return
 end
 if p.kind=="SCREEN_BEGIN" and type(p.data)=="table" then
  frames[sender]={};frameSize[sender]={w=tonumber(p.data.width) or W,h=tonumber(p.data.height) or H};dirty=true;return
 end
 if p.kind=="SCREEN_ROW" and type(p.data)=="table" then
  frames[sender]=frames[sender] or {};frames[sender][tonumber(p.data.y) or 1]=p.data.cells or {};dirty=true;return
 end
 if p.kind=="SCREEN_END" then lastFrame=now();dirty=true;return end
end)

hello();log("BULDACITY OS v"..VERSION.." online")
log("Central server ready on port "..PORT)

event.timer(4,function()
 hello()
 for _,d in ipairs(deviceList()) do if online(d) then send(d,"PING",{from="TIER3"}) end end
 dirty=true
end,math.huge)

event.timer(2,function()
 local d=reactorClient()
 if d then send(d,"REACTOR_REQUEST",{from="BULDACITY OS"}) end
end,math.huge)

event.timer(1,function() dirty=true end,math.huge)

while running do
 if dirty then render() end
 local e,a,b,c,d,e2=event.pull(0.20)
 if e=="key_down" then
  local char,code=b,c
  if code==16 or char==113 or char==81 then running=false
  elseif code==2 or char==49 then page="HOME"
  elseif code==3 or char==50 then page="NETWORK"
  elseif code==4 or char==51 then page="DEVICES"
  elseif code==5 or char==52 then page="APPS"
  elseif code==6 or char==53 then page="DISKS"
  elseif code==7 or char==54 then page="REMOTE"
  elseif code==8 or char==55 then page="SYSTEM"
  elseif code==9 or char==56 then page="REACTOR"
  elseif code==200 or char==72 then
   if page=="DEVICES" then selected=math.max(1,selected-1) elseif page=="APPS" then appSelected=math.max(1,appSelected-1) elseif page=="DISKS" then driveSelected=math.max(1,driveSelected-1) end
  elseif code==208 or char==80 then
   if page=="DEVICES" then selected=math.min(#deviceList(),selected+1) elseif page=="APPS" then appSelected=appSelected+1 elseif page=="DISKS" then driveSelected=driveSelected+1 end
  elseif code==28 then
   if page=="DEVICES" then page="REMOTE" elseif page=="APPS" then launchApp() elseif page=="REACTOR" then reactorCommand(reactorClient(),"start") end
  elseif char==114 or char==82 then scan()
  elseif char==115 or char==83 then
   if page=="REACTOR" then reactorCommand(reactorClient(),"stop") end
  end
  dirty=true
 elseif e=="touch" then
  local x,y,button=b,c,d
  if y>=H-3 then
   if x<11 then page="HOME" elseif x<20 then page="NETWORK" elseif x<29 then page="DEVICES" elseif x<38 then page="APPS" elseif x<47 then page="DISKS" elseif x<56 then page="REMOTE" elseif x<65 then page="SYSTEM" elseif x<78 then page="REACTOR" end
  elseif page=="HOME" and x>=6 and x<=23 and y>=18 and y<=20 then scan()
  elseif page=="DEVICES" then
   if x<=50 and y>=9 and y<9+#deviceList() then selected=clamp(y-9,1,#deviceList())
   elseif x>=53 and y>=30 then page="REMOTE" end
  elseif page=="APPS" and y>=8 and y<8+#appFiles() then appSelected=clamp(y-8,1,#appFiles());if button==0 or button==1 then launchApp() end
  elseif page=="DISKS" and y>=9 and y<9+#drives() then driveSelected=clamp(y-8,1,#drives())
  elseif page=="REMOTE" then
   local rd=selectedDevice()
   if rd then remoteInput(rd,"touch",{x=x,y=y,button=button}) end
  elseif page=="REACTOR" then
   local rc=reactorClient()
   if y>=36 and y<=39 then
    if x>=7 and x<22 then reactorCommand(rc,"start")
    elseif x>=24 and x<39 then reactorCommand(rc,"stop")
    elseif x>=41 and x<59 then reactorCommand(rc,"all_rods",{level=0})
    elseif x>=61 and x<74 then reactorCommand(rc,"all_rods",{level=100}) end
   end
  end
  dirty=true
 elseif e=="scroll" and page=="REMOTE" then
  local rd=selectedDevice();if rd then remoteInput(rd,"scroll",{x=b,y=c,button=d}) end
  dirty=true
 elseif e=="modem_message" then
  dirty=true
 end
end

gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");text(3,3,"BULDACITY OS stopped.",C.cyan,C.bg)
