-- ReactorBigReactors043A_Touch_Responsive.lua
-- Minecraft 1.7.10 / Big Reactors 0.4.3A / OpenComputers 1.8.10+667626d
-- Responsive sci-fi touchscreen dashboard. Optional turbine support.

local component=require("component")
local event=require("event")
local keyboard=require("keyboard")
local gpu=component.gpu

local reactors={}
local selected=1
local rod=0
local page="main"
local running=true
local message="SYSTEM READY"
local messageUntil=0
local ui={}

local C={bg=0x05080D,panel=0x0D141D,panel2=0x111D29,line=0x26384A,blue=0x35B9FF,
cyan=0x55F5FF,green=0x39FF88,red=0xFF4F68,yellow=0xFFE36E,orange=0xFF9F43,
white=0xF4FAFF,grey=0x7F95A8,purple=0xB47CFF,off=0x24313C}

local W,H=80,25
local function resize()
  local mw,mh=gpu.maxResolution()
  local cw,ch=gpu.getResolution()
  if mw and mh then W,H=mw,mh else W,H=cw,ch end
  if W<40 then W=40 end
  if H<16 then H=16 end
  pcall(gpu.setResolution,W,H)
  W,H=gpu.getResolution()
end
resize()

gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")

local function invoke(addr,name,...)
  if not addr then return false,nil end
  local ok,a,b,c,d=pcall(component.invoke,addr,name,...)
  return ok,a,b,c,d
end
local function addr() return reactors[selected] end
local function say(s)
  message=tostring(s);messageUntil=os.time()+3
end
local function discover()
  reactors={}
  for a in component.list("br_reactor") do reactors[#reactors+1]=a end
  if selected>#reactors then selected=1 end
  rod=0
  if #reactors==0 then say("NO REACTOR DETECTED") else say(#reactors.." REACTOR UNIT(S) ONLINE") end
end
discover()

local function read(name,default,...)
  local ok,v=invoke(addr(),name,...)
  if ok and v~=nil then return v end
  return default
end
local function active() return read("getActive",false)==true end
local function rodCount() return tonumber(read("getNumberOfControlRods",0)) or 0 end
local function rodLevel(i) return tonumber(read("getControlRodLevel",0,i)) or 0 end
local function turbineAddr()
  for a in component.list("br_turbine") do return a end
  return nil
end
local function tRead(name,default,...)
  local a=turbineAddr();if not a then return default end
  local ok,v=invoke(a,name,...);if ok and v~=nil then return v end
  return default
end
local function setActive(v)
  local ok=invoke(addr(),"setActive",v)
  if ok then say(v and "REACTOR START COMMAND SENT" or "REACTOR STOP COMMAND SENT") else say("ERROR: REACTOR COMMAND FAILED") end
end
local function setOne(i,v)
  local n=rodCount();if n<=0 then say("NO CONTROL RODS") return end
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))
  if i<0 then i=0 end;if i>=n then i=n-1 end
  -- Big Reactors 0.4.3A uses zero-based indices; setter success may return nil.
  local ok=invoke(addr(),"setControlRodLevel",i,v)
  if ok then rod=i;say("ROD "..i.."  /  "..v.."%") else say("ERROR: ROD COMMAND FAILED") end
end
local function setAll(v)
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))
  local ok=invoke(addr(),"setAllControlRodLevels",v)
  if ok then say("ALL RODS  /  "..v.."%") else say("ERROR: ALL-ROD COMMAND FAILED") end
end
local function changeRod(d) setOne(rod,rodLevel(rod)+d) end
local function nextRod(d)
  local n=rodCount();if n<=0 then return end
  rod=(rod+d)%n;say("SELECTED ROD "..rod)
