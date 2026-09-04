-- ReactorBigReactors043A_Touch_Responsive.lua
-- Buldacity Reactor HUD / Minecraft 1.7.10 / Big Reactors 0.4.3A / OpenComputers
-- Adaptive neon touchscreen dashboard with live telemetry, real auto control,
-- reactor selection, control rods and optional turbine telemetry.

local component=require("component")
local event=require("event")
local keyboard=require("keyboard")
local computer=require("computer")
local gpu=component.gpu

local reactors={}; local selected=1; local rod=0; local page="main"; local running=true
local auto=false; local message="BULDACITY REACTOR SYSTEM READY"; local ui={}; local pulse=0
local AUTO_START_TEMP=500; local AUTO_STOP_TEMP=900; local AUTO_MIN_FUEL=1

local C={bg=0x03060B,panel=0x0A111B,panel2=0x101C29,line=0x214057,cyan=0x35E8FF,
blue=0x438CFF,green=0x35FF9A,red=0xFF466D,yellow=0xFFE36A,purple=0xC56BFF,
pink=0xFF4CCB,orange=0xFF9D45,white=0xF3FAFF,grey=0x7D96AA,off=0x263541}
local W,H=80,25

local function safe(fn,...)
 local ok,a,b,c,d=pcall(fn,...); if ok then return a,b,c,d end
end
local function invoke(a,n,...)
 if not a then return false,nil end
 local ok,x,y,z,q=pcall(component.invoke,a,n,...); return ok,x,y,z,q
end
local function resize()
 local mw,mh=safe(gpu.maxResolution); local cw,ch=safe(gpu.getResolution)
 mw,mh=mw or cw or 80,mh or ch or 25
 safe(gpu.setResolution,mw,mh); W,H=safe(gpu.getResolution); W,H=W or mw,H or mh
end
resize()
local function addr() return reactors[selected] end
local function say(s) message=tostring(s) end
local function discover()
 reactors={}; for a in component.list("br_reactor") do reactors[#reactors+1]=a end
 if #reactors==0 then selected=1;rod=0;say("NO br_reactor DETECTED") else
  if selected>#reactors then selected=1 end;rod=0;say(#reactors.." REACTOR UNIT(S) DETECTED")
 end
end
discover()
local function read(n,d,...)
 local ok,v=invoke(addr(),n,...); if ok and v~=nil then return v end; return d
end
local function active() return read("getActive",false)==true end
local function rodCount() return tonumber(read("getNumberOfControlRods",0)) or 0 end
local function rodLevel(i) return tonumber(read("getControlRodLevel",0,i)) or 0 end
local function turbineAddr() for a in component.list("br_turbine") do return a end end
local function tread(n,d,...)
 local a=turbineAddr(); if not a then return d end
 local ok,v=invoke(a,n,...); if ok and v~=nil then return v end; return d
end
local function setActive(v)
 if not addr() then say("NO REACTOR") return end
 local ok=invoke(addr(),"setActive",v); say(ok and (v and "BULDACITY: REACTOR ONLINE" or "BULDACITY: REACTOR OFFLINE") or "ERROR: REACTOR COMMAND")
end
local function setOne(i,v)
 local n=rodCount(); if n<=0 then say("NO CONTROL RODS") return end
 v=math.max(0,math.min(100,math.floor(tonumber(v) or 0))); i=math.max(0,math.min(n-1,i))
 local ok=invoke(addr(),"setControlRodLevel",i,v)
 if ok then rod=i;say("CONTROL ROD "..i.." -> "..v.."%") else say("ERROR: ROD COMMAND") end
end
local function setAll(v)
 v=math.max(0,math.min(100,math.floor(tonumber(v) or 0))); local ok=invoke(addr(),"setAllControlRodLevels",v)
 say(ok and ("ALL CONTROL RODS -> "..v.."%") or "ERROR: ALL RODS")
end
local function changeRod(d) setOne(rod,rodLevel(rod)+d) end
local function nextRod(d) local n=rodCount(); if n>0 then rod=(rod+d)%n;say("SELECTED ROD "..rod) end end
local function nextReactor(d) if #reactors>0 then selected=((selected-1+d)%#reactors)+1;rod=0;say("SELECTED UNIT "..selected) end end
local function autoControl()
 if not auto or not addr() then return end
 local t=tonumber(read("getFuelTemperature",0)) or 0; local fuel=tonumber(read("getFuelAmount",0)) or 0
 if fuel<=AUTO_MIN_FUEL then if active() then setActive(false) end; return end
 if active() and t>=AUTO_STOP_TEMP then setActive(false)
 elseif (not active()) and t<=AUTO_START_TEMP then setActive(true) end
end

local function clear(bg) gpu.setBackground(bg or C.bg);gpu.fill(1,1,W,H," ") end
local function txt(x,y,s,fg,bg)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s))
end
local function fit(s,n) s=tostring(s or "");n=math.max(1,n or 1);if #s<=n then return s end;if n==1 then return s:sub(1,1) end;return s:sub(1,n-1).."…" end
local function box(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c or C.panel);gpu.fill(x,y,w,h," ") end end
local function line(x,y,w,c) if w>0 and y>=1 and y<=H then gpu.setBackground(c or C.line);gpu.fill(x,y,math.min(w,W-x+1),1," ") end end
local function panel(x,y,w,h,title,c)
 box(x,y,w,h,C.panel);line(x,y,w,c or C.cyan);txt(x+2,y,"◆ "..fit(title,w-5),c or C.cyan,C.panel);if h>=3 then line(x,y+h-1,w,C.line) end
