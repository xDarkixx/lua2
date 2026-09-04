-- ReactorBigReactors043A_Touch_v3.lua
-- Minecraft 1.7.10 / Big Reactors 0.4.3A / OpenComputers 1.8.10+667626d
-- Rod control fix: uses component.invoke and checks pcall success separately.

local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local gpu = component.gpu

local W,H = 132,38
local reactors = {}
local selected = 1
local rod = 0
local page = "main"
local running = true
local message = "Ready"
local messageUntil = 0

local C={bg=0x000000,panel=0x151515,panel2=0x252525,blue=0x4286F4,
red=0xC14141,green=0x00DA41,yellow=0xFFDB4D,white=0xFFFFFF,
grey=0x47494C,cyan=0x66D9FF,orange=0xFF9900,purple=0xB673D6}

pcall(gpu.setResolution,W,H)

gpu.setBackground(C.bg)
gpu.setForeground(C.white)
gpu.fill(1,1,W,H," ")

-- IMPORTANT: return the pcall status separately from the API return value.
-- Big Reactors setter methods normally return nil on success.
local function invoke(addr,name,...)
  if not addr then return false,nil end
  local ok,a,b,c,d = pcall(component.invoke,addr,name,...)
  return ok,a,b,c,d
end

local function discover()
  reactors={}
  for a in component.list("br_reactor") do
    reactors[#reactors+1]=a
  end
  if #reactors == 0 then
    selected=1
    rod=0
    message="No br_reactor found"
    return
  end
  if selected>#reactors then selected=#reactors end
  local ok,count=invoke(reactors[selected],"getNumberOfControlRods")
  count=tonumber(count) or 0
  if count<=0 then rod=0 elseif rod>=count then rod=count-1 end
  message="Found "..#reactors.." reactor(s)"
end

discover()

local function addr()
  return reactors[selected]
end

local function read(name,default,...)
  local ok,v=invoke(addr(),name,...)
  if ok and v~=nil then return v end
  return default
end

local function active()
  return read("getActive",false)==true
end

local function rodCount()
  return tonumber(read("getNumberOfControlRods",0)) or 0
end

local function rodLevel(i)
  return tonumber(read("getControlRodLevel",0,i)) or 0
end

local function setActive(state)
  local ok=invoke(addr(),"setActive",state)
  if ok then message=state and "Reactor START command sent" or "Reactor STOP command sent"
  else message="ERROR: setActive failed" end
end

local function setAll(level)
  level=math.max(0,math.min(100,math.floor(tonumber(level) or 0)))
  local ok=invoke(addr(),"setAllControlRodLevels",level)
  if ok then message="ALL rods -> "..level.."%"
  else message="ERROR: setAllControlRodLevels failed" end
end

local function setOne(index,level)
  level=math.max(0,math.min(100,math.floor(tonumber(level) or 0)))
  local count=rodCount()
  if count<=0 then message="ERROR: no control rods reported"; return end
  if index<0 then index=0 end
  if index>=count then index=count-1 end

  -- Big Reactors 0.4.3A uses ZERO-BASED rod indices.
  -- Do NOT test the return value: successful setters return nil.
  local ok=invoke(addr(),"setControlRodLevel",index,level)
  if ok then
    rod=index
    message="Rod "..index.." -> "..level.."%"
  else
    message="ERROR: setControlRodLevel failed for rod "..index
  end
end

local function changeRod(delta)
  local n=rodCount()
  if n<=0 then message="No control rods"; return end
  local level=rodLevel(rod)+delta
  setOne(rod,level)
end

local function nextRod(delta)
  local n=rodCount()
  if n<=0 then return end
  rod=rod+delta
  if rod<0 then rod=n-1 end
  if rod>=n then rod=0 end
  message="Selected rod "..rod
end

local function nextReactor(delta)
  if #reactors==0 then return end
  selected=selected+delta
  if selected<1 then selected=#reactors end
  if selected>#reactors then selected=1 end
  rod=0
  message="Selected reactor "..selected
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

local function button(x,y,w,label,c,activeState)
  local bg=activeState and C.green or c
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

local function bar(x,y,w,value,max,c)
  value=tonumber(value) or 0
  max=math.max(tonumber(max) or 1,1)
  value=math.max(0,math.min(max,value))
  local n=math.floor(value/max*w)
  fill(x,y,w,1,C.panel2)
  if n>0 then fill(x,y,n,1,c or C.blue) end
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
  local energy=tonumber(read("getEnergyStored",0)) or 0
  local fuel=tonumber(read("getFuelAmount",0)) or 0
  local fuelMax=tonumber(read("getFuelAmountMax",1)) or 1
  local temp=tonumber(read("getFuelTemperature",0)) or 0
  panel(3,6,60,25,"REACTOR",C.blue)
  txt(7,9,"STATUS",C.grey,C.panel);txt(25,9,active() and "ONLINE" or "OFFLINE",active() and C.green or C.red,C.panel)
  txt(7,11,"ENERGY",C.grey,C.panel);txt(25,11,math.floor(energy).." RF",C.cyan,C.panel)
  txt(7,13,"FUEL",C.grey,C.panel);txt(25,13,math.floor(fuel).." / "..math.floor(fuelMax).." mb",C.yellow,C.panel)
  bar(7,14,50,fuel,fuelMax,C.yellow)
  txt(7,16,"FUEL TEMP",C.grey,C.panel);txt(25,16,math.floor(temp).." C",C.orange,C.panel)
  button(7,20,22,"START",C.green,false)
  button(32,20,22,"STOP",C.red,false)
  button(7,25,22,"RODS",C.orange,false)
  button(32,25,22,"INFO",C.blue,false)
  panel(67,6,62,25,"ROD QUICK CONTROL",C.orange)
  local n=rodCount()
  txt(71,9,"RODS",C.grey,C.panel);txt(88,9,n,C.white,C.panel)
  if n>0 then
    txt(71,11,"SELECTED",C.grey,C.panel);txt(88,11,rod,C.cyan,C.panel)
    txt(71,13,"LEVEL",C.grey,C.panel);txt(88,13,rodLevel(rod).." %",C.yellow,C.panel)
  end
  button(71,17,23,"-10",C.blue,false);button(99,17,23,"+10",C.orange,false)
  button(71,22,23,"-1",C.blue,false);button(99,22,23,"+1",C.orange,false)
  footer()
  txt(3,34,message,C.yellow,C.bg)
end

local function drawInfo()
  header("REACTOR INFORMATION")
  panel(3,6,60,25,"STATUS",C.cyan)
  txt(7,9,"ACTIVE",C.grey,C.panel);txt(25,9,active() and "TRUE" or "FALSE",active() and C.green or C.red,C.panel)
  txt(7,11,"ENERGY",C.grey,C.panel);txt(25,11,read("getEnergyStored",0).." RF",C.cyan,C.panel)
  txt(7,13,"FUEL",C.grey,C.panel);txt(25,13,read("getFuelAmount",0).." mb",C.yellow,C.panel)
  txt(7,15,"WASTE",C.grey,C.panel);txt(25,15,read("getWasteAmount",0).." mb",C.white,C.panel)
  txt(7,17,"CASING",C.grey,C.panel);txt(25,17,math.floor(read("getCasingTemperature",0)).." C",C.yellow,C.panel)
  txt(7,19,"FUEL TEMP",C.grey,C.panel);txt(25,19,math.floor(read("getFuelTemperature",0)).." C",C.orange,C.panel)
  panel(67,6,62,25,"COMMANDS",C.blue)
  button(71,9,23,"START",C.green,false)
  button(99,9,23,"STOP",C.red,false)
  button(71,14,23,"RODS",C.orange,false)
  button(99,14,23,"RESCAN",C.cyan,false)
  footer()
  txt(3,34,message,C.yellow,C.bg)
end

local function drawRods()
  header("CONTROL RODS")
  local n=rodCount()
  if #reactors==0 then
    txt(45,18,"No br_reactor found",C.red,C.bg)
    footer();return
  end
  if n<=0 then
    txt(40,18,"getNumberOfControlRods() returned 0",C.red,C.bg)
    footer();return
  end
  if rod>=n then rod=n-1 end
  local level=rodLevel(rod)
  panel(3,6,126,25,"ROD "..rod.." / "..(n-1),C.orange)
  txt(8,9,"LEVEL",C.grey,C.panel);txt(28,9,level.." %",C.yellow,C.panel)
  bar(8,11,112,level,100,level>=80 and C.red or C.yellow)
  button(8,15,25,"-10",C.blue,false)
  button(36,15,25,"-1",C.blue,false)
  button(66,15,25,"+1",C.orange,false)
  button(94,15,25,"+10",C.orange,false)
  button(8,21,25,"PREV ROD",C.purple,false)
  button(36,21,25,"NEXT ROD",C.purple,false)
  button(66,21,25,"ALL 0%",C.green,false)
  button(94,21,25,"ALL 100%",C.red,false)
  txt(8,27,"Index is 0-based, as required by Big Reactors 0.4.3A",C.white,C.panel)
  txt(8,29,message,C.yellow,C.panel)
  footer()
end

local function draw()
  gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
  if page=="main" then drawMain()
  elseif page=="info" then drawInfo()
  else drawRods() end
end

local function touch(x,y)
  x=tonumber(x) or 0;y=tonumber(y) or 0
  if y>=35 then
    if x>=2 and x<=20 then page="main"
    elseif x>=23 and x<=41 then page="info"
    elseif x>=44 and x<=62 then page="rods"
    elseif x>=65 and x<=83 then nextReactor(-1)
    elseif x>=86 and x<=104 then nextReactor(1)
    elseif x>=107 and x<=118 then discover()
    elseif x>=120 then running=false end
    return
  end
  if #reactors==0 then return end

  if page=="main" then
    if y>=20 and y<=22 and x>=7 and x<=29 then setActive(true)
    elseif y>=20 and y<=22 and x>=32 and x<=54 then setActive(false)
    elseif y>=25 and y<=27 and x>=7 and x<=29 then page="rods"
    elseif y>=25 and y<=27 and x>=32 and x<=54 then page="info"
    elseif y>=17 and y<=19 and x>=71 and x<=94 then changeRod(-10)
    elseif y>=17 and y<=19 and x>=99 and x<=122 then changeRod(10)
    elseif y>=22 and y<=24 and x>=71 and x<=94 then changeRod(-1)
    elseif y>=22 and y<=24 and x>=99 and x<=122 then changeRod(1) end
  elseif page=="info" then
    if y>=9 and y<=11 and x>=71 and x<=94 then setActive(true)
    elseif y>=9 and y<=11 and x>=99 and x<=122 then setActive(false)
    elseif y>=14 and y<=16 and x>=71 and x<=94 then page="rods"
    elseif y>=14 and y<=16 and x>=99 and x<=122 then discover() end
  elseif page=="rods" then
    if y>=15 and y<=17 and x>=8 and x<=33 then changeRod(-10)
    elseif y>=15 and y<=17 and x>=36 and x<=61 then changeRod(-1)
    elseif y>=15 and y<=17 and x>=66 and x<=91 then changeRod(1)
    elseif y>=15 and y<=17 and x>=94 and x<=119 then changeRod(10)
    elseif y>=21 and y<=23 and x>=8 and x<=33 then nextRod(-1)
    elseif y>=21 and y<=23 and x>=36 and x<=61 then nextRod(1)
    elseif y>=21 and y<=23 and x>=66 and x<=91 then setAll(0)
    elseif y>=21 and y<=23 and x>=94 and x<=119 then setAll(100) end
  end
end

local function keyDown(char,code)
  if char==string.byte("q") or char==string.byte("Q") then running=false;return end
  if code==keyboard.keys.left then nextReactor(-1)
  elseif code==keyboard.keys.right then nextReactor(1)
  elseif page=="rods" and code==keyboard.keys.up then nextRod(-1)
  elseif page=="rods" and code==keyboard.keys.down then nextRod(1)
  elseif page=="rods" and code==keyboard.keys.a then setAll(0)
  elseif page=="rods" and code==keyboard.keys.s then setAll(100) end
end

local function onTouch(_,screen,x,y,buttonNumber,player)
  touch(x,y)
end

local function onKey(_,_,char,code,player)
  keyDown(char,code)
end

event.listen("touch",onTouch)
event.listen("key_down",onKey)

draw()
while running do
  local e={event.pull(0.5)}
  if e[1]=="touch" then touch(e[3],e[4])
  elseif e[1]=="key_down" then keyDown(e[3],e[4]) end
  draw()
end

event.ignore("touch",onTouch)
event.ignore("key_down",onKey)
gpu.setBackground(C.bg)
gpu.setForeground(C.white)
gpu.fill(1,1,W,H," ")
