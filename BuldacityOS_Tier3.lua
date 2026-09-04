-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers Desktop
-- Minecraft 1.7.10 / OpenComputers
-- Self-contained desktop hub. Network service is provided by Network.lua on normal PCs.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local shell=require("shell")
local network=require("Network")
local gpu=component.gpu

local PROTOCOL="BULDACITY/2"
local PORT=4242
local VERSION="4.0"
local ok,mode=network.startServer()
if not ok then error("BULDACITY OS: modem/network card required") end

local W,H=gpu.getResolution()
local running=true
local page="HOME"
local selected=1
local devices={}
local logs={}
local frames={}
local frameSize={}
local status="ONLINE"
local ui={}
local lastInput=0

local C={bg=0x050811,bar=0x0B1220,panel=0x101A2C,panel2=0x172640,line=0x263B59,cyan=0x00E5FF,purple=0xA66CFF,pink=0xFF3EBB,green=0x35F59A,yellow=0xFFD34E,red=0xFF5572,white=0xEAF6FF,dim=0x71859E,black=0x000000,orange=0xFF9D45}

local function now() return computer.uptime() end
local function fit(s,n) s=tostring(s or "");n=math.max(1,n or 1);if #s<=n then return s end;if n==1 then return s:sub(1,1) end;return s:sub(1,n-1).."…" end
local function text(x,y,s,c,bg) if x<1 or y<1 or x>W or y>H then return end;gpu.setForeground(c or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or "")) end
local function fill(x,y,w,h,c) if x<=W and y<=H and w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ") end end
local function rule(x,y,w,c) if w>0 then gpu.setBackground(c or C.line);gpu.fill(x,y,math.min(w,W-x+1),1," ") end end
local function log(s) table.insert(logs,1,os.date("%H:%M:%S").."  "..s);if #logs>10 then table.remove(logs) end end
local function panel(x,y,w,h,title,c)
 fill(x,y,w,h,C.panel);fill(x,y,w,1,c or C.cyan);text(x+2,y+2,"◆ "..fit(title,w-6),c or C.cyan,C.panel);rule(x+2,y+3,w-4,C.line)
end
local function online(d) return d and now()-(d.last or 0)<12 end
local function deviceList()
 local r={};for _,d in pairs(devices) do r[#r+1]=d end
 table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address) end)
 return r
end
local function selectedDevice() local l=deviceList();if #l==0 then return nil end;selected=math.max(1,math.min(selected,#l));return l[selected] end
local function send(d,k,data) if d and online(d) then return network.send(d.address,k,data) end;return false end
local function hello() network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol=PROTOCOL,port=PORT}) end
local function scan() hello();for _,d in ipairs(deviceList()) do if online(d) then send(d,"PING",{from="TIER3"}) end end;status="SCAN SENT";log("Network discovery broadcast") end
local function requestScreen(d) if d then send(d,"SCREEN_REQUEST",{width=W,height=H}) end end

local function header(title,sub)
 fill(1,1,W,5,C.bar);fill(1,5,W,1,C.cyan)
 text(3,2,"BULDACITY",C.cyan,C.bar);text(14,2,"OS",C.white,C.bar);text(18,2,title,C.purple,C.bar)
 text(3,3,sub or "TIER-3 CENTRAL CONTROL",C.dim,C.bar);text(math.max(1,W-24),2,"● NETWORK ONLINE",C.green,C.bar);text(math.max(1,W-14),3,PROTOCOL,C.cyan,C.bar);text(math.max(1,W-8),4,os.date("%H:%M"),C.white,C.bar)
end
local function nav()
 local n={{"1","HOME"},{"2","NETWORK"},{"3","DEVICES"},{"4","APPS"},{"5","REMOTE"},{"6","SYSTEM"}};local x=2
 fill(1,H-3,W,4,C.bar)
 for _,v in ipairs(n) do local active=page==v[2];text(x,H-1,"["..v[1].."] "..v[2],active and C.white or C.dim,C.bar);x=x+13 end
 text(math.max(1,W-18),H-1,fit(status,15),C.green,C.bar);text(math.max(1,W-3),H-1,"Q",C.red,C.bar)
