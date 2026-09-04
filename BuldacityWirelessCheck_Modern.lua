-- BuldacityWirelessCheck_Modern.lua
-- BULDACITY graphical wireless/component diagnostics
-- OpenComputers 1.7.10 / BULDACITY/2

local component=require("component")
local event=require("event")
local computer=require("computer")
local network=require("Network")

local gpu=component.gpu
local W,H=gpu.getResolution()
local running=true
local dirty=true
local status="CHECKING"
local info={}

local C={bg=0x060A12,bar=0x0B1220,panel=0x111B2B,line=0x29415F,cyan=0x00E5FF,purple=0xA66CFF,green=0x35F59A,yellow=0xFFD34E,red=0xFF5572,white=0xEAF6FF,dim=0x71859E}

local function fill(x,y,w,h,c)
 gpu.setBackground(c);gpu.fill(x,y,w,h," ")
end
local function text(x,y,s,c,bg)
 gpu.setForeground(c or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or ""))
end
local function fit(s,n)
 s=tostring(s or "");if #s<=n then return s end;if n<2 then return s:sub(1,n) end;return s:sub(1,n-1).."…"
end
local function panel(x,y,w,h,title,c)
 fill(x,y,w,h,C.panel);fill(x,y,w,1,c);text(x+2,y+1,"◆ "..fit(title,w-5),c,C.panel)
end
local function scan()
 info=network.componentCheck()
 info.modems={}
 for address in component.list("modem",true) do
  local m=component.proxy(address)
  if m then
   local wireless=type(m.setStrength)=="function" or type(m.getStrength)=="function"
   local strength=0
   if wireless and type(m.getStrength)=="function" then pcall(function() strength=m.getStrength() or 0 end) end
   info.modems[#info.modems+1]={address=address,wireless=wireless,strength=tonumber(strength) or 0}
  end
 end
 info.relays={}
 for address in component.list("relay",true) do
  local r=component.proxy(address)
  if r then
   local strength=0
   if type(r.getStrength)=="function" then pcall(function() strength=r.getStrength() or 0 end) end
   info.relays[#info.relays+1]={address=address,strength=tonumber(strength) or 0,repeater=type(r.setRepeater)=="function"}
  end
 end
 info.accessPoints={}
 for address in component.list("access_point",true) do
  local a=component.proxy(address)
  if a then
   local strength=0
   if type(a.getStrength)=="function" then pcall(function() strength=a.getStrength() or 0 end) end
   info.accessPoints[#info.accessPoints+1]={address=address,strength=tonumber(strength) or 0,repeater=type(a.setRepeater)=="function"}
  end
 end
 if not info.wirelessAvailable then status="WIRELESS MISSING"
 elseif not info.wirelessReady then status="WIRELESS NOT READY"
 else status="WIRELESS READY" end
 dirty=true
end
local function render()
 W,H=gpu.getResolution();fill(1,1,W,H,C.bg)
 fill(1,1,W,5,C.bar);fill(1,5,W,1,C.cyan)
 text(2,2,"◈ BULDACITY",C.cyan,C.bar);text(17,2,"WIRELESS HARDWARE CHECK",C.white,C.bar)
 local sc=status=="WIRELESS READY" and C.green or C.red
 text(math.max(1,W-25),2,"● "..status,sc,C.bar)
 panel(3,7,36,10,"WIRELESS MODEM / CARD",C.purple)
 text(6,10,"PRESENT",C.dim);text(18,10,info.wirelessAvailable and "YES" or "NO",info.wirelessAvailable and C.green or C.red)
 text(6,12,"READY",C.dim);text(18,12,info.wirelessReady and "YES" or "NO",info.wirelessReady and C.green or C.red)
 text(6,14,"STRENGTH",C.dim);text(18,14,tostring(info.wirelessStrength or 0),info.wirelessReady and C.green or C.yellow)
 text(6,16,"MODEMS",C.dim);text(18,16,tostring(info.modemCount or 0),C.white)
 panel(42,7,37,10,"PATH COMPONENTS",C.cyan)
 text(45,10,"RELAYS",C.dim);text(56,10,tostring(info.relayCount or 0),C.white)
 text(45,12,"ACCESS POINTS",C.dim);text(60,12,tostring(info.accessPointCount or 0),C.white)
 text(45,14,"WIRELESS PATHS",C.dim);text(60,14,tostring(info.relayWirelessCount or 0),C.green)
 text(45,16,"COMPONENT",C.dim);text(60,16,fit(info.wirelessComponent or "NONE",16),C.cyan)
 panel(3,19,76,math.max(8,H-25),"DETAILED COMPONENT TEST",C.green)
 local y=22
 for i,m in ipairs(info.modems or {}) do
  if y>H-7 then break end
  text(6,y,"MODEM",C.dim);text(14,y,fit(m.address,16),C.white);text(32,y,m.wireless and "WIRELESS" or "WIRED",m.wireless and C.purple or C.cyan);text(46,y,m.wireless and (m.strength>0 and "SIGNAL OK" or "SIGNAL OFF") or "CABLE LINK",m.wireless and (m.strength>0 and C.green or C.red) or C.cyan);y=y+2
 end
 for i,r in ipairs(info.relays or {}) do
  if y>H-7 then break end
  text(6,y,"RELAY",C.dim);text(14,y,fit(r.address,16),C.white);text(32,y,"WIRELESS SLOT",C.purple);text(46,y,r.strength>0 and "SIGNAL OK" or "NO WIRELESS",r.strength>0 and C.green or C.yellow);y=y+2
 end
 for i,a in ipairs(info.accessPoints or {}) do
  if y>H-7 then break end
  text(6,y,"ACCESS POINT",C.dim);text(19,y,fit(a.address,16),C.white);text(37,y,"BRIDGE",C.cyan);text(46,y,a.strength>0 and "SIGNAL OK" or "NO WIRELESS",a.strength>0 and C.green or C.yellow);y=y+2
 end
 if y<=H-5 then
  text(6,y+1,"WHAT IS REQUIRED",C.yellow)
  if not info.wirelessAvailable then text(6,y+3,"Install a Wireless Network Card in the OpenComputers PC.",C.white)
  elseif not info.wirelessReady then text(6,y+3,"Wireless card found, but signal strength is zero/not configured.",C.white)
  else text(6,y+3,"Wireless hardware is present and configured. End-to-end PING still verifies the real link.",C.white) end
 end
 fill(1,H-3,W,4,C.bar);text(3,H-1,"R = RESCAN    Q = EXIT",C.dim,C.bar);text(math.max(1,W-28),H-1,"BULDACITY COMPONENT TEST",C.cyan,C.bar)
 dirty=false
end

scan()
while running do
 if dirty then render() end
 local e,_,char,code=event.pull(0.5)
 if e=="key_down" then
  if char==113 or char==81 or code==16 then running=false elseif char==114 or char==82 then scan() end
 end
end
fill(1,1,W,H,C.bg);text(3,3,"Wireless component check finished.",C.cyan,C.bg)
