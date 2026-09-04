-- BuldacityServer_Tier3.lua
-- BULDACITY // TIER 3 SERVER DESKTOP
-- OpenComputers 1.7.10 / protocol BULDACITY/1 / port 4242
-- Full-screen PC-style server UI.
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local PORT=4242
local PROTOCOL="BULDACITY/1"
local running=true
local page="DESKTOP"
local selected=1
local devices={}
local lastDraw=0
local C={bg=0x05070D,bar=0x0B1020,panel=0x10172A,panel2=0x151F36,cyan=0x00E5FF,blue=0x3E82FF,purple=0xB060FF,pink=0xFF3CCB,green=0x36FF91,yellow=0xFFD84D,red=0xFF4D6D,white=0xEDF7FF,dim=0x71839B}
local modem
for address in component.list("modem",true) do modem=component.proxy(address); break end
if not modem then error("Buldacity Tier-3 Server requires a Network/Wireless Network Card") end
modem.open(PORT)
local function text(x,y,s,c) gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or "")) end
local function fill(x,y,w,h,c) gpu.setBackground(c); gpu.fill(x,y,w,h," ") end
local function line(x,y,w,c) gpu.setForeground(c or C.dim); gpu.set(x,y,string.rep("-",math.max(0,w))) end
local function card(x,y,w,h,title,accent) fill(x,y,w,h,C.panel); text(x+2,y,title,accent or C.cyan); line(x,y+1,w,C.dim) end
local function online(d) return computer.uptime()-(d.last or 0)<=10 end
local function listDevices() local r={}; for _,d in pairs(devices) do r[#r+1]=d end; table.sort(r,function(a,b) return tostring(a.name or "")<tostring(b.name or "") end); return r end
local function upsert(sender,data) local d=devices[sender] or {address=sender}; devices[sender]=d; for k,v in pairs(data or {}) do d[k]=v end; d.last=computer.uptime() end
local function packet(kind,data) return {protocol=PROTOCOL,kind=kind,sender=computer.address(),time=computer.uptime(),data=data or {}} end
local function broadcast(kind,data) modem.broadcast(PORT,packet(kind,data)) end
local function announce() broadcast("SERVER",{name="BULDACITY SERVER",role="SERVER",app="Buldacity OS",screen="SERVER ONLINE"}) end
local function titlebar() fill(1,1,W,3,C.bar); text(3,1,"[ BULDACITY OS ]",C.cyan); text(22,1,"TIER 3 SERVER",C.purple); text(W-18,1,os.date("%H:%M:%S"),C.white); text(3,2,"Network Command Desktop",C.dim); text(W-25,2,"NET",C.dim); text(W-20,2,"ONLINE",C.green) end
local function taskbar() fill(1,H-2,W,3,C.bar); text(3,H-1,"[START]",C.cyan); text(14,H-1,"[DESKTOP]",page=="DESKTOP" and C.white or C.dim); text(28,H-1,"[DEVICES]",page=="DEVICES" and C.white or C.dim); text(41,H-1,"[REMOTE]",page=="REMOTE" and C.white or C.dim); text(56,H-1,"[R] RESCAN",C.yellow); text(W-10,H-1,"[Q] EXIT",C.red) end
local function desktop() titlebar(); local list=listDevices(); local n=0; for _,d in ipairs(list) do if online(d) then n=n+1 end end; card(3,5,25,8,"NETWORK",C.cyan); text(6,7,"STATUS",C.dim); text(15,7,"CONNECTED",C.green); text(6,9,"CLIENTS",C.dim); text(15,9,#list,C.white); text(6,11,"ONLINE",C.dim); text(15,11,n,C.green); card(31,5,46,8,"SYSTEM",C.purple); text(34,7,"HOST",C.dim); text(46,7,"BULDACITY TIER 3",C.white); text(34,9,"PROTOCOL",C.dim); text(46,9,PROTOCOL,C.cyan); text(34,11,"PORT",C.dim); text(46,11,PORT,C.yellow); card(3,15,74,7,"BULDACITY DEVICES",C.pink); if #list==0 then text(7,18,"No Tier-2 controller connected yet.",C.dim); text(7,20,"Start BuldacityControllerLauncher on a Tier-2 PC.",C.white) else for i,d in ipairs(list) do if i>3 then break end; local y=17+i; text(7,y,string.format("%02d",i),C.dim); text(12,y,(d.name or "UNKNOWN"):sub(1,25),C.white); text(40,y,d.role or "CLIENT",C.dim); text(56,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red) end end; taskbar() end
local function devicesPage() titlebar(); card(3,5,74,H-9,"DEVICE MANAGER",C.purple); local list=listDevices(); selected=math.max(1,math.min(selected,math.max(1,#list))); if #list==0 then text(7,9,"Waiting for Buldacity clients...",C.dim) end; for i,d in ipairs(list) do local y=7+i; if y>H-4 then break end; if i==selected then fill(5,y,69,1,C.panel2) end; text(7,y,string.format("%02d",i),C.dim); text(12,y,(d.name or "UNKNOWN"):sub(1,24),i==selected and C.cyan or C.white); text(39,y,(d.role or "CLIENT"):sub(1,12),C.dim); text(55,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red) end; taskbar() end
local function remotePage() titlebar(); card(3,5,74,H-9,"REMOTE DESKTOP",C.pink); local d=listDevices()[selected]; if not d then text(7,9,"Select a device in DEVICE MANAGER first.",C.dim); taskbar(); return end; text(7,7,"DEVICE",C.dim); text(19,7,d.name or "UNKNOWN",C.cyan); text(7,9,"ROLE",C.dim); text(19,9,d.role or "CLIENT",C.white); text(7,11,"STATUS",C.dim); text(19,11,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red); text(7,13,"APPLICATION",C.dim); text(19,13,d.app or "-",C.white); text(7,15,"ADDRESS",C.dim); text(19,15,d.address or "-",C.dim); text(7,18,"REMOTE DISPLAY",C.yellow); text(7,20,d.screen or "No display telemetry reported.",C.white); text(7,22,"Status metadata only; no pixel mirroring is implemented yet.",C.dim); taskbar() end
local function draw() W,H=gpu.maxResolution(); gpu.setResolution(W,H); gpu.setBackground(C.bg); gpu.fill(1,1,W,H," "); if page=="DESKTOP" then desktop() elseif page=="DEVICES" then devicesPage() else remotePage() end end
announce(); event.timer(3,announce,math.huge); draw()
while running do local e,a,b,c,d=event.pull(0.5); if e=="key_down" then local key=d; if key==17 then running=false elseif key==2 then page="DESKTOP" elseif key==3 then page="DEVICES" elseif key==4 then page="REMOTE" elseif key==200 then selected=math.max(1,selected-1); page="DEVICES" elseif key==208 then selected=selected+1; page="DEVICES" elseif key==19 then announce() end elseif e=="touch" then local x,y=a,b; if y>=H-2 and x<27 then page="DESKTOP" elseif y>=H-2 and x<40 then page="DEVICES" elseif y>=H-2 and x<55 then page="REMOTE" elseif y>=H-2 and x<69 then announce() end elseif e=="modem_message" and c==PORT then local p=d; if type(p)=="table" and p.protocol==PROTOCOL and p.kind~="SERVER" then upsert(b,p.data or {}) end end; if computer.uptime()-lastDraw>=1 then lastDraw=computer.uptime(); draw() end end
gpu.setBackground(0); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