end
local function nextReactor(d)
  if #reactors==0 then return end
  selected=((selected-1+d)%#reactors)+1;rod=0;say("SELECTED REACTOR "..selected)
end

local function txt(x,y,s,fg,bg)
  gpu.setBackground(bg or C.bg);gpu.setForeground(fg or C.white);gpu.set(x,y,tostring(s))
end
local function box(x,y,w,h,c)
  gpu.setBackground(c or C.panel);gpu.fill(x,y,w,h," ")
end
local function fit(s,w)
  s=tostring(s or "");if #s>w then return s:sub(1,math.max(0,w-1)).."…" end;return s
end
local function centered(x,y,w,s,fg,bg)
  s=fit(s,w-2);txt(x+math.max(1,math.floor((w-#s)/2)),y,s,fg,bg)
end
local function panel(x,y,w,h,title,c)
  box(x,y,w,h,C.panel);gpu.setBackground(c or C.blue);gpu.fill(x,y,w,1," ")
  txt(x+2,y,"◆ "..fit(title,w-5),C.white,c or C.blue)
  gpu.setBackground(C.line);gpu.fill(x,y+h-1,w,1," ")
end
local function led(x,y,on,c,label)
  local cc=on and (c or C.green) or C.off
  box(x,y,3,1,cc);txt(x+4,y,label or (on and "ON" or "OFF"),on and cc or C.grey,C.panel)
end
local function bar(x,y,w,value,max,c)
  value=tonumber(value) or 0;max=math.max(tonumber(max) or 1,1)
  local n=math.floor(math.max(0,math.min(max,value))/max*w)
  box(x,y,w,1,C.panel2);if n>0 then box(x,y,n,1,c or C.blue) end
end
local function button(id,x,y,w,h,label,c)
  ui[id]={x=x,y=y,w=w,h=h}
  box(x,y,w,h,c or C.blue);centered(x,y+math.floor(h/2),w,label,C.white,c or C.blue)
end
local function hit(id,x,y)
  local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function header(title)
  box(1,1,W,4,C.panel)
  txt(3,2,"◈ REACTOR // CONTROL",C.cyan,C.panel)
  local tx=math.max(26,math.floor(W*0.30));txt(tx,2,fit(title,math.max(10,W-tx-30)),C.white,C.panel)
  txt(math.max(tx+12,W-28),2,"BR 0.4.3A",C.grey,C.panel)
  gpu.setBackground(C.blue);gpu.fill(1,4,W,1," ")
end
local function footer()
  local y=H-3;box(1,y,W,4,C.panel);local gap=1;local bw=math.max(7,math.floor((W-2-6*gap)/7))
  local x=2
  button("main",x,y,bw,2,"MAIN",C.purple);x=x+bw+gap
  button("info",x,y,bw,2,"INFO",C.blue);x=x+bw+gap
  button("rods",x,y,bw,2,"RODS",C.orange);x=x+bw+gap
  button("prev",x,y,bw,2,"◀ UNIT",C.blue);x=x+bw+gap
  button("next",x,y,bw,2,"UNIT ▶",C.blue);x=x+bw+gap
  button("scan",x,y,bw,2,"SCAN",C.cyan);x=x+bw+gap
  button("exit",x,y,bw,2,"EXIT",C.red)
  txt(3,H,"[Q] EXIT   [←/→] UNIT   [↑/↓] ROD",C.grey,C.panel)
end

local function drawMain()
  header("SYSTEM DASHBOARD")
  local turbine=turbineAddr()~=nil
  local contentY=6;local footY=H-4;local areaH=footY-contentY
  local two=W>=82
  local gap=2;local leftW=two and math.floor((W-6-gap)/2) or W-6;local rightW=leftW
  local x1=3;local x2=x1+leftW+gap
  panel(x1,contentY,leftW,areaH,"REACTOR CORE",C.blue)
  if #reactors==0 then centered(x1,contentY+5,leftW,"NO br_reactor FOUND",C.red,C.panel)
  else
    local en=tonumber(read("getEnergyStored",0)) or 0
    local fuel=tonumber(read("getFuelAmount",0)) or 0
    local fm=tonumber(read("getFuelAmountMax",1)) or 1
    local temp=tonumber(read("getFuelTemperature",0)) or 0
    local cool=read("isActivelyCooled",false)==true
    txt(x1+3,contentY+3,"UNIT",C.grey,C.panel);txt(x1+18,contentY+3,selected.." / "..#reactors,C.white,C.panel)
    led(x1+3,contentY+5,active(),C.green,active() and "ONLINE" or "OFFLINE")
    led(x1+3,contentY+7,cool,C.cyan,"ACTIVE COOLING")
    txt(x1+3,contentY+9,"ENERGY",C.grey,C.panel);txt(x1+18,contentY+9,math.floor(en).." RF",C.cyan,C.panel)
    txt(x1+3,contentY+11,"FUEL",C.grey,C.panel);txt(x1+18,contentY+11,math.floor(fuel).." / "..math.floor(fm).." mb",C.yellow,C.panel)
    bar(x1+3,contentY+12,leftW-6,fuel,fm,C.yellow)
    txt(x1+3,contentY+14,"FUEL TEMP",C.grey,C.panel);txt(x1+18,contentY+14,math.floor(temp).." C",C.orange,C.panel)
    button("start",x1+3,contentY+16,math.max(10,math.floor((leftW-8)/2)),2,"START",C.green)
    button("stop",x1+4+math.max(10,math.floor((leftW-8)/2)),contentY+16,math.max(10,math.floor((leftW-8)/2)),2,"STOP",C.red)
  end
  if two then
    panel(x2,contentY,rightW,areaH,turbine and "POWER + TURBINE" or "POWER + RODS",turbine and C.cyan or C.orange)
    if turbine then
      local te=tonumber(tRead("getEnergyProducedLastTick",0)) or 0
      local speed=tonumber(tRead("getRotorSpeed",0)) or 0
      local flow=tonumber(tRead("getFluidFlowRate",0)) or 0
      led(x2+3,contentY+3,tRead("getActive",false)==true,C.green,"TURBINE")
      txt(x2+3,contentY+6,"ROTOR",C.grey,C.panel);txt(x2+18,contentY+6,math.floor(speed).." RPM",C.cyan,C.panel)
      txt(x2+3,contentY+8,"OUTPUT",C.grey,C.panel);txt(x2+18,contentY+8,math.floor(te).." RF/t",C.green,C.panel)
      txt(x2+3,contentY+10,"FLOW",C.grey,C.panel);txt(x2+18,contentY+10,math.floor(flow).." mB/t",C.blue,C.panel)
      led(x2+3,contentY+12,tRead("getInductorEngaged",false)==true,C.purple,"INDUCTOR")
    else
      local n=rodCount();local lv=n>0 and rodLevel(rod) or 0
      txt(x2+3,contentY+3,"CONTROL RODS",C.grey,C.panel);txt(x2+20,contentY+3,n,C.white,C.panel)
      txt(x2+3,contentY+5,"SELECTED",C.grey,C.panel);txt(x2+20,contentY+5,n>0 and rod or "-",C.cyan,C.panel)
      txt(x2+3,contentY+7,"LEVEL",C.grey,C.panel);txt(x2+20,contentY+7,lv.." %",C.yellow,C.panel)
      bar(x2+3,contentY+8,rightW-6,lv,100,lv>=80 and C.red or C.yellow)
      button("minus10",x2+3,contentY+11,math.max(9,math.floor((rightW-9)/2)),2,"-10",C.blue)
      button("plus10",x2+6+math.max(9,math.floor((rightW-9)/2)),contentY+11,math.max(9,math.floor((rightW-9)/2)),2,"+10",C.orange)
      button("minus1",x2+3,contentY+14,math.max(9,math.floor((rightW-9)/2)),2,"-1",C.blue)
      button("plus1",x2+6+math.max(9,math.floor((rightW-9)/2)),contentY+14,math.max(9,math.floor((rightW-9)/2)),2,"+1",C.orange)
    end
  else
    -- Small screens: use the full width and prioritize reactor + rod status.
    panel(x1,contentY,leftW,areaH,"ROD STATUS",C.orange)
    local n=rodCount();local lv=n>0 and rodLevel(rod) or 0
    txt(x1+3,contentY+3,"RODS",C.grey,C.panel);txt(x1+15,contentY+3,n,C.white,C.panel)
    txt(x1+3,contentY+5,"LEVEL",C.grey,C.panel);txt(x1+15,contentY+5,lv.." %",C.yellow,C.panel)
    bar(x1+3,contentY+6,leftW-6,lv,100,C.yellow)
    button("minus1",x1+3,contentY+8,math.max(8,math.floor((leftW-9)/2)),2,"-1",C.blue)
    button("plus1",x1+6+math.max(8,math.floor((leftW-9)/2)),contentY+8,math.max(8,math.floor((leftW-9)/2)),2,"+1",C.orange)
  end
  footer();txt(3,H-4,fit(message,W-6),C.yellow,C.bg)
end

local function drawInfo()
  header("TELEMETRY / DIAGNOSTICS")
  local y=6;local h=H-9;local gap=2;local two=W>=82;local pw=two and math.floor((W-6-gap)/2) or W-6
  panel(3,y,pw,h,"LIVE TELEMETRY",C.cyan)
  if #reactors==0 then centered(3,y+5,pw,"NO REACTOR",C.red,C.panel) else
    local rows={{"ACTIVE",active() and "TRUE" or "FALSE",active() and C.green or C.red},{"ENERGY",read("getEnergyStored",0).." RF",C.cyan},{"FUEL",read("getFuelAmount",0).." mb",C.yellow},{"WASTE",read("getWasteAmount",0).." mb",C.white},{"CASING",math.floor(read("getCasingTemperature",0)).." C",C.yellow},{"FUEL TEMP",math.floor(read("getFuelTemperature",0)).." C",C.orange},{"RODS",rodCount(),C.orange}}
    for i,r in ipairs(rows) do txt(6,y+2+(i-1)*2,r[1],C.grey,C.panel);txt(22,y+2+(i-1)*2,fit(r[2],pw-24),r[3],C.panel) end
  end
  if two then
    local x=3+pw+gap;panel(x,y,pw,h,"DEVICE STATUS",C.blue)
    led(x+3,y+3,#reactors>0,C.green,"REACTOR LINK")
    led(x+3,y+5,turbineAddr()~=nil,C.cyan,"TURBINE LINK")
    led(x+3,y+7,rodCount()>0,C.orange,"ROD ARRAY")
    txt(x+3,y+10,"SCREEN",C.grey,C.panel);txt(x+18,y+10,W.." x "..H,C.white,C.panel)
    txt(x+3,y+12,"UNIT",C.grey,C.panel);txt(x+18,y+12,#reactors>0 and selected or "-",C.cyan,C.panel)
    txt(x+3,y+14,"MESSAGE",C.grey,C.panel);txt(x+3,y+16,fit(message,pw-6),C.yellow,C.panel)
  end
  footer()
end

local function drawRods()
  header("CONTROL ROD MATRIX")
  local y=6;local h=H-9;panel(3,y,W-6,h,"ROD CONTROL",C.orange)
  local n=rodCount()
  if n<=0 then centered(3,y+5,W-6,"NO CONTROL RODS REPORTED",C.red,C.panel) else
    if rod>=n then rod=n-1 end
    local lv=rodLevel(rod)
    txt(7,y+3,"SELECTED ROD",C.grey,C.panel);txt(25,y+3,rod.." / "..(n-1),C.cyan,C.panel)
    txt(7,y+5,"INSERTION",C.grey,C.panel);txt(25,y+5,lv.." %",C.yellow,C.panel)
    bar(7,y+6,W-14,lv,100,lv>=80 and C.red or C.yellow)
    local bw=math.max(9,math.floor((W-20)/4));local x=7
    button("rminus10",x,y+9,bw,2,"-10",C.blue);x=x+bw+2
    button("rminus1",x,y+9,bw,2,"-1",C.blue);x=x+bw+2
    button("rplus1",x,y+9,bw,2,"+1",C.orange);x=x+bw+2
    button("rplus10",x,y+9,bw,2,"+10",C.orange)
    button("prevrod",7,y+13,bw*2+2,2,"◀ PREV ROD",C.purple)
    button("nextrod",9+bw*2,y+13,bw*2+2,2,"NEXT ROD ▶",C.purple)
    button("all0",7,y+16,bw*2+2,2,"ALL 0%",C.green)
    button("all100",9+bw*2,y+16,bw*2+2,2,"ALL 100%",C.red)
    txt(7,y+19,fit("ZERO-BASED ROD INDEX  /  BIG REACTORS 0.4.3A",W-14),C.grey,C.panel)
  end
  footer();txt(3,H-4,fit(message,W-6),C.yellow,C.bg)
end

local function draw()
  ui={};gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
  if page=="main" then drawMain() elseif page=="info" then drawInfo() else drawRods() end
end

draw()
local function touch(x,y)
  if hit("main",x,y) then page="main"
  elseif hit("info",x,y) then page="info"
  elseif hit("rods",x,y) then page="rods"
  elseif hit("prev",x,y) then nextReactor(-1)
  elseif hit("next",x,y) then nextReactor(1)
  elseif hit("scan",x,y) then discover()
  elseif hit("exit",x,y) then running=false
  elseif hit("start",x,y) then setActive(true)
  elseif hit("stop",x,y) then setActive(false)
  elseif hit("minus10",x,y) or hit("rminus10",x,y) then changeRod(-10)
  elseif hit("plus10",x,y) or hit("rplus10",x,y) then changeRod(10)
  elseif hit("minus1",x,y) or hit("rminus1",x,y) then changeRod(-1)
  elseif hit("plus1",x,y) or hit("rplus1",x,y) then changeRod(1)
  elseif hit("prevrod",x,y) then nextRod(-1)
  elseif hit("nextrod",x,y) then nextRod(1)
  elseif hit("all0",x,y) then setAll(0)
  elseif hit("all100",x,y) then setAll(100) end
end

event.listen("touch",function(_,_,x,y) touch(x,y);draw() end)
while running do
  local e={event.pull(1)}
  if e[1]=="key_down" then
    local ch=e[3];local code=e[4]
    if ch==string.byte("q") or ch==string.byte("Q") then running=false
    elseif code==keyboard.keys.left then nextReactor(-1)
    elseif code==keyboard.keys.right then nextReactor(1)
    elseif code==keyboard.keys.up and page=="rods" then nextRod(-1)
    elseif code==keyboard.keys.down and page=="rods" then nextRod(1)
    elseif ch==string.byte("r") or ch==string.byte("R") then discover() end
  end
  if running then draw() end
end
