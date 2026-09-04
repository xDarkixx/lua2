-- ReactorBigReactors043A_Touch_v2.lua
-- Minecraft 1.7.10 / Big Reactors 0.4.3A / OpenComputers 1.8.10+667626d
-- Legacy API-compatible touchscreen controller.

local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local gpu = component.gpu

local W,H = 132,38
local reactors = {}
local selected = 1
local rod = 0
local page = "main"
local auto = false
local running = true
local dirty = true

local C={bg=0x000000,panel=0x151515,panel2=0x252525,blue=0x4286F4,purple=0xB673D6,
red=0xC14141,green=0x00DA41,yellow=0xFFDB4D,white=0xFFFFFF,grey=0x47494C,
cyan=0x66D9FF,orange=0xFF9900}

gpu.setResolution(W,H)

gpu.setBackground(C.bg)
gpu.setForeground(C.white)
gpu.fill(1,1,W,H," ")

local function inv(addr,name,...)
  if not addr then return nil end
  local ok,a,b,c,d=pcall(component.invoke,addr,name,...)
  if ok then return a,b,c,d end
  return nil
end

local function has(addr,name)
  if not addr then return false end
  return pcall(component.invoke,addr,name)
end

local function txt(x,y,s,fg,bg)
  gpu.setBackground(bg or C.bg)
  gpu.setForeground(fg or C.white)
  gpu.set(x,y,tostring(s))
end

local function fill(x,y,w,h,c)
  gpu.setBackground(c)
  gpu.fill(x,y,w,h," ")
end

local function bar(x,y,w,value,max,c)
  value=tonumber(value) or 0
  max=math.max(tonumber(max) or 1,1)
  if value<0 then value=0 end
  if value>max then value=max end
  local n=math.floor(value/max*w)
  fill(x,y,w,1,C.panel2)
  if n>0 then fill(x,y,n,1,c or C.blue) end
end

