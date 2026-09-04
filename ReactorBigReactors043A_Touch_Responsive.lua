-- ReactorBigReactors043A_Touch_Responsive.lua
-- BULDACITY Reactor / Turbine HUD
-- Minecraft 1.7.10 / Big Reactors 0.4.3A / OpenComputers
-- Page 1 = Reactor + AUTO energy control
-- Page 2 = Turbine information

local component=require("component")
local event=require("event")
local keyboard=require("keyboard")
local gpu=component.gpu

local reactors={}; local selected=1; local rod=0; local page="reactor"
local running=true; local auto=false; local message="BULDACITY REACTOR SYSTEM READY"; local pulse=0

-- AUTO: reactor starts when stored energy is below 10% and stops at 90%.
-- Temperature and fuel remain safety limits.
local AUTO_ON_ENERGY=10
local AUTO_OFF_ENERGY=90
local AUTO_STOP_TEMP=900
local AUTO_MIN_FUEL=1

local C={bg=0x03060B,panel=0x0A111B,panel2=0x101C29,line=0x214057,
 cyan=0x35E8FF,blue=0x438CFF,green=0x35FF9A,red=0xFF466D,yellow=0xFFE36A,
 purple=0xC56BFF,pink=0xFF4CCB,orange=0xFF9D45,white=0xF3FAFF,grey=0x7D96AA,off=0x263541}
local W,H=80,25
local ui={}

local function safe(fn,...)
 local ok,a,b,c,d=pcall(fn,...); if ok then return a,b,c,d end
end
local function invoke(addr,name,...)
 if not addr then return false,nil end
 local ok,a,b,c,d=pcall(component.invoke,addr,name,...)
 return ok,a,b,c,d
end
local function resize()
 local mw,mh=safe(gpu.maxResolution); local cw,ch=safe(gpu.getResolution)
 mw,mh=mw or cw or 80,mh or ch or 25
 safe(gpu.setResolution,mw,mh)
 W,H=safe(gpu.getResolution); W,H=W or mw,H or mh
end
resize()

local function addr() return reactors[selected] end
local function say(s) message=tostring(s) end
local function discover()
 reactors={}
 for a in component.list("br_reactor") do reactors[#reactors+1]=a end
 if #reactors==0 then selected=1;rod=0;say("NO br_reactor DETECTED")
 else
  if selected>#reactors then selected=1 end
  rod=0;say(#reactors.." REACTOR UNIT(S) DETECTED")
 end
end
discover()

local function read(name,default,...)
 local ok,v=invoke(addr(),name,...)
 if ok and v~=nil then return v end
 return default
end
local function active() return read("getActive",false)==true end
local function energy()
 local stored=tonumber(read("getEnergyStored",0)) or 0
 local max=tonumber(read("getEnergyStoredMax",0)) or 0
 return stored,max
end
local function energyPercent()
 local stored,max=energy()
 if max<=0 then return 0,stored,max end
 return math.max(0,math.min(100,stored/max*100)),stored,max
end
local function rodCount() return tonumber(read("getNumberOfControlRods",0)) or 0 end
local function rodLevel(i) return tonumber(read("getControlRodLevel",0,i)) or 0 end

local function turbineAddr()
 for a in component.list("br_turbine") do return a end
end
local function tread(name,default,...)
 local a=turbineAddr(); if not a then return default end
 local ok,v=invoke(a,name,...)
 if ok and v~=nil then return v end
 return default
end

local function setActive(v)
 if not addr() then say("NO REACTOR") return end
 local ok=invoke(addr(),"setActive",v)
 if ok then say(v and "BULDACITY: REACTOR ONLINE" or "BULDACITY: REACTOR OFFLINE")
 else say("ERROR: REACTOR COMMAND") end
end
local function setOne(i,v)
 local n=rodCount(); if n<=0 then say("NO CONTROL RODS") return end
 i=math.max(0,math.min(n-1,i)); v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))
 local ok=invoke(addr(),"setControlRodLevel",i,v)
 if ok then rod=i;say("CONTROL ROD "..i.." -> "..v.."%") else say("ERROR: ROD COMMAND") end
