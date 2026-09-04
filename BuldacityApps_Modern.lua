-- BuldacityApps_Modern.lua
-- BULDACITY OS // Remote PC & App Center
-- Runs on the Tier-3 central server and uses BULDACITY/2.
-- All files are loaded from /home.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local network=require("Network")

local gpu=component.gpu
local PORT=4242
local W,H=gpu.getResolution()
local C={bg=0x060A12,bar=0x0B1220,panel=0x111B2B,panel2=0x192944,line=0x29415F,cyan=0x00E5FF,purple=0xA66CFF,pink=0xFF3EBB,green=0x35F59A,yellow=0xFFD34E,red=0xFF5572,white=0xEAF6FF,dim=0x71859E}
local devices={}
local frames={}
local frameSize={}
local selected=1
local mode="APPS"
local dirty=true
local running=true
local status="READY"

local function now() return computer.uptime() end
local function clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
local function fit(s,n)
 s=tostring(s or "");n=math.max(1,n or 1);if #s<=n then return s end
 return n<=1 and s:sub(1,1) or s:sub(1,n-1).."…"
end
local function fill(x,y,w,h,c)
 gpu.setBackground(c or C.bg);gpu.fill(x,y,w,h," ")
end
local function text(x,y,s,fg,bg)
 if x>=1 and y>=1 and x<=W and y<=H then gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or "")) end
end
local function panel(x,y,w,h,title,c)
 fill(x,y,w,h,C.panel);fill(x,y,w,1,c or C.cyan);text(x+2,y+1,"◆ "..fit(title,w-5),c or C.cyan,C.panel)
 if h>3 then fill(x+2,y+2,w-4,1,C.line) end
end
local function button(x,y,w,label,c,active)
 local bg=active and C.panel2 or C.bar;fill(x,y,w,3,bg);fill(x,y,w,1,c or C.cyan);text(x+2,y+1,fit(label,w-4),active and C.white or (c or C.cyan),bg)
