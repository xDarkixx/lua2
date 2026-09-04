-- ReactorBigReactors043A_Touch_Responsive.lua
-- Minecraft 1.7.10 / Big Reactors 0.4.3A / OpenComputers 1.8.10+667626d
-- Responsive sci-fi touchscreen dashboard with optional turbine and REAL auto control.

local component=require("component")
local event=require("event")
local keyboard=require("keyboard")
local gpu=component.gpu

local reactors={}; local selected=1; local rod=0; local page="main"; local running=true
local auto=false; local message="SYSTEM READY"; local ui={}
local AUTO_START_TEMP=500; local AUTO_STOP_TEMP=900; local AUTO_MIN_FUEL=1

local C={bg=0x05080D,panel=0x0D141D,panel2=0x111D29,line=0x26384A,blue=0x35B9FF,
cyan=0x55F5FF,green=0x39FF88,red=0xFF4F68,yellow=0xFFE36E,orange=0xFF9F43,
white=0xF4FAFF,grey=0x7F95A8,purple=0xB47CFF,off=0x24313C}
local W,H=80,25
local function resize()
  local mw,mh=gpu.maxResolution(); local cw,ch=gpu.getResolution()
  W,H=mw or cw,mh or ch; if W<40 then W=40 end; if H<16 then H=16 end
  pcall(gpu.setResolution,W,H); W,H=gpu.getResolution()
end
resize()
local function invoke(a,n,...)
  if not a then return false,nil end
  local ok,x,y,z,q=pcall(component.invoke,a,n,...); return ok,x,y,z,q
end
local function addr() return reactors[selected] end
local function say(s) message=tostring(s) end
local function discover()
  reactors={}; for a in component.list("br_reactor") do reactors[#reactors+1]=a end
  if #reactors==0 then selected=1;rod=0;say("NO REACTOR DETECTED") else
    if selected>#reactors then selected=1 end; rod=0;say(#reactors.." REACTOR UNIT(S) DETECTED")
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
  local a=turbineAddr();if not a then return d end;local ok,v=invoke(a,n,...);if ok and v~=nil then return v end;return d
end
local function setActive(v)
  if not addr() then say("NO REACTOR") return end
  local ok=invoke(addr(),"setActive",v);say(ok and (v and "REACTOR ON" or "REACTOR OFF") or "ERROR: REACTOR COMMAND")
end
local function setOne(i,v)
  local n=rodCount();if n<=0 then say("NO CONTROL RODS") return end
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)));i=math.max(0,math.min(n-1,i))
  local ok=invoke(addr(),"setControlRodLevel",i,v)
  if ok then rod=i;say("ROD "..i.." -> "..v.."%") else say("ERROR: ROD COMMAND") end
end
local function setAll(v)
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)));local ok=invoke(addr(),"setAllControlRodLevels",v)
  say(ok and ("ALL RODS -> "..v.."%") or "ERROR: ALL RODS")
end
local function changeRod(d) setOne(rod,rodLevel(rod)+d) end
local function nextRod(d)local n=rodCount();if n>0 then rod=(rod+d)%n;say("SELECTED ROD "..rod)end end
local function nextReactor(d)if #reactors>0 then selected=((selected-1+d)%#reactors)+1;rod=0;say("SELECTED UNIT "..selected)end end

-- Automatic control: start below AUTO_START_TEMP, stop at/above AUTO_STOP_TEMP,
-- and stop if fuel is depleted. Hysteresis prevents rapid on/off switching.
local function autoControl()
  if not auto or not addr() then return end
  local t=tonumber(read("getFuelTemperature",0)) or 0
  local fuel=tonumber(read("getFuelAmount",0)) or 0
  if fuel<=AUTO_MIN_FUEL then if active() then setActive(false) end;return end
  if active() and t>=AUTO_STOP_TEMP then setActive(false)
  elseif (not active()) and t<=AUTO_START_TEMP then setActive(true) end
end