local function button(x,y,w,label,c,active)
  local bg=active and C.green or c
  fill(x,y,w,3,bg)
  local s=tostring(label)
  if #s>w-2 then s=s:sub(1,w-2) end
  txt(x+math.max(1,math.floor((w-#s)/2)),y+1,s,C.white,bg)
end

local function panel(x,y,w,h,title,c)
  fill(x,y,w,h,C.panel)
  fill(x,y,w,1,c or C.blue)
  txt(x+2,y,"[ "..title.." ]",C.white,c or C.blue)
  fill(x,y+h-1,w,1,C.grey)
end

local function discover()
  reactors={}
  for addr in component.list("br_reactor") do
    if addr then reactors[#reactors+1]=addr end
  end
  if #reactors==0 then selected=1; rod=0; dirty=true; return end
  if selected>#reactors then selected=#reactors end
  local count=tonumber(inv(reactors[selected],"getNumberOfControlRods")) or 0
  if count<=0 then rod=0 elseif rod>=count then rod=count-1 end
  dirty=true
end

discover()

local function addr() return reactors[selected] end

local function active() return inv(addr(),"getActive")==true end
local function cooled() return inv(addr(),"isActivelyCooled")==true end
local function rods() return tonumber(inv(addr(),"getNumberOfControlRods")) or 0 end
local function rodLevel(i) return tonumber(inv(addr(),"getControlRodLevel",i)) or 0 end

local function setActive(state)
  return inv(addr(),"setActive",state)
end

local function setAll(level)
  level=math.floor(tonumber(level) or 0)
  if level<0 then level=0 end
  if level>100 then level=100 end
  return inv(addr(),"setAllControlRodLevels",level)
end

local function setOne(i,level)
  level=math.floor(tonumber(level) or 0)
  if level<0 then level=0 end
  if level>100 then level=100 end
  -- Big Reactors 0.4.3A supports the per-rod Computer Port call.
  local result=inv(addr(),"setControlRodLevel",i,level)
  if result==nil then return setAll(level) end
  return result
end

local function nextReactor(d)
  if #reactors==0 then return end
  selected=selected+d
  if selected<1 then selected=#reactors end
  if selected>#reactors then selected=1 end
  rod=0
  dirty=true
end

local function fmt(v)
  v=math.floor(tonumber(v) or 0)
  if math.abs(v)>=1000000000 then return string.format("%.2fG",v/1000000000) end
  if math.abs(v)>=1000000 then return string.format("%.2fM",v/1000000) end
  if math.abs(v)>=1000 then return string.format("%.1fk",v/1000) end
  return tostring(v)
end

local function header(title)
  fill(1,1,W,4,C.panel)
  txt(3,2,"MJRLEGENDS REACTOR",C.blue,C.panel)
  txt(25,2,title,C.white,C.panel)
  txt(88,2,"BR 0.4.3A",C.cyan,C.panel)
  txt(106,2,#reactors>0 and ("UNIT "..selected.."/"..#reactors) or "NO REACTOR",C.yellow,C.panel)
  fill(1,4,W,1,C.blue)
end

local function footer()
  fill(1,35,W,4,C.panel)
  button(2,35,19,"MAIN",C.purple,page=="main")
  button(23,35,19,"INFO",C.blue,page=="info")
  button(44,35,19,"RODS",C.orange,page=="rods")
  button(65,35,19,"PREV",C.blue,false)
  button(86,35,19,"NEXT",C.blue,false)
  button(107,35,11,"SCAN",C.cyan,false)
  button(120,35,11,"EXIT",C.red,false)
end

local function drawMain()
  header("SYSTEM DASHBOARD")
  local online=0
  local energy,fuel,fuelMax,waste,steam=0,0,0,0,0
  for _,a in ipairs(reactors) do
    if inv(a,"getActive")==true then online=online+1 end
    energy=energy+(tonumber(inv(a,"getEnergyStored")) or 0)
    fuel=fuel+(tonumber(inv(a,"getFuelAmount")) or 0)
    fuelMax=fuelMax+(tonumber(inv(a,"getFuelAmountMax")) or 0)
    waste=waste+(tonumber(inv(a,"getWasteAmount")) or 0)
    steam=steam+(tonumber(inv(a,"getHotFluidAmount")) or 0)
  end
  panel(3,6,41,12,"REACTORS",C.blue)
  txt(6,8,"DETECTED",C.grey,C.panel);txt(24,8,#reactors,C.white,C.panel)
  txt(6,10,"ONLINE",C.grey,C.panel);txt(24,10,online.." / "..#reactors,C.green,C.panel)
  bar(6,11,32,online,math.max(#reactors,1),C.green)
  txt(6,14,"SELECTED",C.grey,C.panel);txt(24,14,#reactors>0 and selected or "--",C.cyan,C.panel)
  txt(6,16,"AUTO",C.grey,C.panel);txt(24,16,auto and "ON" or "OFF",auto and C.green or C.red,C.panel)
  panel(47,6,82,12,"ENERGY / FUEL",C.cyan)
  txt(50,8,"ENERGY",C.grey,C.panel);txt(72,8,fmt(energy).." RF",C.white,C.panel)
  bar(50,9,74,energy,math.max(#reactors*10000000,1),C.cyan)
  txt(50,12,"FUEL",C.grey,C.panel);txt(72,12,fmt(fuel).." / "..fmt(fuelMax).." mb",C.yellow,C.panel)
  bar(50,13,74,fuel,math.max(fuelMax,1),C.yellow)
  txt(50,16,"STEAM",C.grey,C.panel);txt(72,16,fmt(steam).." mb",C.white,C.panel)
  panel(3,20,61,12,"QUICK CONTROL",C.purple)
  button(7,22,22,"START",C.green,false)
  button(32,22,22,"STOP",C.red,false)
  button(7,27,22,"INFO",C.blue,false)
  button(32,27,22,"RODS",C.orange,false)
  panel(67,20,62,12,"REACTOR",C.blue)
  if #reactors>0 then
    local a=addr()
    txt(70,22,"STATUS",C.grey,C.panel);txt(92,22,active() and "ONLINE" or "OFFLINE",active() and C.green or C.red,C.panel)
    txt(70,24,"CASING",C.grey,C.panel);txt(92,24,math.floor(tonumber(inv(a,"getCasingTemperature")) or 0).." C",C.yellow,C.panel)
    txt(70,26,"FUEL TEMP",C.grey,C.panel);txt(92,26,math.floor(tonumber(inv(a,"getFuelTemperature")) or 0).." C",C.orange,C.panel)
    txt(70,28,"COOLING",C.grey,C.panel);txt(92,28,cooled() and "ACTIVE" or "PASSIVE",C.cyan,C.panel)
  end
  footer()
end

local function drawInfo()
  header("REACTOR INFORMATION")
  if #reactors==0 then txt(43,18,"No br_reactor found",C.red,C.bg);footer();return end
  local a=addr()
  local e=tonumber(inv(a,"getEnergyStored")) or 0
  local fm=tonumber(inv(a,"getFuelAmountMax")) or 1
  local f=tonumber(inv(a,"getFuelAmount")) or 0
  local w=tonumber(inv(a,"getWasteAmount")) or 0
  local ct=tonumber(inv(a,"getCasingTemperature")) or 0
  local ft=tonumber(inv(a,"getFuelTemperature")) or 0
  local out=tonumber(inv(a,"getEnergyProducedLastTick")) or 0
  panel(3,6,62,25,"LIVE STATUS",C.orange)
  txt(7,8,"STATUS",C.grey,C.panel);txt(28,8,active() and "ONLINE" or "OFFLINE",active() and C.green or C.red,C.panel)
  txt(7,10,"CASING",C.grey,C.panel);txt(28,10,math.floor(ct).." C",C.yellow,C.panel);bar(7,11,54,ct,5000,ct>=1500 and C.red or C.yellow)
  txt(7,13,"FUEL TEMP",C.grey,C.panel);txt(28,13,math.floor(ft).." C",C.orange,C.panel);bar(7,14,54,ft,5000,ft>=1500 and C.red or C.orange)
  txt(7,16,"ENERGY",C.grey,C.panel);txt(28,16,fmt(e).." RF",C.cyan,C.panel);bar(7,17,54,e,10000000,C.cyan)
  txt(7,20,"OUTPUT/T",C.grey,C.panel);txt(28,20,fmt(out).." RF",C.green,C.panel)
  txt(7,22,"FUEL",C.grey,C.panel);txt(28,22,fmt(f).." / "..fmt(fm).." mb",C.yellow,C.panel);bar(7,23,54,f,fm,C.yellow)
  txt(7,26,"WASTE",C.grey,C.panel);txt(28,26,fmt(w).." mb",C.blue,C.panel)
  txt(7,28,"MODE",C.grey,C.panel);txt(28,28,cooled() and "ACTIVE COOLING" or "PASSIVE",C.cyan,C.panel)
  panel(67,6,62,25,"CONTROL",C.blue)
  button(70,9,23,"START",C.green,active())
  button(100,9,23,"STOP",C.red,not active())
  button(70,14,23,"PREVIOUS",C.blue,false)
  button(100,14,23,"NEXT",C.blue,false)
  button(70,19,23,auto and "AUTO ON" or "AUTO OFF",C.green,auto)
  button(100,19,23,"RESCAN",C.cyan,false)
  txt(70,24,"Big Reactors 0.4.3A",C.yellow,C.panel)
  txt(70,26,"OpenComputers 1.8.10",C.white,C.panel)
  txt(70,28,"component.invoke API",C.cyan,C.panel)
  footer()
end

local function drawRods()
  header("CONTROL RODS")
  if #reactors==0 then txt(43,18,"No br_reactor found",C.red,C.bg);footer();return end
  local a=addr();local count=rods()
  if count<=0 then txt(38,18,"No control rods reported",C.yellow,C.bg);footer();return end
  if rod>=count then rod=count-1 end
  local lvl=rodLevel(rod)
  panel(3,6,126,25,"ROD "..rod.." / "..(count-1),C.orange)
  txt(7,9,"LEVEL",C.grey,C.panel);txt(28,9,math.floor(lvl).." %",C.yellow,C.panel)
  bar(7,11,112,lvl,100,lvl>=80 and C.red or C.yellow)
  button(8,15,25,"-10",C.blue,false);button(36,15,25,"-1",C.blue,false)
  button(66,15,25,"+1",C.orange,false);button(94,15,25,"+10",C.orange,false)
  button(8,21,25,"PREV ROD",C.purple,false);button(36,21,25,"NEXT ROD",C.purple,false)
  button(66,21,25,"ALL 0%",C.green,false);button(94,21,25,"ALL 100%",C.red,false)
  txt(8,27,"Legacy API: setControlRodLevel(index, level)",C.white,C.panel)
  txt(8,29,"Index 0..N-1, matching original Reactor.lua",C.yellow,C.panel)
  footer()
end

local function draw()
  gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
  if page=="main" then drawMain() elseif page=="info" then drawInfo() else drawRods() end
end

local function doTouch(x,y)
  x=tonumber(x) or 0;y=tonumber(y) or 0
  if y>=35 then
    if x>=2 and x<=20 then page="main"
    elseif x>=23 and x<=41 then page="info"
    elseif x>=44 and x<=62 then page="rods"
    elseif x>=65 and x<=83 then nextReactor(-1)
    elseif x>=86 and x<=104 then nextReactor(1)
    elseif x>=107 and x<=118 then discover()
    elseif x>=120 then running=false end
    dirty=true;return
  end
  if #reactors==0 then return end
  if page=="main" then
    if y>=22 and y<=24 and x>=7 and x<=29 then setActive(true)
    elseif y>=22 and y<=24 and x>=32 and x<=54 then setActive(false)
    elseif y>=27 and y<=29 and x>=7 and x<=29 then page="info"
    elseif y>=27 and y<=29 and x>=32 and x<=54 then page="rods" end
  elseif page=="info" then
    if y>=9 and y<=11 and x>=70 and x<=93 then setActive(true)
    elseif y>=9 and y<=11 and x>=100 and x<=123 then setActive(false)
    elseif y>=14 and y<=16 and x>=70 and x<=93 then nextReactor(-1)
    elseif y>=14 and y<=16 and x>=100 and x<=123 then nextReactor(1)
    elseif y>=19 and y<=21 and x>=70 and x<=93 then auto=not auto
    elseif y>=19 and y<=21 and x>=100 and x<=123 then discover() end
  elseif page=="rods" then
    local count=rods();if count<=0 then return end
    if rod>=count then rod=count-1 end
    local lvl=rodLevel(rod)
    if y>=15 and y<=17 then
      if x>=8 and x<=33 then setOne(rod,lvl-10)
      elseif x>=36 and x<=61 then setOne(rod,lvl-1)
      elseif x>=66 and x<=91 then setOne(rod,lvl+1)
      elseif x>=94 and x<=119 then setOne(rod,lvl+10) end
    elseif y>=21 and y<=23 then
      if x>=8 and x<=33 then rod=(rod-1)%count
      elseif x>=36 and x<=61 then rod=(rod+1)%count
      elseif x>=66 and x<=91 then setAll(0)
      elseif x>=94 and x<=119 then setAll(100) end
    end
  end
  dirty=true
end

-- Use an OpenComputers touch listener. This is the same event mechanism as the original working program.
event.listen("touch",function(_,screenAddress,x,y,buttonNumber,player)
  doTouch(x,y)
end)

while running do
  if dirty then draw();dirty=false end
  local e,a,c,d=event.pull(0.5)
  if e=="key_down" then
    local code=d
    local char=c
    if code==keyboard.keys.q or char==string.byte("q") or char==string.byte("Q") then running=false
    elseif code==keyboard.keys.r or char==string.byte("r") or char==string.byte("R") then discover();dirty=true
    elseif code==keyboard.keys.tab then
      if page=="main" then page="info" elseif page=="info" then page="rods" else page="main" end
      dirty=true
    end
  end
end

gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
txt(47,19,"Controller stopped.",C.yellow,C.bg)