end
local function home()
 header("HOME","CENTRAL CONTROL // AUTONOMOUS NETWORK HUB")
 local l=deviceList();local up=0;for _,d in ipairs(l) do if online(d) then up=up+1 end end
 panel(3,7,24,8,"NETWORK",C.cyan);text(6,10,"STATUS",C.dim);text(15,10,"ONLINE",C.green);text(6,12,"PORT",C.dim);text(15,12,PORT,C.yellow);text(6,14,"CLIENTS",C.dim);text(15,14,up.." / "..#l,C.cyan)
 panel(29,7,24,8,"DESKTOP",C.purple);text(32,10,"VERSION",C.dim);text(42,10,VERSION,C.white);text(32,12,"MODE",C.dim);text(42,12,mode,C.green);text(32,14,"ADDRESS",C.dim);text(42,14,fit(network.address(),10),C.white)
 panel(55,7,23,8,"QUICK ACTION",C.pink);text(59,10,"[R]",C.cyan);text(64,10,"SCAN",C.white);text(59,12,"[3]",C.cyan);text(64,12,"DEVICES",C.white);text(59,14,"[5]",C.cyan);text(64,14,"REMOTE",C.white)
 panel(3,17,75,10,"LIVE FLEET",C.green)
 if #l==0 then text(7,22,"Waiting for controller PCs...",C.dim) end
 for i,d in ipairs(l) do if i>6 then break end;local y=18+i;text(7,y,string.format("%02d",i),C.dim);text(12,y,fit(d.name or "CONTROLLER",25),C.white);text(40,y,fit(d.controller or d.app or "CLIENT",18),C.dim);text(61,y,online(d) and "● ONLINE" or "○ OFFLINE",online(d) and C.green or C.red) end
 panel(3,29,75,math.max(4,H-32),"SYSTEM LOG",C.yellow);for i=1,math.min(#logs,H-35) do text(6,29+i,fit(logs[i],W-10),C.dim) end
 nav()
end
local function networkPage()
 header("NETWORK","BULDACITY/2 // AUTOMATIC DISCOVERY")
 panel(3,7,75,9,"NETWORK CORE",C.cyan);text(7,10,"PROTOCOL",C.dim);text(19,10,PROTOCOL,C.cyan);text(7,12,"PORT",C.dim);text(19,12,PORT,C.yellow);text(7,14,"TRANSPORT",C.dim);text(19,14,mode,C.green);text(40,10,"ADDRESS",C.dim);text(52,10,fit(network.address(),24),C.white);text(40,12,"CONFIGURATION",C.dim);text(52,12,"AUTOMATIC",C.green);text(40,14,"ACCESS CONTROL",C.dim);text(52,14,"NONE",C.orange)
 panel(3,17,75,math.max(7,H-21),"HEARTBEAT MONITOR",C.purple)
 local l=deviceList();for i,d in ipairs(l) do local y=18+i;if y>H-5 then break end;text(7,y,string.format("%02d",i),C.dim);text(12,y,fit(d.name or "UNKNOWN",23),C.white);text(37,y,fit(d.address or "",14),C.dim);text(53,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red);text(65,y,online(d) and string.format("%02ds",math.floor(now()-(d.last or now()))) or "--",C.dim) end
 text(7,H-5,"R = rediscover   1 = home   3 = devices",C.dim);nav()
end
local function devicesPage()
 header("DEVICES","CONTROLLER FLEET // SELECT A NORMAL PC")
 panel(3,7,75,H-11,"CONNECTED CONTROLLERS",C.purple)
 local l=deviceList();if #l==0 then text(7,12,"No network controller is online.",C.dim);text(7,14,"Run a controller network app on a normal OpenComputers PC.",C.dim) end
 for i,d in ipairs(l) do local y=9+i;if y>H-6 then break end;if i==selected then fill(5,y,70,1,C.panel2);fill(5,y,2,1,C.cyan) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(d.name or "UNKNOWN",23),i==selected and C.cyan or C.white);text(38,y,fit(d.controller or d.app or "CLIENT",19),C.dim);text(59,y,online(d) and "● ONLINE" or "○ OFFLINE",online(d) and C.green or C.red) end
 text(7,H-5,"↑/↓ or W/S select   ENTER = remote   R = scan",C.dim);nav()
end
local function appsPage()
 header("APPS","DESKTOP APPLICATIONS // MODERN CONTROLLERS")
 panel(3,7,75,H-11,"APP LIBRARY",C.pink)
 local files={};for f in filesystem.list("/") do if f:match("_Modern%.lua$") then files[#files+1]=f:gsub("/$","") end end
 table.sort(files);local big=filesystem.exists("ReactorBigReactors043A_Touch_Responsive.lua");if big then files[#files+1]="ReactorBigReactors043A_Touch_Responsive.lua" end
 if #files==0 then text(7,12,"No Modern controller apps found.",C.dim) end
 for i,f in ipairs(files) do local y=8+i;if y>H-6 then break end;text(7,y,string.format("%02d",i),C.dim);text(12,y,fit(f,50),C.white);text(68,y,"APP",C.green) end
 text(7,H-5,"Modern files are desktop apps. Network controller PCs run their network app separately.",C.dim);nav()
end
local function remotePage()
 header("REMOTE","LIVE REMOTE DESKTOP // SELECTED CONTROLLER")
 local d=selectedDevice();if not d then panel(3,7,75,H-11,"REMOTE DESKTOP",C.pink);text(7,12,"No controller selected.",C.dim);text(7,14,"Open DEVICES and select a controller.",C.dim);nav();return end
 local frame=frames[d.address];local sz=frameSize[d.address] or {w=0,h=0};local ox,oy=3,7;local vw=math.min(math.max(10,W-6),sz.w>0 and sz.w or W-6);local vh=math.min(math.max(8,H-12),sz.h>0 and sz.h or H-12)
 fill(ox,oy,vw+2,vh+3,C.panel);fill(ox,oy,vw+2,1,C.pink);text(ox+2,oy+2,fit(d.name or "CONTROLLER",vw-4),C.white,C.panel);rule(ox+2,oy+3,vw-2,C.line)
 if frame then for y=1,math.min(vh-3,sz.h) do local row=frame[y];if row then for x=1,math.min(vw,sz.w) do local cell=row[x];if cell then gpu.setBackground(cell[3] or C.black);gpu.setForeground(cell[2] or C.white);gpu.set(ox+x,oy+3+y,cell[1] or " ") end end end end else text(ox+4,oy+8,"WAITING FOR REMOTE SCREEN...",C.dim) end
 fill(ox,oy+vh+1,vw+2,2,C.bar);text(ox+2,oy+vh+2,"LIVE  |  ENTER=PING  |  R=REFRESH  |  ESC=DEVICES",C.dim,C.bar);nav()
end
local function systemPage()
 header("SYSTEM","TIER-3 DIAGNOSTICS")
 panel(3,7,36,12,"COMPUTER",C.yellow);text(7,10,"UPTIME",C.dim);text(19,10,string.format("%.1fs",computer.uptime()),C.white);text(7,12,"ENERGY",C.dim);text(19,12,computer.energy and math.floor(computer.energy()) or "N/A",C.green);text(7,14,"MAX ENERGY",C.dim);text(19,14,computer.maxEnergy and math.floor(computer.maxEnergy()) or "N/A",C.white);text(7,16,"TIER",C.dim);text(19,16,"TIER-3",C.cyan);text(7,18,"NETWORK",C.dim);text(19,18,"EMBEDDED HUB",C.green)
 panel(41,7,37,12,"ARCHITECTURE",C.cyan);text(44,10,"CENTRAL",C.dim);text(56,10,"BULDACITY OS",C.white);text(44,12,"NORMAL PCs",C.dim);text(56,12,"NETWORK APPS",C.green);text(44,14,"DESKTOP APPS",C.dim);text(56,14,"*_Modern.lua",C.purple);text(44,16,"PROTOCOL",C.dim);text(56,16,PROTOCOL,C.cyan);text(44,18,"PORT",C.dim);text(56,18,PORT,C.yellow)
 panel(3,21,75,H-25,"ABOUT",C.purple);text(7,24,"One central Tier-3 desktop controls the fleet.",C.white);text(7,26,"Modern controller files stay as local desktop applications.",C.dim);text(7,28,"Normal controller PCs provide their own network side and announce themselves.",C.dim);text(7,30,"No whitelist / UUID access-control layer is used.",C.dim);nav()
end
local function draw()
 W,H=gpu.getResolution();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")
 if page=="HOME" then home() elseif page=="NETWORK" then networkPage() elseif page=="DEVICES" then devicesPage() elseif page=="APPS" then appsPage() elseif page=="REMOTE" then remotePage() else systemPage() end
end

local function remember(sender,p,distance)
 local data=p.data or {};local d=devices[sender] or {address=sender};devices[sender]=d
 for k,v in pairs(data) do d[k]=v end;d.address=sender;d.last=now();d.distance=distance
end
local function input(d,eventName,a,b,c) if d then network.send(d.address,"INPUT",{event=eventName,x=a,y=b,char=a,code=b,button=c}) end end

network.startServer(function(sender,p,distance)
 if p.kind=="HELLO" or p.kind=="HEARTBEAT" then remember(sender,p,distance);status="CLIENT ONLINE";return end
 if p.kind=="PONG" then remember(sender,p,distance);return end
 if p.kind=="SCREEN_BEGIN" then local s=p.data or {};frameSize[sender]={w=tonumber(s.width) or W,h=tonumber(s.height) or H};frames[sender]={};dirty=true;return end
 if p.kind=="SCREEN_ROW" then local s=p.data or {};if frames[sender] and s.y then frames[sender][s.y]=s.cells end;dirty=true;return end
 if p.kind=="SCREEN_END" then local d=devices[sender];if d then d.last=now();d.screen=now() end;dirty=true;return end
end)

log("BULDACITY OS "..VERSION.." started")
log("Self-contained Tier-3 network hub on port "..PORT)
hello()
event.timer(3,hello,math.huge)
event.timer(5,scan,math.huge)
event.timer(1,function() if page=="REMOTE" then requestScreen(selectedDevice()) end end,math.huge)
draw()

while running do
 local e,a,b,c,distance=event.pull(0.20)
 if e=="key_down" then
  local char=b or 0;local code=c or 0;local target=selectedDevice()
  if char==113 or char==81 then running=false
  elseif char==49 then page="HOME";draw()
  elseif char==50 then page="NETWORK";draw()
  elseif char==51 then page="DEVICES";draw()
  elseif char==52 then page="APPS";draw()
  elseif char==53 then page="REMOTE";requestScreen(target);draw()
  elseif char==54 then page="SYSTEM";draw()
  elseif char==114 or char==82 then scan();draw()
  elseif char==119 or code==200 then selected=math.max(1,selected-1);draw()
  elseif char==115 or code==208 then selected=selected+1;draw()
  elseif code==28 or code==57 then if page=="DEVICES" and target then page="REMOTE";requestScreen(target);draw() elseif page=="REMOTE" and target then send(target,"PING",{from="REMOTE"}) end
  elseif char==27 then page="DEVICES";draw()
  elseif page=="REMOTE" and target and now()-lastInput>0.03 then input(target,"key_down",char,code);lastInput=now()
  end
 elseif e=="touch" then
  local x,y,button=b,c,distance;local target=selectedDevice()
  if page=="DEVICES" then local idx=y-9;if idx>=1 and idx<=#deviceList() then selected=idx;draw() end
  elseif page=="REMOTE" and target then
   local sz=frameSize[target.address] or {w=W,h=H};local rx=math.max(1,math.min(sz.w,x-4));local ry=math.max(1,math.min(sz.h,y-10));input(target,"touch",rx,ry,button);lastInput=now()
  end
 elseif e=="scroll" then
  local target=selectedDevice();if page=="REMOTE" and target then input(target,"scroll",b,c,distance);lastInput=now() end
 end
 if now()-lastInput>0.5 then status="ONLINE" end
end