end
local function list() local r={};for _,d in pairs(devices) do r[#r+1]=d end;table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address) end);return r end
local function selectedDevice() local l=list();if #l==0 then return nil end;selected=clamp(selected,1,#l);return l[selected] end
local function online(d) return d and now()-(d.last or 0)<12 end

local function syncDevices()
 local diag=network.getDiagnostics and network.getDiagnostics() or network.status().diagnostics or {}
 for address,d in pairs(diag) do
  devices[address]=d;devices[address].address=address
 end
 dirty=true
end
local function requestScreen(d)
 if not d or not online(d) then return end
 network.send(d.address,"SCREEN_REQUEST",{from="BULDACITY APP CENTER",live=true})
 status="SCREEN REQUEST SENT"
end
local function sendInput(d,data)
 if d and online(d) then network.send(d.address,"INPUT",data);status="INPUT SENT" end
end
local function drawTop()
 fill(1,1,W,H,C.bg);fill(1,1,W,5,C.bar);fill(1,5,W,1,C.pink)
 text(2,2,"◈ BULDACITY APP CENTER",C.pink,C.bar);text(30,2,"REMOTE PCs + APPLICATIONS",C.white,C.bar);text(math.max(1,W-18),2,"TIER-3",C.cyan,C.bar)
 text(2,3,"Select a client to open its live desktop",C.dim,C.bar);text(math.max(1,W-18),3,online(selectedDevice()) and "● LINKED" or "○ OFFLINE",online(selectedDevice()) and C.green or C.red,C.bar)
end
local function drawApps()
 panel(3,7,76,H-11,"CONNECTED PCs / APPLICATIONS",C.pink)
 local l=list();if #l==0 then text(7,12,"Waiting for BULDACITY clients...",C.dim);text(7,14,"R = refresh discovery",C.dim);return end
 for i,d in ipairs(l) do local y=9+i;if y>H-7 then break end;local a=i==selected;if a then fill(5,y,70,2,C.panel2);fill(5,y,2,2,C.pink) end
  local st=online(d) and (d.linked and "LINKED" or "ONLINE") or "OFFLINE";local sc=st=="LINKED" and C.green or st=="OFFLINE" and C.red or C.yellow
  text(8,y,string.format("%02d",i),C.dim);text(13,y,fit(d.name or d.app or "CLIENT",23),a and C.cyan or C.white);text(37,y,fit(d.mod or d.controller or d.app or "NETWORK CLIENT",18),C.dim);text(57,y,fit(d.link or (d.wireless and "WIRELESS" or "WIRED"),9),C.cyan);text(68,y,st,sc)
 end
 text(7,H-5,"ENTER = live desktop   S = refresh   R = network discovery   Q = close",C.dim)
end
local function drawRemote()
 local d=selectedDevice();panel(3,7,58,H-11,"LIVE DESKTOP // "..fit(d and d.name or "NONE",35),C.cyan)
 if not d then text(7,12,"No client selected.",C.dim);return end
 if not online(d) then text(7,12,"CLIENT OFFLINE",C.red);return end
 local f=frames[d.address];if not f then text(7,12,"Requesting live desktop...",C.dim);requestScreen(d);return end
 local sz=frameSize[d.address] or {w=80,h=25};text(6,9,string.format("LIVE %dx%d   %s",sz.w,sz.h,d.linked and "LINKED" or "ONLINE"),C.green)
 local sy=math.max(1,math.ceil(sz.h/math.max(1,H-14)));local sx=math.max(1,math.ceil(sz.w/52));local y=11
 for row=1,sz.h,sy do if y>H-6 then break end;local cells=f[row] or {};local out="";for col=1,sz.w,sx do local c=cells[col];out=out..(c and tostring(c[1] or c.ch or " ") or " ") end;text(6,y,fit(out,52),C.white);y=y+1 end
 panel(63,7,16,H-11,"CONTROL",C.purple)
 button(65,10,12,"UP",C.cyan);button(65,14,12,"DOWN",C.cyan);button(65,18,12,"LEFT",C.cyan);button(65,22,12,"RIGHT",C.cyan);button(65,26,12,"ENTER",C.green);button(65,30,12,"REFRESH",C.pink);text(65,35,"ESC/Q = back",C.dim)
end
local function render()
 W,H=gpu.getResolution();drawTop();if mode=="APPS" then drawApps() else drawRemote() end;dirty=false
end

local ok,why=network.startServer(function(sender,p,distance)
 if p.kind=="HELLO" or p.kind=="HEARTBEAT" or p.kind=="PONG" or p.kind=="LINK_CONFIRM" then syncDevices();return end
 if p.kind=="SCREEN_BEGIN" and type(p.data)=="table" then frames[sender]={};frameSize[sender]={w=tonumber(p.data.width) or 80,h=tonumber(p.data.height) or 25};dirty=true;return end
 if p.kind=="SCREEN_ROW" and type(p.data)=="table" then frames[sender]=frames[sender] or {};frames[sender][tonumber(p.data.y) or 1]=p.data.cells or {};dirty=true;return end
 if p.kind=="SCREEN_END" then dirty=true;return end
end)
if not ok then error("BULDACITY App Center: network unavailable: "..tostring(why)) end

network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY APP CENTER",protocol="BULDACITY/2",port=PORT})
syncDevices()
event.timer(2,syncDevices,math.huge)
event.timer(3,function() local d=selectedDevice();if mode=="REMOTE" and d and online(d) and not frames[d.address] then requestScreen(d) end end,math.huge)
event.timer(1,function() dirty=true end,math.huge)

while running do
 if dirty then render() end
 local e,a,b,c,d=event.pull(0.2)
 if e=="key_down" then
  local char,code=b,c
  if char==113 or char==81 or code==16 then if mode=="REMOTE" then mode="APPS";dirty=true else running=false end
  elseif char==13 or code==28 then if mode=="APPS" then if selectedDevice() then mode="REMOTE";requestScreen(selectedDevice()) end else requestScreen(selectedDevice()) end
  elseif char==114 or char==82 or char==115 or char==83 then syncDevices();network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY APP CENTER",protocol="BULDACITY/2",port=PORT})
  elseif char==200 or char==72 then if mode=="APPS" then selected=math.max(1,selected-1) end
  elseif char==208 or char==80 then if mode=="APPS" then selected=math.min(#list(),selected+1) end
  elseif mode=="REMOTE" then
   local rd=selectedDevice();if code==200 then sendInput(rd,{event="key_down",char=0,code=200}) elseif code==208 then sendInput(rd,{event="key_down",char=0,code=208}) elseif code==203 then sendInput(rd,{event="key_down",char=0,code=203}) elseif code==205 then sendInput(rd,{event="key_down",char=0,code=205}) elseif code==28 then sendInput(rd,{event="key_down",char=13,code=28}) end
  end
  dirty=true
 elseif e=="touch" then
  local x,y,buttonId=b,c,d
  if mode=="APPS" then
   local l=list();if y>=10 and y<10+#l then selected=clamp(y-9,1,#l);if buttonId==0 or buttonId==1 then mode="REMOTE";requestScreen(selectedDevice()) end
   elseif y>=H-4 and x<25 then syncDevices() end
  else
   local rd=selectedDevice()
   if x>=63 then
    if y>=10 and y<14 then sendInput(rd,{event="key_down",char=0,code=200}) elseif y>=14 and y<18 then sendInput(rd,{event="key_down",char=0,code=208}) elseif y>=18 and y<22 then sendInput(rd,{event="key_down",char=0,code=203}) elseif y>=22 and y<26 then sendInput(rd,{event="key_down",char=0,code=205}) elseif y>=26 and y<30 then sendInput(rd,{event="key_down",char=13,code=28}) elseif y>=30 and y<34 then frames[rd.address]=nil;requestScreen(rd) end
   elseif rd then sendInput(rd,{event="touch",x=x,y=y,button=buttonId}) end
  end
  dirty=true
 elseif e=="modem_message" then dirty=true end
end

fill(1,1,W,H,C.bg);text(3,3,"BULDACITY APP CENTER closed.",C.cyan,C.bg)