end
local function led(x,y,on,c,label)
 local cc=on and(c or C.green)or C.off;box(x,y,2,1,cc);txt(x+3,y,fit(label or(on and"ONLINE"or"OFFLINE"),math.max(1,W-x-3)),on and cc or C.grey,C.panel)
end
local function bar(x,y,w,p,c)
 w=math.max(1,w);p=math.max(0,math.min(100,tonumber(p)or 0));box(x,y,w,1,C.panel2);local n=math.floor(w*p/100);if n>0 then box(x,y,n,1,c or C.cyan)end
end
local function marquee(x,y,w,phase,c)
 w=math.max(3,w);box(x,y,w,1,C.panel2);local pos=(phase%(w+7))-7;if pos<0 then pos=0 end;local n=math.min(8,w);if pos+n>w then n=w-pos end;if n>0 then box(x+pos,y,n,1,c or C.cyan)end
end
local function button(id,x,y,w,label,c,activeState)
 w=math.max(4,w);ui[id]={x=x,y=y,w=w,h=2};box(x,y,w,2,activeState and C.white or c);txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),activeState and c or C.white,activeState and C.white or c)
end
local function hit(id,x,y) local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
local function header(title)
 box(1,1,W,4,C.panel);txt(3,1,"╔ BULDACITY // REACTOR CORE ╗",C.cyan,C.panel);txt(3,2,fit(title,math.max(10,W-32)),C.white,C.panel)
 local state=active();led(math.max(5,W-27),2,state,state and C.green or C.red,state and"ONLINE"or"OFFLINE");line(1,4,W,C.cyan)
end
local function footer()
 local y=math.max(1,H-3);local n=7;local gap=1;local bw=math.max(4,math.floor((W-4-(n-1)*gap)/n));local x=2
 button("main",x,y,bw,"MAIN",C.purple,page=="main");x=x+bw+gap
 button("info",x,y,bw,"INFO",C.cyan,page=="info");x=x+bw+gap
 button("rods",x,y,bw,"RODS",C.orange,page=="rods");x=x+bw+gap
 button("prev",x,y,bw,"◀ UNIT",C.blue);x=x+bw+gap
 button("next",x,y,bw,"UNIT ▶",C.blue);x=x+bw+gap
 button("scan",x,y,bw,"SCAN",C.yellow);x=x+bw+gap
 button("exit",x,y,bw,"EXIT",C.red);txt(2,H,fit("[Q] EXIT  [←/→] UNIT  [↑/↓] ROD  [A] AUTO",math.max(1,W-4)),C.grey,C.bg)