end
local function setAll(v)
 v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))
 local ok=invoke(addr(),"setAllControlRodLevels",v)
 say(ok and ("ALL CONTROL RODS -> "..v.."%") or "ERROR: ALL RODS")
end
local function changeRod(d) setOne(rod,rodLevel(rod)+d) end
local function nextReactor(d)
 if #reactors>0 then
  selected=((selected-1+d)%#reactors)+1; rod=0
  say("SELECTED REACTOR "..selected.." / "..#reactors)
 end
end

local function autoControl()
 if not auto or not addr() then return end
 local ep,stored,max=energyPercent()
 local t=tonumber(read("getFuelTemperature",0)) or 0
 local fuel=tonumber(read("getFuelAmount",0)) or 0
 -- Safety always wins.
 if fuel<=AUTO_MIN_FUEL then
  if active() then setActive(false) end
  say("AUTO SAFETY: FUEL EMPTY")
  return
 end
 if active() and t>=AUTO_STOP_TEMP then
  setActive(false); say("AUTO SAFETY: TEMP >= "..AUTO_STOP_TEMP.." C")
  return
 end
 -- Energy hysteresis: ON below 10%, OFF at/above 90%.
 if not active() and ep<AUTO_ON_ENERGY then
  setActive(true); say("AUTO: ENERGY "..math.floor(ep).."% -> REACTOR ON")
 elseif active() and ep>=AUTO_OFF_ENERGY then
  setActive(false); say("AUTO: ENERGY "..math.floor(ep).."% -> REACTOR OFF")
 end
end

local function clear(bg) gpu.setBackground(bg or C.bg);gpu.fill(1,1,W,H," ") end
local function txt(x,y,s,fg,bg)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s))
end
local function fit(s,n)
 s=tostring(s or ""); n=math.max(1,n or 1)
 if #s<=n then return s end
 if n==1 then return s:sub(1,1) end
 return s:sub(1,n-1).."…"
end
local function box(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c or C.panel);gpu.fill(x,y,w,h," ") end end
local function line(x,y,w,c)
 if w>0 and y>=1 and y<=H then gpu.setBackground(c or C.line);gpu.fill(x,y,math.min(w,W-x+1),1," ") end
end
local function panel(x,y,w,h,title,c)
 box(x,y,w,h,C.panel);line(x,y,w,c or C.cyan)
 txt(x+2,y,"◆ "..fit(title,w-5),c or C.cyan,C.panel)
 if h>=3 then line(x,y+h-1,w,C.line) end
end
local function led(x,y,on,c,label)
 local cc=on and(c or C.green)or C.off
 box(x,y,2,1,cc);txt(x+3,y,fit(label or(on and "ONLINE"or"OFFLINE"),math.max(1,W-x-3)),on and cc or C.grey,C.panel)
end
local function bar(x,y,w,p,c)
 w=math.max(1,w);p=math.max(0,math.min(100,tonumber(p)or 0));box(x,y,w,1,C.panel2)
 local n=math.floor(w*p/100);if n>0 then box(x,y,n,1,c or C.cyan)end
end
local function marquee(x,y,w,phase,c)
 w=math.max(3,w);box(x,y,w,1,C.panel2)
 local pos=(phase%(w+7))-7;if pos<0 then pos=0 end
 local n=math.min(8,w-pos);if n>0 then box(x+pos,y,n,1,c or C.cyan)end
end
local function button(id,x,y,w,label,c,on)
 w=math.max(5,w);ui[id]={x=x,y=y,w=w,h=2}
 box(x,y,w,2,on and C.white or c)
 txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),on and c or C.white,on and C.white or c)
end
local function hit(id,x,y)
 local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function header(title)
 box(1,1,W,4,C.panel)
 txt(3,1,"╔ BULDACITY // REACTOR SYSTEM ╗",C.cyan,C.panel)
 txt(3,2,fit(title,math.max(10,W-36)),C.white,C.panel)
 local state=active()
 led(math.max(5,W-27),2,state,state and C.green or C.red,state and "ONLINE" or "OFFLINE")
 line(1,4,W,C.cyan)
