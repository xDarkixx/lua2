-- BuldacityDesktop_Tier3.lua
-- Full OpenComputers Tier-3 wireless desktop / control center.
-- Requires a Tier-3 computer, GPU, screen and Network/Wireless Network Card.

local component = require("component")
local event = require("event")
local computer = require("computer")
local wireless = require("BuldacityWireless")

local PORT = 4242
local PROTOCOL = "BULDACITY/2"
local ok, mode = wireless.init(PORT)
if not ok then error("BULDACITY: OpenComputers modem required") end

local gpu = component.gpu
local W, H = gpu.maxResolution()
local page = "HOME"
local selected = 1
local devices = {}
local lastDraw = 0
local running = true

local C = {
  bg=0x05070D, bar=0x0B1020, panel=0x10172A, panel2=0x18233D,
  cyan=0x00E5FF, blue=0x4B8DFF, purple=0xB060FF, pink=0xFF3CCB,
  green=0x36FF91, yellow=0xFFD84D, red=0xFF4D6D, white=0xEDF7FF,
  dim=0x71839B
}

local function text(x,y,s,c)
  gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or ""))
end
local function fill(x,y,w,h,c)
  gpu.setBackground(c); gpu.fill(x,y,w,h," ")
end
local function line(x,y,w,c)
  gpu.setForeground(c or C.dim); gpu.set(x,y,string.rep("-", math.max(0,w)))
end
local function card(x,y,w,h,title,accent)
  fill(x,y,w,h,C.panel); text(x+2,y,title,accent or C.cyan); line(x,y+1,w,C.dim)
end
local function online(d)
  return computer.uptime() - (d.last or 0) <= 12