end
local function drawMain()
 header("LIVE SYSTEM DASHBOARD");local cy=6;local bottom=H-5;local ph=math.max(4,bottom-cy+1);local two=W>=82;local gap=2;local pw=two and math.floor((W-6-gap)/2)or W-6;local x1=3;local x2=x1+pw+gap
 panel(x1,cy,pw,ph,"REACTOR CORE // LIVE",C.cyan)
 if #reactors==0 then txt(x1+4,cy+5,"NO br_reactor FOUND",C.red,C.panel) else
  local en=tonumber(read("getEnergyStored",0))or 0;local fuel=tonumber(read("getFuelAmount",0))or 0;local fm=tonumber(read("getFuelAmountMax",1))or 1;local t=tonumber(read("getFuelTemperature",0))or 0;local cool=read("isActivelyCooled",false)==true
  txt(x1+3,cy+3,"UNIT",C.grey,C.panel);txt(x1+18,cy+3,selected.." / "..#reactors,C.white,C.panel)
  led(x1+3,cy+5,active(),C.green,active()and"ONLINE"or"OFFLINE");led(x1+3,cy+7,cool,C.cyan,"ACTIVE COOLING");led(x1+3,cy+9,auto,C.purple,auto and"AUTO CONTROL"or"MANUAL")
  txt(x1+3,cy+11,"ENERGY",C.grey,C.panel);txt(x1+18,cy+11,math.floor(en).." RF",C.cyan,C.panel)
  txt(x1+3,cy+13,"FUEL",C.grey,C.panel);txt(x1+18,cy+13,math.floor(fuel).." / "..math.floor(fm).." mb",C.yellow,C.panel);bar(x1+3,cy+14,pw-6,fuel/fm*100,C.yellow)
  txt(x1+3,cy+16,"FUEL TEMP",C.grey,C.panel);txt(x1+18,cy+16,math.floor(t).." C",t>=AUTO_STOP_TEMP and C.red or C.orange,C.panel);bar(x1+3,cy+17,pw-6,math.min(100,t/1000*100),t>=AUTO_STOP_TEMP and C.red or C.orange)
  local bw=math.max(8,math.floor((pw-9)/2));button("start",x1+3,cy+19,bw,"START",C.green);button("stop",x1+6+bw,cy+19,bw,"STOP",C.red);button("auto",x1+3,cy+21,pw-6,"AUTO: "..(auto and"ON"or"OFF"),C.purple,auto)
 end
 if two then
  local turbine=turbineAddr()~=nil;panel(x2,cy,pw,ph,turbine and"POWER + TURBINE"or"CONTROL RODS",turbine and C.pink or C.orange)
  if turbine then
   led(x2+3,cy+3,tread("getActive",false)==true,C.green,"TURBINE ONLINE");txt(x2+3,cy+6,"ROTOR",C.grey,C.panel);txt(x2+18,cy+6,math.floor(tread("getRotorSpeed",0)).." RPM",C.cyan,C.panel);txt(x2+3,cy+8,"OUTPUT",C.grey,C.panel);txt(x2+18,cy+8,math.floor(tread("getEnergyProducedLastTick",0)).." RF/t",C.green,C.panel);txt(x2+3,cy+10,"FLOW",C.grey,C.panel);txt(x2+18,cy+10,math.floor(tread("getFluidFlowRate",0)).." mB/t",C.blue,C.panel);led(x2+3,cy+12,tread("getInductorEngaged",false)==true,C.purple,"INDUCTOR");marquee(x2+3,cy+15,pw-6,pulse,C.pink)
  else
   local n=rodCount();local lv=n>0 and rodLevel(rod)or 0;txt(x2+3,cy+3,"CONTROL RODS",C.grey,C.panel);txt(x2+20,cy+3,n,C.white,C.panel);txt(x2+3,cy+5,"SELECTED",C.grey,C.panel);txt(x2+20,cy+5,n>0 and rod or"-",C.cyan,C.panel);txt(x2+3,cy+7,"LEVEL",C.grey,C.panel);txt(x2+20,cy+7,lv.." %",C.yellow,C.panel);bar(x2+3,cy+8,pw-6,lv,lv>=80 and C.red or C.yellow)
   local bw2=math.max(7,math.floor((pw-9)/2));button("minus10",x2+3,cy+11,bw2,"-10",C.blue);button("plus10",x2+6+bw2,cy+11,bw2,"+10",C.orange);button("minus1",x2+3,cy+14,bw2,"-1",C.blue);button("plus1",x2+6+bw2,cy+14,bw2,"+1",C.orange);button("all50",x2+3,cy+17,pw-6,"ALL RODS -> 50%",C.purple)
  end
 else
  panel(x1,cy,pw,ph,"ROD CONTROL",C.orange);local n=rodCount();local lv=n>0 and rodLevel(rod)or 0;txt(x1+3,cy+3,"RODS",C.grey,C.panel);txt(x1+15,cy+3,n,C.white,C.panel);txt(x1+3,cy+5,"SELECTED",C.grey,C.panel);txt(x1+15,cy+5,n>0 and rod or"-",C.cyan,C.panel);txt(x1+3,cy+7,"LEVEL",C.grey,C.panel);txt(x1+15,cy+7,lv.." %",C.yellow,C.panel);bar(x1+3,cy+8,pw-6,lv,C.yellow)
 end
 footer();txt(3,H-4,fit(message,math.max(1,W-6)),C.yellow,C.bg)
end
local function drawInfo()
 header("TELEMETRY // DIAGNOSTICS");local y=6;local h=H-10;local two=W>=82;local gap=2;local pw=two and math.floor((W-6-gap)/2)or W-6
 panel(3,y,pw,h,"REACTOR TELEMETRY",C.cyan)
 if #reactors==0 then txt(7,y+4,"NO REACTOR DATA",C.red,C.panel) else
  local rows={{"ACTIVE",active()and"TRUE"or"FALSE",active()and C.green or C.red},{"AUTO",auto and"ENABLED"or"DISABLED",auto and C.purple or C.grey},{"ENERGY",read("getEnergyStored",0).." RF",C.cyan},{"FUEL",read("getFuelAmount",0).." mb",C.yellow},{"WASTE",read("getWasteAmount",0).." mb",C.white},{"CASING",math.floor(read("getCasingTemperature",0)).." C",C.orange},{"FUEL TEMP",math.floor(read("getFuelTemperature",0)).." C",C.orange},{"RODS",rodCount(),C.pink}}
  for i,r in ipairs(rows)do local yy=y+2+(i-1)*2;txt(6,yy,r[1],C.grey,C.panel);txt(22,yy,fit(r[2],pw-24),r[3],C.panel)end
 end
 if two then local x=3+pw+gap;panel(x,y,pw,h,"AUTO / HARDWARE",C.purple);led(x+3,y+3,#reactors>0,C.green,"REACTOR LINK");led(x+3,y+5,turbineAddr()~=nil,C.cyan,"TURBINE LINK");led(x+3,y+7,auto,C.purple,auto and"AUTO ACTIVE"or"AUTO OFF");txt(x+3,y+10,"START TEMP",C.grey,C.panel);txt(x+23,y+10,AUTO_START_TEMP.." C",C.green,C.panel);txt(x+3,y+12,"STOP TEMP",C.grey,C.panel);txt(x+23,y+12,AUTO_STOP_TEMP.." C",C.red,C.panel);txt(x+3,y+14,"MIN FUEL",C.grey,C.panel);txt(x+23,y+14,AUTO_MIN_FUEL.." mb",C.yellow,C.panel);marquee(x+3,y+17,pw-6,pulse,C.purple)end
 footer();txt(3,H-4,fit(message,math.max(1,W-6)),C.yellow,C.bg)
end
local function drawRods()
 header("CONTROL RODS // MATRIX");local y=6;local h=H-10;local w=W-6;panel(3,y,w,h,"CONTROL ROD BANK",C.orange);local n=rodCount();if n<=0 then txt(7,y+4,"NO CONTROL RODS",C.red,C.panel) else
 local rows=math.max(1,h-4);for i=0,math.min(n-1,rows-1)do local yy=y+2+i;local lv=rodLevel(i);local on=i==rod;if on then box(4,yy,w-2,1,C.panel2)end;txt(6,yy,string.format("%02d",i),on and C.yellow or C.cyan,C.panel);txt(11,yy,string.format("ROD %02d",i),C.white,C.panel);bar(21,yy,math.max(8,w-34),lv,lv>=80 and C.red or C.yellow);txt(math.max(23, W-10),yy,string.format("%3d%%",lv),lv>=80 and C.red or C.yellow,C.panel);ui["rod"..i]={x=4,y=yy,w=w-2,h=1}end
 end
 button("all0",3,y+h-4,math.max(8,math.floor((w-8)/3)),"ALL 0%",C.blue);button("all50",5+math.floor((w-8)/3),y+h-4,math.max(8,math.floor((w-8)/3)),"ALL 50%",C.purple);button("all100",7+2*math.floor((w-8)/3),y+h-4,math.max(8,math.floor((w-8)/3)),"ALL 100%",C.red);footer();txt(3,H-4,fit(message,math.max(1,W-6)),C.yellow,C.bg)
end
local function draw()
 ui={};clear(C.bg);if page=="main"then drawMain()elseif page=="info"then drawInfo()elseif page=="rods"then drawRods()end
end

draw()
while running do
 pulse=pulse+1;autoControl();draw()
 local e,a,b,c=event.pull(0.5)
 if e=="touch" then
  local x,y=a,b
  if hit("main",x,y)then page="main"elseif hit("info",x,y)then page="info"elseif hit("rods",x,y)then page="rods"elseif hit("prev",x,y)then nextReactor(-1)elseif hit("next",x,y)then nextReactor(1)elseif hit("scan",x,y)then discover()
  elseif hit("exit",x,y)then running=false
  elseif hit("start",x,y)then setActive(true)
  elseif hit("stop",x,y)then setActive(false)
  elseif hit("auto",x,y)then auto=not auto;say(auto and"BULDACITY AUTO CONTROL ENABLED"or"BULDACITY AUTO CONTROL DISABLED")
  elseif hit("minus10",x,y)then changeRod(-10)elseif hit("plus10",x,y)then changeRod(10)elseif hit("minus1",x,y)then changeRod(-1)elseif hit("plus1",x,y)then changeRod(1)elseif hit("all50",x,y)then setAll(50)
  elseif hit("all0",x,y)then setAll(0)elseif hit("all100",x,y)then setAll(100)
  else for i=0,rodCount()-1 do if hit("rod"..i,x,y)then rod=i;say("SELECTED ROD "..i);break end end end
 elseif e=="key_down" then
  if a==keyboard.keys.q then running=false elseif a==keyboard.keys.left then nextReactor(-1)elseif a==keyboard.keys.right then nextReactor(1)elseif a==keyboard.keys.up then changeRod(1)elseif a==keyboard.keys.down then changeRod(-1)elseif a==keyboard.keys.a then auto=not auto;say(auto and"AUTO CONTROL ENABLED"or"AUTO CONTROL DISABLED") end
 elseif e=="screen_resized" then resize()
 end
end
clear(C.bg);txt(3,3,"BULDACITY REACTOR HUD OFFLINE",C.cyan,C.bg);txt(3,5,"System stopped.",C.grey,C.bg)