local function txt(x,y,s,fg,bg)gpu.setBackground(bg or C.bg);gpu.setForeground(fg or C.white);gpu.set(x,y,tostring(s))end
local function box(x,y,w,h,c)gpu.setBackground(c or C.panel);gpu.fill(x,y,w,h," ")end
local function fit(s,w)s=tostring(s or "");if #s>w then return s:sub(1,math.max(0,w-1)).."…" end;return s end
local function center(x,y,w,s,fg,bg)s=fit(s,w-2);txt(x+math.max(1,math.floor((w-#s)/2)),y,s,fg,bg)end
local function panel(x,y,w,h,title,c)box(x,y,w,h,C.panel);gpu.setBackground(c or C.blue);gpu.fill(x,y,w,1," ");txt(x+2,y,"◆ "..fit(title,w-5),C.white,c or C.blue);gpu.setBackground(C.line);gpu.fill(x,y+h-1,w,1," ")end
local function led(x,y,on,c,label)local cc=on and(c or C.green)or C.off;box(x,y,3,1,cc);txt(x+4,y,fit(label or(on and"ON"or"OFF"),18),on and cc or C.grey,C.panel)end
local function bar(x,y,w,v,m,c)v=tonumber(v)or 0;m=math.max(tonumber(m)or 1,1);local n=math.floor(math.max(0,math.min(m,v))/m*w);box(x,y,w,1,C.panel2);if n>0 then box(x,y,n,1,c or C.blue)end end
local function button(id,x,y,w,h,label,c,on)ui[id]={x=x,y=y,w=w,h=h};box(x,y,w,h,on and C.green or c);center(x,y+math.floor(h/2),w,label,C.white,on and C.green or c)end
local function hit(id,x,y)local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
local function header(title)
  box(1,1,W,4,C.panel);txt(3,2,"◈ REACTOR // CONTROL",C.cyan,C.panel)
  local tx=math.max(25,math.floor(W*.30));txt(tx,2,fit(title,math.max(8,W-tx-30)),C.white,C.panel)
  txt(math.max(tx+10,W-28),2,"BR 0.4.3A",C.grey,C.panel);gpu.setBackground(C.blue);gpu.fill(1,4,W,1," ")
end
local function footer()
  local y=H-3;box(1,y,W,4,C.panel);local gap=1;local bw=math.max(7,math.floor((W-2-6*gap)/7));local x=2
  button("main",x,y,bw,2,"MAIN",C.purple,page=="main");x=x+bw+gap
  button("info",x,y,bw,2,"INFO",C.blue,page=="info");x=x+bw+gap
  button("rods",x,y,bw,2,"RODS",C.orange,page=="rods");x=x+bw+gap
  button("prev",x,y,bw,2,"◀ UNIT",C.blue);x=x+bw+gap
  button("next",x,y,bw,2,"UNIT ▶",C.blue);x=x+bw+gap
  button("scan",x,y,bw,2,"SCAN",C.cyan);x=x+bw+gap
  button("exit",x,y,bw,2,"EXIT",C.red);txt(3,H,"[Q] EXIT   [←/→] UNIT   [↑/↓] ROD",C.grey,C.panel)
end

local function drawMain()
  header("SYSTEM DASHBOARD");local turbine=turbineAddr()~=nil;local cy=6;local fy=H-4;local ah=fy-cy;local two=W>=82;local gap=2
  local pw=two and math.floor((W-6-gap)/2) or W-6;local x1=3;local x2=x1+pw+gap
  panel(x1,cy,pw,ah,"REACTOR CORE",C.blue)
  if #reactors==0 then center(x1,cy+5,pw,"NO br_reactor FOUND",C.red,C.panel) else
    local en=tonumber(read("getEnergyStored",0))or 0;local fuel=tonumber(read("getFuelAmount",0))or 0;local fm=tonumber(read("getFuelAmountMax",1))or 1;local t=tonumber(read("getFuelTemperature",0))or 0;local cool=read("isActivelyCooled",false)==true
    txt(x1+3,cy+3,"UNIT",C.grey,C.panel);txt(x1+18,cy+3,selected.." / "..#reactors,C.white,C.panel)
    led(x1+3,cy+5,active(),C.green,active() and"ONLINE"or"OFFLINE");led(x1+3,cy+7,cool,C.cyan,"ACTIVE COOLING");led(x1+3,cy+9,auto,C.purple,auto and"AUTO CONTROL"or"MANUAL")
    txt(x1+3,cy+11,"ENERGY",C.grey,C.panel);txt(x1+18,cy+11,math.floor(en).." RF",C.cyan,C.panel)
    txt(x1+3,cy+13,"FUEL",C.grey,C.panel);txt(x1+18,cy+13,math.floor(fuel).." / "..math.floor(fm).." mb",C.yellow,C.panel);bar(x1+3,cy+14,pw-6,fuel,fm,C.yellow)
    txt(x1+3,cy+16,"FUEL TEMP",C.grey,C.panel);txt(x1+18,cy+16,math.floor(t).." C",t>=AUTO_STOP_TEMP and C.red or C.orange,C.panel)
    local bw=math.max(10,math.floor((pw-9)/2));button("start",x1+3,cy+18,bw,2,"START",C.green);button("stop",x1+6+bw,cy+18,bw,2,"STOP",C.red);button("auto",x1+3,cy+21,pw-6,2,auto and"AUTO CONTROL: ON"or"AUTO CONTROL: OFF",C.purple,auto)
  end
  if two then
    panel(x2,cy,pw,ah,turbine and"POWER + TURBINE"or"POWER + RODS",turbine and C.cyan or C.orange)
    if turbine then
      led(x2+3,cy+3,tread("getActive",false)==true,C.green,"TURBINE ONLINE");txt(x2+3,cy+6,"ROTOR",C.grey,C.panel);txt(x2+18,cy+6,math.floor(tread("getRotorSpeed",0)).." RPM",C.cyan,C.panel);txt(x2+3,cy+8,"OUTPUT",C.grey,C.panel);txt(x2+18,cy+8,math.floor(tread("getEnergyProducedLastTick",0)).." RF/t",C.green,C.panel);txt(x2+3,cy+10,"FLOW",C.grey,C.panel);txt(x2+18,cy+10,math.floor(tread("getFluidFlowRate",0)).." mB/t",C.blue,C.panel);led(x2+3,cy+12,tread("getInductorEngaged",false)==true,C.purple,"INDUCTOR")
    else
      local n=rodCount();local lv=n>0 and rodLevel(rod)or 0;txt(x2+3,cy+3,"CONTROL RODS",C.grey,C.panel);txt(x2+20,cy+3,n,C.white,C.panel);txt(x2+3,cy+5,"SELECTED",C.grey,C.panel);txt(x2+20,cy+5,n>0 and rod or"-",C.cyan,C.panel);txt(x2+3,cy+7,"LEVEL",C.grey,C.panel);txt(x2+20,cy+7,lv.." %",C.yellow,C.panel);bar(x2+3,cy+8,pw-6,lv,100,lv>=80 and C.red or C.yellow)
      local bw2=math.max(9,math.floor((pw-9)/2));button("minus10",x2+3,cy+11,bw2,2,"-10",C.blue);button("plus10",x2+6+bw2,cy+11,bw2,2,"+10",C.orange);button("minus1",x2+3,cy+14,bw2,2,"-1",C.blue);button("plus1",x2+6+bw2,cy+14,bw2,2,"+1",C.orange)
    end
  else
    panel(x1,cy,pw,ah,"ROD STATUS",C.orange);local n=rodCount();local lv=n>0 and rodLevel(rod)or 0;txt(x1+3,cy+3,"RODS",C.grey,C.panel);txt(x1+15,cy+3,n,C.white,C.panel);txt(x1+3,cy+5,"LEVEL",C.grey,C.panel);txt(x1+15,cy+5,lv.." %",C.yellow,C.panel);bar(x1+3,cy+6,pw-6,lv,100,C.yellow)
    local bw2=math.max(8,math.floor((pw-9)/2));button("minus1",x1+3,cy+8,bw2,2,"-1",C.blue);button("plus1",x1+6+bw2,cy+8,bw2,2,"+1",C.orange)
  end
  footer();txt(3,H-4,fit(message,W-6),C.yellow,C.bg)
end

local function drawInfo()
  header("LIVE TELEMETRY");local y=6;local h=H-9;local gap=2;local two=W>=82;local pw=two and math.floor((W-6-gap)/2)or W-6
  panel(3,y,pw,h,"REACTOR DATA",C.cyan)
  if #reactors==0 then center(3,y+5,pw,"NO REACTOR",C.red,C.panel) else
    local rows={{"ACTIVE",active()and"TRUE"or"FALSE",active()and C.green or C.red},{"AUTO",auto and"ENABLED"or"DISABLED",auto and C.purple or C.grey},{"ENERGY",read("getEnergyStored",0).." RF",C.cyan},{"FUEL",read("getFuelAmount",0).." mb",C.yellow},{"WASTE",read("getWasteAmount",0).." mb",C.white},{"CASING",math.floor(read("getCasingTemperature",0)).." C",C.yellow},{"FUEL TEMP",math.floor(read("getFuelTemperature",0)).." C",C.orange},{"RODS",rodCount(),C.orange}}
    for i,r in ipairs(rows)do txt(6,y+2+(i-1)*2,r[1],C.grey,C.panel);txt(22,y+2+(i-1)*2,fit(r[2],pw-24),r[3],C.panel)end
  end
  if two then local x=3+pw+gap;panel(x,y,pw,h,"DEVICES / AUTO",C.blue);led(x+3,y+3,#reactors>0,C.green,"REACTOR LINK");led(x+3,y+5,turbineAddr()~=nil,C.cyan,"TURBINE LINK");led(x+3,y+7,auto,C.purple,auto and"AUTO ACTIVE"or"AUTO OFF");txt(x+3,y+10,"AUTO START",C.grey,C.panel);txt(x+22,y+10,AUTO_START_TEMP.." C",C.green,C.panel);txt(x+3,y+12,"AUTO STOP",C.grey,C.panel);txt(x+22,y+12,AUTO_STOP_TEMP.." C",C.red,C.panel);txt(x+3,y+14,"FUEL MIN",C.grey,C.panel);txt(x+22,y+14,AUTO_MIN_FUEL.." mb",C.yellow,C.panel);button("auto2",x+3,y+17,pw-6,2,auto and"AUTO: ON"or"AUTO: OFF",C.purple,auto);button("scan2",x+3,y+20,pw-6,2,"RESCAN DEVICES",C.cyan)end
  footer();txt(3,H-4,fit(message,W-6),C.yellow,C.bg)
end

local function drawRods()
  header("CONTROL RODS");local n=rodCount();local y=6;local h=H-9
  if #reactors==0 then center(1,16,W,"NO br_reactor FOUND",C.red,C.bg);footer();return end
  if n<=0 then center(1,16,W,"NO CONTROL RODS",C.red,C.bg);footer();return end
  local w=W-6;local lv=rodLevel(rod);panel(3,y,w,h,"ROD "..rod.." / "..(n-1),C.orange);txt(8,y+3,"LEVEL",C.grey,C.panel);txt(25,y+3,lv.." %",C.yellow,C.panel);bar(8,y+5,w-10,lv,100,lv>=80 and C.red or C.yellow)
  local bw=math.max(8,math.floor((w-13)/4));local x=8;button("rminus10",x,y+8,bw,2,"-10",C.blue);x=x+bw+2;button("rminus1",x,y+8,bw,2,"-1",C.blue);x=x+bw+2;button("rplus1",x,y+8,bw,2,"+1",C.orange);x=x+bw+2;button("rplus10",x,y+8,bw,2,"+10",C.orange)
  x=8;button("rprev",x,y+12,bw*2+2,2,"PREV ROD",C.purple);x=x+bw*2+4;button("rnext",x,y+12,bw*2+2,2,"NEXT ROD",C.purple);button("all0",8,y+16,math.floor((w-12)/2),2,"ALL 0%",C.green);button("all100",11+math.floor((w-12)/2),y+16,math.floor((w-12)/2),2,"ALL 100%",C.red)
  footer();txt(8,H-4,fit(message,W-16),C.yellow,C.bg)
end

local function draw()ui={};gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ");if page=="main"then drawMain()elseif page=="info"then drawInfo()else drawRods()end end
local function touch(x,y)
  if hit("main",x,y)then page="main";return end;if hit("info",x,y)then page="info";return end;if hit("rods",x,y)then page="rods";return end
  if hit("prev",x,y)then nextReactor(-1);return end;if hit("next",x,y)then nextReactor(1);return end;if hit("scan",x,y)or hit("scan2",x,y)then discover();return end;if hit("exit",x,y)then running=false;return end
  if hit("start",x,y)then setActive(true);return end;if hit("stop",x,y)then setActive(false);return end;if hit("auto",x,y)or hit("auto2",x,y)then auto=not auto;say(auto and"AUTO CONTROL ENABLED"or"AUTO CONTROL DISABLED");return end
  if hit("minus10",x,y)or hit("rminus10",x,y)then changeRod(-10);return end;if hit("plus10",x,y)or hit("rplus10",x,y)then changeRod(10);return end;if hit("minus1",x,y)or hit("rminus1",x,y)then changeRod(-1);return end;if hit("plus1",x,y)or hit("rplus1",x,y)then changeRod(1);return end
  if hit("rprev",x,y)then nextRod(-1);return end;if hit("rnext",x,y)then nextRod(1);return end;if hit("all0",x,y)then setAll(0);return end;if hit("all100",x,y)then setAll(100);return end
end
local function keyDown(ch,code)
  if ch==string.byte("q")or ch==string.byte("Q")then running=false
  elseif code==keyboard.keys.left then nextReactor(-1)
  elseif code==keyboard.keys.right then nextReactor(1)
  elseif page=="rods"and code==keyboard.keys.up then nextRod(-1)
  elseif page=="rods"and code==keyboard.keys.down then nextRod(1)
  elseif ch==string.byte("a")or ch==string.byte("A")then auto=not auto;say(auto and"AUTO CONTROL ENABLED"or"AUTO CONTROL DISABLED") end
end
event.listen("touch",function(_,screen,x,y)touch(x,y)end)
event.listen("key_down",function(_,_,ch,code)keyDown(ch,code)end)
while running do autoControl();draw();event.pull(1)end
event.ignore("touch");event.ignore("key_down");gpu.setBackground(0x000000);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