end
local function listDevices()
  local r={}
  for _,d in pairs(devices) do r[#r+1]=d end
  table.sort(r,function(a,b) return tostring(a.name or "") < tostring(b.name or "") end)
  return r
end
local function send(d, kind, data)
  if not d or not d.address or not online(d) then return false end
  return wireless.send(d.address, kind, data)
end
local function broadcast(kind,data)
  return wireless.broadcast(kind,data)
end
local function announce()
  broadcast("SERVER_HELLO", {name="BULDACITY TIER-3", role="SERVER", app="BULDACITY OS", screen="DESKTOP", mode=mode})
end
local function upsert(address,data)
  if not address then return end
  local d=devices[address] or {address=address}
  devices[address]=d
  for k,v in pairs(data or {}) do d[k]=v end
  d.last=computer.uptime()
end
local function selectedDevice()
  local list=listDevices()
  if #list==0 then return nil end
  selected=math.max(1,math.min(selected,#list))
  return list[selected]
end
local function titlebar()
  fill(1,1,W,3,C.bar)
  text(3,1,"[ BULDACITY OS ]",C.cyan)
  text(22,1,"TIER-3 CONTROL CENTER",C.purple)
  text(math.max(1,W-18),1,os.date("%H:%M:%S"),C.white)
  text(3,2,"OpenComputers Network Desktop",C.dim)
  text(math.max(1,W-18),2,wireless.isWireless() and "WIRELESS" or "WIRED",wireless.isWireless() and C.green or C.yellow)
end
local function taskbar()
  fill(1,H-2,W,3,C.bar)
  text(3,H-1,"[1] HOME",page=="HOME" and C.white or C.dim)
  text(16,H-1,"[2] DEVICES",page=="DEVICES" and C.white or C.dim)
  text(32,H-1,"[3] REMOTE",page=="REMOTE" and C.white or C.dim)
  text(49,H-1,"[R] RESCAN",C.yellow)
  text(math.max(1,W-10),H-1,"[Q] EXIT",C.red)
end
local function home()
  titlebar()
  local list=listDevices(); local n=0
  for _,d in ipairs(list) do if online(d) then n=n+1 end end
  card(3,5,31,8,"NETWORK STATUS",C.cyan)
  text(6,7,"LINK",C.dim); text(18,7,wireless.isWireless() and "WIRELESS" or "WIRED",C.green)
  text(6,9,"PORT",C.dim); text(18,9,PORT,C.yellow)
  text(6,11,"RANGE",C.dim); text(18,11,wireless.strength() or "N/A",C.white)
  card(37,5,41,8,"TIER-3 SERVER",C.purple)
  text(40,7,"ADDRESS",C.dim); text(52,7,wireless.address(),C.white)
  text(40,9,"PROTOCOL",C.dim); text(52,9,PROTOCOL,C.cyan)
  text(40,11,"CLIENTS",C.dim); text(52,11,#list .. " / " .. n .. " online",C.green)
  card(3,15,75,9,"CONNECTED CONTROLLERS",C.pink)
  if #list==0 then
    text(7,19,"No Tier-2 controller detected.",C.dim)
    text(7,21,"Install BuldacityNetworkClient.lua and enable a modem.",C.white)
  else
    for i,d in ipairs(list) do
      if i>4 then break end
      local y=17+i
      text(7,y,string.format("%02d",i),C.dim)
      text(12,y,(d.name or "UNKNOWN"):sub(1,25),C.white)
      text(40,y,(d.role or "CLIENT"):sub(1,12),C.dim)
      text(56,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red)
    end
  end
  taskbar()
end
local function devicesPage()
  titlebar(); card(3,5,75,H-9,"DEVICE MANAGER",C.purple)
  local list=listDevices(); selected=math.max(1,math.min(selected,math.max(1,#list)))
  if #list==0 then text(7,9,"Waiting for Tier-2 controllers...",C.dim) end
  for i,d in ipairs(list) do
    local y=7+i; if y>H-4 then break end
    if i==selected then fill(5,y,70,1,C.panel2) end
    text(7,y,string.format("%02d",i),C.dim)
    text(12,y,(d.name or "UNKNOWN"):sub(1,24),i==selected and C.cyan or C.white)
    text(39,y,(d.role or "CLIENT"):sub(1,12),C.dim)
    text(55,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red)
  end
  taskbar()
end
local function remotePage()
  titlebar(); card(3,5,75,H-9,"REMOTE CONTROL",C.pink)
  local d=selectedDevice()
  if not d then text(7,9,"No controller selected.",C.dim); taskbar(); return end
  text(7,7,"DEVICE",C.dim); text(20,7,d.name or "UNKNOWN",C.cyan)
  text(7,9,"STATUS",C.dim); text(20,9,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red)
  text(7,11,"ROLE",C.dim); text(20,11,d.role or "CLIENT",C.white)
  text(7,13,"APP",C.dim); text(20,13,d.app or "-",C.white)
  text(7,15,"ADDRESS",C.dim); text(20,15,d.address or "-",C.dim)
  text(7,18,"REMOTE INPUT",C.yellow)
  text(7,20,"Keyboard and mouse/touch events are forwarded through OC modem packets.",C.white)
  text(7,22,"Use this Tier-3 desktop as the central operator console.",C.white)
  text(7,24,"[ENTER] ping   [R] rescan",C.dim)
  taskbar()
end
local function draw()
  W,H=gpu.maxResolution(); gpu.setBackground(C.bg); gpu.fill(1,1,W,H," ")
  if page=="HOME" then home() elseif page=="DEVICES" then devicesPage() else remotePage() end
end

announce(); event.timer(3,announce,math.huge); draw()
while running do
  local e,a,b,c,d=event.pull(0.5)
  if e=="key_down" then
    local char=b or 0; local key=c or 0; local target=selectedDevice()
    if key==17 then running=false
    elseif char==49 then page="HOME"
    elseif char==50 then page="DEVICES"
    elseif char==51 then page="REMOTE"
    elseif char==19 then announce()
    elseif key==200 then selected=math.max(1,selected-1); page="DEVICES"
    elseif key==208 then selected=selected+1; page="DEVICES"
    elseif key==28 and target then send(target,"PING",{from="TIER3"})
    elseif page=="REMOTE" and target then send(target,"INPUT",{event="key_down",char=char,code=key}) end
  elseif e=="key_up" and page=="REMOTE" then
    local target=selectedDevice(); if target then send(target,"INPUT",{event="key_up",char=b or 0,code=c or 0}) end
  elseif e=="touch" then
    local x,y=a,b; local list=listDevices()
    if y>=H-2 and x<14 then page="HOME"
    elseif y>=H-2 and x<30 then page="DEVICES"
    elseif y>=H-2 and x<47 then page="REMOTE"
    elseif y>=H-2 and x<65 then announce()
    elseif page=="DEVICES" and y>=8 and y<=H-4 then selected=math.max(1,math.min(#list,y-7)); page="REMOTE"
    elseif page=="REMOTE" then local target=selectedDevice(); if target then send(target,"INPUT",{event="touch",x=x,y=y,button=1}) end end
  elseif e=="scroll" and page=="REMOTE" then
    local target=selectedDevice(); if target then send(target,"INPUT",{event="scroll",x=a or 0,y=b or 0,button=c or 0}) end
  elseif e=="modem_message" and c==PORT then
    local p=d
    if wireless.valid(p) and p.kind~="SERVER_HELLO" then
      if p.kind=="HELLO" or p.kind=="HEARTBEAT" or p.kind=="PONG" then upsert(b,p.data) end
    end
  end
  if computer.uptime()-lastDraw>=1 then lastDraw=computer.uptime(); draw() end
end
fill(1,1,W,H,0x000000)