end

local function footer()
 local y=math.max(1,H-4);local gap=1;local n=7
 local bw=math.max(5,math.floor((W-4-(n-1)*gap)/n));local x=2
 button("reactor",x,y,bw,"REACTOR",C.cyan,page=="reactor");x=x+bw+gap
 button("turbine",x,y,bw,"TURBINE",C.pink,page=="turbine");x=x+bw+gap
 button("rods",x,y,bw,"RODS",C.orange,page=="rods");x=x+bw+gap
 button("prev",x,y,bw,"◀ UNIT",C.blue);x=x+bw+gap
 button("next",x,y,bw,"UNIT ▶",C.blue);x=x+bw+gap
 button("scan",x,y,bw,"SCAN",C.yellow);x=x+bw+gap
 button("exit",x,y,bw,"EXIT",C.red)
 txt(2,H,fit("[Q] EXIT  [1] REACTOR  [2] TURBINE  [←/→] UNIT  [↑/↓] ROD  [A] AUTO",math.max(1,W-4)),C.grey,C.bg)
end

local function drawReactor()
 header("PAGE 1 // REACTOR + ENERGY AUTO")
 local y=6;local h=H-12;local gap=2
 local pw=math.floor((W-6-gap)/2);if pw<20 then pw=W-6;gap=0 end
 local x1=3;local x2=x1+pw+gap
 panel(x1,y,pw,h,"REACTOR CORE // LIVE",C.cyan)
 if #reactors==0 then
  txt(x1+4,y+5,"NO br_reactor FOUND",C.red,C.panel)
 else
  local ep,en,em=energyPercent()
  local fuel=tonumber(read("getFuelAmount",0))or 0
  local fm=tonumber(read("getFuelAmountMax",1))or 1
  local t=tonumber(read("getFuelTemperature",0))or 0
  local cool=read("isActivelyCooled",false)==true
  txt(x1+3,y+3,"UNIT",C.grey,C.panel);txt(x1+18,y+3,selected.." / "..#reactors,C.white,C.panel)
  led(x1+3,y+5,active(),C.green,active()and"REACTOR ONLINE"or"REACTOR OFFLINE")
  led(x1+3,y+7,auto,C.purple,auto and"AUTO ENABLED"or"AUTO DISABLED")
  led(x1+3,y+9,cool,C.cyan,"ACTIVE COOLING")
  txt(x1+3,y+11,"ENERGY",C.grey,C.panel);txt(x1+18,y+11,math.floor(en).." RF",C.cyan,C.panel)
  txt(x1+3,y+12,"LEVEL",C.grey,C.panel);txt(x1+18,y+12,string.format("%5.1f %%",ep),ep<10 and C.red or(ep>=90 and C.green or C.yellow),C.panel)
  bar(x1+3,y+13,pw-6,ep,ep<10 and C.red or(ep>=90 and C.green or C.cyan))
  txt(x1+3,y+15,"FUEL",C.grey,C.panel);txt(x1+18,y+15,math.floor(fuel).." / "..math.floor(fm).." mb",C.yellow,C.panel)
  bar(x1+3,y+16,pw-6,fuel/fm*100,C.yellow)
  txt(x1+3,y+18,"TEMP",C.grey,C.panel);txt(x1+18,y+18,math.floor(t).." C",t>=AUTO_STOP_TEMP and C.red or C.orange,C.panel)
  bar(x1+3,y+19,pw-6,math.min(100,t/1000*100),t>=AUTO_STOP_TEMP and C.red or C.orange)
  local bw=math.max(8,math.floor((pw-9)/2))
  button("start",x1+3,y+21,bw,"START",C.green)
  button("stop",x1+6+bw,y+21,bw,"STOP",C.red)
  button("auto",x1+3,y+23,pw-6,"AUTO: "..(auto and"ON"or"OFF"),C.purple,auto)
 end
 panel(x2,y,pw,h,"AUTO // POWER GRID",C.purple)
 local ep,en,em=energyPercent()
 txt(x2+3,y+3,"ENERGY CONTROL",C.white,C.panel)
 txt(x2+3,y+5,"ON THRESHOLD",C.grey,C.panel);txt(x2+24,y+5,"< "..AUTO_ON_ENERGY.." %",C.red,C.panel)
 txt(x2+3,y+7,"OFF THRESHOLD",C.grey,C.panel);txt(x2+24,y+7,">= "..AUTO_OFF_ENERGY.." %",C.green,C.panel)
 txt(x2+3,y+9,"CURRENT",C.grey,C.panel);txt(x2+24,y+9,string.format("%5.1f %%",ep),C.cyan,C.panel)
 bar(x2+3,y+10,pw-6,ep,ep<10 and C.red or(ep>=90 and C.green or C.cyan))
 led(x2+3,y+13,not auto,C.grey,"MANUAL AVAILABLE")
 led(x2+3,y+15,auto and ep<AUTO_ON_ENERGY,C.red,"LOW POWER -> START")
 led(x2+3,y+17,auto and ep>=AUTO_OFF_ENERGY,C.green,"FULL GRID -> STOP")
 led(x2+3,y+19,active() and t~=nil,C.cyan,"SAFETY MONITOR")
 marquee(x2+3,y+21,pw-6,pulse,C.purple)
 txt(x2+3,y+23,fit("AUTO keeps energy between 10% and 90%",pw-6),C.yellow,C.panel)
 footer();txt(3,H-5,fit(message,math.max(1,W-6)),C.yellow,C.bg)
end

local function drawTurbine()
 header("PAGE 2 // TURBINE INFORMATION")
 local y=6;local h=H-12;local w=W-6;panel(3,y,w,h,"TURBINE TELEMETRY // LIVE",C.pink)
 local ta=turbineAddr()
 if not ta then
  txt(7,y+5,"NO br_turbine FOUND",C.red,C.panel)
  txt(7,y+7,"Connect a Big Reactors turbine to view live data.",C.grey,C.panel)
 else
  local on=tread("getActive",false)==true
  local rpm=tonumber(tread("getRotorSpeed",0))or 0
  local out=tonumber(tread("getEnergyProducedLastTick",0))or 0
  local flow=tonumber(tread("getFluidFlowRate",0))or 0
  local ind=tread("getInductorEngaged",false)==true
  local two=math.floor((w-7)/2);local x1=6;local x2=6+two+3
  led(x1,y+3,on,C.green,on and"TURBINE ONLINE"or"TURBINE OFFLINE")
  led(x2,y+3,ind,C.purple,"INDUCTOR")
  txt(x1,y+6,"ROTOR SPEED",C.grey,C.panel);txt(x1+18,y+6,math.floor(rpm).." RPM",C.cyan,C.panel)
  txt(x2,y+6,"ENERGY OUTPUT",C.grey,C.panel);txt(x2+20,y+6,math.floor(out).." RF/t",C.green,C.panel)
  txt(x1,y+8,"FLUID FLOW",C.grey,C.panel);txt(x1+18,y+8,math.floor(flow).." mB/t",C.blue,C.panel)
  txt(x2,y+8,"REACTOR",C.grey,C.panel);txt(x2+20,y+8,selected.." / "..#reactors,C.white,C.panel)
  txt(x1,y+11,"ROTOR LOAD / ACTIVITY",C.grey,C.panel)
  bar(x1,y+12,w-6,math.min(100,rpm/1800*100),C.pink)
  marquee(x1,y+15,w-6,pulse,C.pink)
  txt(x1,y+17,"TURBINE STATUS",C.grey,C.panel);txt(x1+20,y+17,on and"RUNNING"or"STOPPED",on and C.green or C.red,C.panel)
  txt(x1,y+19,"INDUCTOR",C.grey,C.panel);txt(x1+20,y+19,ind and"ENGAGED"or"DISENGAGED",ind and C.purple or C.grey,C.panel)
  txt(x1,y+21,fit("LIVE turbine information / automatic refresh",w-6),C.yellow,C.panel)
 end
 footer();txt(3,H-5,fit(message,math.max(1,W-6)),C.yellow,C.bg)
end

local function drawRods()
 header("CONTROL RODS // MATRIX")
 local y=6;local h=H-12;local w=W-6;panel(3,y,w,h,"CONTROL ROD BANK",C.orange)
 local n=rodCount()
 if n<=0 then txt(7,y+5,"NO CONTROL RODS",C.red,C.panel) else
  local rows=math.max(1,h-5)
  for i=0,math.min(n-1,rows-1) do
   local yy=y+2+i;local lv=rodLevel(i);local on=i==rod
   if on then box(4,yy,w-2,1,C.panel2)end
   txt(6,yy,string.format("%02d",i),on and C.yellow or C.cyan,C.panel)
   txt(11,yy,"ROD "..string.format("%02d",i),C.white,C.panel)
   bar(21,yy,math.max(8,w-34),lv,lv>=80 and C.red or C.yellow)
   txt(math.max(23,W-10),yy,string.format("%3d%%",lv),lv>=80 and C.red or C.yellow,C.panel)
   ui["rod"..i]={x=4,y=yy,w=w-2,h=1}
  end
 end
 local bw=math.max(10,math.floor((w-8)/3))
 button("all0",3,y+h-4,bw,"ALL 0%",C.blue)
 button("all50",5+bw,y+h-4,bw,"ALL 50%",C.purple)
 button("all100",7+bw*2,y+h-4,bw,"ALL 100%",C.red)
 footer();txt(3,H-5,fit(message,math.max(1,W-6)),C.yellow,C.bg)
end

local function draw()
 ui={};clear(C.bg)
 if page=="reactor" then drawReactor() elseif page=="turbine" then drawTurbine() else drawRods() end
end

draw()
while running do
 pulse=pulse+1
 autoControl()
 draw()
 -- OpenComputers touch: screenAddress, x, y, button, playerName
 local e,screenAddress,x,y,buttonCode,player=event.pull(0.5)
 if e=="touch" then
  if hit("reactor",x,y) then page="reactor"
  elseif hit("turbine",x,y) then page="turbine"
  elseif hit("rods",x,y) then page="rods"
  elseif hit("prev",x,y) then nextReactor(-1)
  elseif hit("next",x,y) then nextReactor(1)
  elseif hit("scan",x,y) then discover()
  elseif hit("exit",x,y) then running=false
  elseif hit("start",x,y) then setActive(true)
  elseif hit("stop",x,y) then setActive(false)
  elseif hit("auto",x,y) then auto=not auto;say(auto and"BULDACITY AUTO ENABLED"or"BULDACITY AUTO DISABLED")
  elseif hit("minus10",x,y) then changeRod(-10)
  elseif hit("plus10",x,y) then changeRod(10)
  elseif hit("minus1",x,y) then changeRod(-1)
  elseif hit("plus1",x,y) then changeRod(1)
  elseif hit("all50",x,y) then setAll(50)
  elseif hit("all0",x,y) then setAll(0)
  elseif hit("all100",x,y) then setAll(100)
  else
   for i=0,rodCount()-1 do
    if hit("rod"..i,x,y) then rod=i;say("SELECTED ROD "..i);break end
   end
  end
 elseif e=="key_down" then
  if x==keyboard.keys.q then running=false
  elseif x==keyboard.keys["1"] then page="reactor"
  elseif x==keyboard.keys["2"] then page="turbine"
  elseif x==keyboard.keys.left then nextReactor(-1)
  elseif x==keyboard.keys.right then nextReactor(1)
  elseif x==keyboard.keys.up then changeRod(1)
  elseif x==keyboard.keys.down then changeRod(-1)
  elseif x==keyboard.keys.a then auto=not auto;say(auto and"BULDACITY AUTO ENABLED"or"BULDACITY AUTO DISABLED")
  end
 elseif e=="screen_resized" then resize()
 end
end
clear(C.bg);txt(3,3,"BULDACITY REACTOR HUD OFFLINE",C.cyan,C.bg);txt(3,5,"System stopped.",C.grey,C.bg)