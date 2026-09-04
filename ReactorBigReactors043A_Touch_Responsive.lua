-- ReactorBigReactors043A_Touch_Responsive.lua
-- BULDACITY Big Reactors 0.4.3A controller for OpenComputers 1.7.10
-- Touch + keyboard dashboard. Standalone; also works behind BuldacityNetworkClient.

local component=require("component")
local event=require("event")
local gpu=component.gpu

local W,H=gpu.getResolution()
local reactors={}
local selected=1
local rod=0
local page="reactor"
local auto=false
local running=true
local message="BULDACITY REACTOR READY"
local ui={}
local lastScan=0

local AUTO_ON=10
local AUTO_OFF=90
local AUTO_TEMP=900
local AUTO_MIN_FUEL=1

local C={
 bg=0x03060B,panel=0x0A111B,panel2=0x101C29,line=0x214057,
 cyan=0x35E8FF,blue=0x438CFF,green=0x35FF9A,red=0xFF466D,
 yellow=0xFFE36A,purple=0xC56BFF,pink=0xFF4CCB,orange=0xFF9D45,
 white=0xF3FAFF,grey=0x7D96AA,off=0x263541
}

local function safe(fn,...)
  local ok,a,b,c,d=pcall(fn,...)
  if ok then return a,b,c,d end
end

local function invoke(addr,name,...)
  if not addr then return false,nil end
  local ok,a,b,c,d=pcall(component.invoke,addr,name,...)
  return ok,a,b,c,d
end

local function fit(s,n)
  s=tostring(s or "")
  n=math.max(1,n or 1)
  if #s<=n then return s end
  return n==1 and s:sub(1,1) or s:sub(1,n-3).."..."
end

local function txt(x,y,s,fg,bg)
  if x<1 or y<1 or x>W or y>H then return end
  gpu.setForeground(fg or C.white)
  gpu.setBackground(bg or C.bg)
  gpu.set(x,y,fit(s,W-x+1))
end

local function fill(x,y,w,h,bg)
  if w<=0 or h<=0 then return end
  gpu.setBackground(bg or C.panel)
  gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ")
end

local function rule(y,c)
  if y>=1 and y<=H then
    gpu.setBackground(c or C.line)
    gpu.fill(1,y,W,1," ")
  end
end

local function panel(x,y,w,h,title,c)
  fill(x,y,w,h,C.panel)
  rule(y,c or C.cyan)
  txt(x+2,y,"[ "..fit(title,w-5).." ]",c or C.cyan,C.panel)
  if h>2 then rule(y+h-1,C.line) end
end

local function led(x,y,on,c,label)
  local cc=on and(c or C.green)or C.off
  fill(x,y,2,1,cc)
  txt(x+3,y,label or(on and"ONLINE"or"OFFLINE"),on and cc or C.grey,C.panel)
end

local function bar(x,y,w,p,c)
  p=math.max(0,math.min(100,tonumber(p) or 0))
  fill(x,y,w,1,C.panel2)
  local n=math.floor(w*p/100)
  if n>0 then fill(x,y,n,1,c or C.cyan) end
end

local function button(id,x,y,w,label,c,on)
  w=math.max(5,w)
  ui[id]={x=x,y=y,w=w,h=2}
  fill(x,y,w,2,on and C.white or c)
  local fg=on and c or C.white
  txt(x+math.max(1,math.floor((w-#label)/2)),y,label,fg,on and C.white or c)
end

local function hit(id,x,y)
  local b=ui[id]
  return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function say(s) message=tostring(s) end

local function scan()
  reactors={}
  for a in component.list("br_reactor") do reactors[#reactors+1]=a end
  if #reactors==0 then
    selected=1
    rod=0
    say("NO br_reactor DETECTED")
  else
    if selected>#reactors then selected=1 end
    rod=0
    say(#reactors.." REACTOR UNIT(S) DETECTED")
  end
  lastScan=safe(require,"computer") and 0 or 0
end

local function reactorAddr() return reactors[selected] end

local function read(name,default,...)
  local ok,v=invoke(reactorAddr(),name,...)
  if ok and v~=nil then return v end
  return default
end

local function active() return read("getActive",false)==true end

local function energy()
  local stored=tonumber(read("getEnergyStored",0)) or 0
  local max=tonumber(read("getEnergyStoredMax",0)) or 0
  local pct=max>0 and math.max(0,math.min(100,stored/max*100)) or 0
  return pct,stored,max
end

local function fuel()
  local amount=tonumber(read("getFuelAmount",0)) or 0
  local max=tonumber(read("getFuelAmountMax",0)) or 0
  local pct=max>0 and math.max(0,math.min(100,amount/max*100)) or 0
  return pct,amount,max
end

local function temperature()
  return tonumber(read("getFuelTemperature",0)) or 0
end

local function rodCount()
  return tonumber(read("getNumberOfControlRods",0)) or 0
end

local function rodLevel(i)
  return tonumber(read("getControlRodLevel",0,i)) or 0
end

local function setActive(v)
  if not reactorAddr() then say("NO REACTOR") return end
  local ok=invoke(reactorAddr(),"setActive",v)
  if ok then
    say(v and"REACTOR STARTED"or"REACTOR STOPPED")
  else
    say("REACTOR COMMAND FAILED")
  end
end

local function setRod(i,v)
  local n=rodCount()
  if n<=0 then say("NO CONTROL RODS") return end
  i=math.max(0,math.min(n-1,math.floor(tonumber(i) or 0)))
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))
  local ok=invoke(reactorAddr(),"setControlRodLevel",i,v)
  if ok then
    rod=i
    say("ROD "..i.." -> "..v.."%")
  else
    say("ROD COMMAND FAILED")
  end
end

local function setAllRods(v)
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))
  local ok=invoke(reactorAddr(),"setAllControlRodLevels",v)
  say(ok and("ALL RODS -> "..v.."%")or"ALL RODS COMMAND FAILED")
end

local function changeRod(delta)
  if rodCount()>0 then setRod(rod,rodLevel(rod)+delta) end
end

local function changeUnit(delta)
  if #reactors==0 then return end
  selected=((selected-1+delta)%#reactors)+1
  rod=0
  say("UNIT "..selected.." / "..#reactors)
end

local function autoControl()
  if not auto or not reactorAddr() then return end
  local ep=energy()
  local fp,fa= fuel()
  local temp=temperature()

  if fa<=AUTO_MIN_FUEL then
    if active() then setActive(false) end
    say("AUTO SAFETY: FUEL LOW")
    return
  end
  if active() and temp>=AUTO_TEMP then
    setActive(false)
    say("AUTO SAFETY: TEMP >= "..AUTO_TEMP.." C")
    return
  end
  if not active() and ep<AUTO_ON then
    setActive(true)
    say("AUTO: LOW ENERGY -> START")
  elseif active() and ep>=AUTO_OFF then
    setActive(false)
    say("AUTO: HIGH ENERGY -> STOP")
  end
end

local function turbineAddr()
  for a in component.list("br_turbine") do return a end
end

local function tread(name,default,...)
  local a=turbineAddr()
  if not a then return default end
  local ok,v=invoke(a,name,...)
  if ok and v~=nil then return v end
  return default
end

local function header(title)
  fill(1,1,W,4,C.panel)
  txt(3,1,"BULDACITY // BIG REACTORS 0.4.3A",C.cyan,C.panel)
  txt(3,2,title,C.white,C.panel)
  local on=active()
  led(math.max(5,W-22),2,on,on and C.green or C.red,on and"ONLINE"or"OFFLINE")
  rule(4,C.cyan)
end

local function footer()
  local y=math.max(6,H-4)
  local n=7
  local gap=1
  local bw=math.max(6,math.floor((W-4-(n-1)*gap)/n))
  local x=2
  button("reactor",x,y,bw,"CORE",C.cyan,page=="reactor");x=x+bw+gap
  button("rods",x,y,bw,"RODS",C.orange,page=="rods");x=x+bw+gap
  button("turbine",x,y,bw,"TURBINE",C.pink,page=="turbine");x=x+bw+gap
  button("prev",x,y,bw,"< UNIT",C.blue);x=x+bw+gap
  button("next",x,y,bw,"UNIT >",C.blue);x=x+bw+gap
  button("scan",x,y,bw,"SCAN",C.yellow);x=x+bw+gap
  button("exit",x,y,bw,"EXIT",C.red)
  txt(2,H,"[Q] EXIT  [1] CORE  [2] RODS  [3] TURBINE  [A] AUTO  [UP/DOWN] ROD",C.grey,C.bg)
end

local function drawReactor()
  header("CORE // LIVE TELEMETRY + AUTO ENERGY")
  local y=6
  local h=H-11
  local gap=2
  local pw=math.floor((W-6-gap)/2)
  local x1=3
  local x2=x1+pw+gap
  panel(x1,y,pw,h,"REACTOR",C.cyan)
  panel(x2,y,pw,h,"POWER CONTROL",C.purple)

  if #reactors==0 then
    txt(x1+3,y+4,"NO br_reactor FOUND",C.red,C.panel)
    txt(x1+3,y+6,"Attach a Big Reactors reactor",C.grey,C.panel)
    txt(x1+3,y+7,"to the OpenComputers network.",C.grey,C.panel)
  else
    local ep,en,em=energy()
    local fp,fa,fm=fuel()
    local temp=temperature()
    local cool=read("isActivelyCooled",false)==true
    txt(x1+3,y+2,"UNIT",C.grey,C.panel)
    txt(x1+17,y+2,selected.." / "..#reactors,C.white,C.panel)
    led(x1+3,y+4,active(),C.green,active() and"REACTOR ONLINE"or"REACTOR OFFLINE")
    led(x1+3,y+6,auto,C.purple,auto and"AUTO ENABLED"or"AUTO DISABLED")
    led(x1+3,y+8,cool,C.cyan,cool and"ACTIVE COOLING"or"PASSIVE COOLING")

    txt(x1+3,y+10,"ENERGY",C.grey,C.panel)
    txt(x1+17,y+10,string.format("%.1f %%",ep),ep<10 and C.red or(ep>=90 and C.green or C.cyan),C.panel)
    bar(x1+3,y+11,pw-6,ep,ep<10 and C.red or(ep>=90 and C.green or C.cyan))
    txt(x1+3,y+13,"STORED",C.grey,C.panel)
    txt(x1+17,y+13,math.floor(en).." RF",C.white,C.panel)

    txt(x1+3,y+15,"FUEL",C.grey,C.panel)
    txt(x1+17,y+15,string.format("%.1f %%",fp),C.yellow,C.panel)
    bar(x1+3,y+16,pw-6,fp,C.yellow)
    txt(x1+3,y+18,"TEMP",C.grey,C.panel)
    txt(x1+17,y+18,math.floor(temp).." C",temp>=AUTO_TEMP and C.red or C.orange,C.panel)
    bar(x1+3,y+19,pw-6,math.min(100,temp/1000*100),temp>=AUTO_TEMP and C.red or C.orange)
    txt(x1+3,y+21,"FUEL",C.grey,C.panel)
    txt(x1+17,y+21,math.floor(fa).." / "..math.floor(fm).." mB",C.yellow,C.panel)
  end

  local ep=energy()
  txt(x2+3,y+2,"AUTO THRESHOLDS",C.white,C.panel)
  txt(x2+3,y+4,"START",C.grey,C.panel)
  txt(x2+18,y+4,"< "..AUTO_ON.." %",C.red,C.panel)
  txt(x2+3,y+6,"STOP",C.grey,C.panel)
  txt(x2+18,y+6,">= "..AUTO_OFF.." %",C.green,C.panel)
  txt(x2+3,y+8,"CURRENT",C.grey,C.panel)
  txt(x2+18,y+8,string.format("%.1f %%",ep),C.cyan,C.panel)
  bar(x2+3,y+9,pw-6,ep,C.cyan)
  led(x2+3,y+12,auto and ep<AUTO_ON,C.red,"LOW POWER START")
  led(x2+3,y+14,auto and ep>=AUTO_OFF,C.green,"HIGH POWER STOP")
  led(x2+3,y+16,active(),C.cyan,"SAFETY MONITOR")
  txt(x2+3,y+19,"SAFE TEMP",C.grey,C.panel)
  txt(x2+18,y+19,"< "..AUTO_TEMP.." C",C.orange,C.panel)
  button("start",x2+3,y+21,math.floor((pw-7)/2),"START",C.green)
  button("stop",x2+5+math.floor((pw-7)/2),y+21,math.floor((pw-7)/2),"STOP",C.red)
  button("auto",x2+3,y+23,pw-6,"AUTO: "..(auto and"ON"or"OFF"),C.purple,auto)

  footer()
  txt(3,H-5,fit(message,W-6),C.yellow,C.bg)
end

local function drawRods()
  header("CONTROL RODS // TOUCH CONTROL")
  local y=6
  local h=H-11
  local w=W-6
  panel(3,y,w,h,"ROD MATRIX",C.orange)
  local n=rodCount()
  if n<=0 then
    txt(7,y+4,"NO CONTROL RODS DETECTED",C.red,C.panel)
  else
    local cols=math.min(4,n)
    local rows=math.ceil(n/cols)
    local cw=math.floor((w-6-(cols-1)*2)/cols)
    for i=0,n-1 do
      local col=i%cols
      local row=math.floor(i/cols)
      local x=6+col*(cw+2)
      local yy=y+3+row*3
      local lv=rodLevel(i)
      button("rod"..i,x,yy,cw,"R"..i.." "..lv.."%",i==rod and C.white or C.orange,i==rod)
      bar(x,yy+2,cw,lv,i==rod and C.cyan or C.orange)
    end
    local controlsY=math.min(y+h-4,y+5+rows*3)
    button("minus",6,controlsY,12,"-5",C.red)
    button("plus",20,controlsY,12,"+5",C.green)
    button("all0",34,controlsY,12,"ALL 0",C.blue)
    button("all50",48,controlsY,12,"ALL 50",C.yellow)
    button("all100",62,controlsY,12,"ALL 100",C.purple)
  end
  footer()
  txt(3,H-5,fit(message,W-6),C.yellow,C.bg)
end

local function drawTurbine()
  header("TURBINE // LIVE TELEMETRY")
  local y=6
  local h=H-11
  local w=W-6
  panel(3,y,w,h,"TURBINE",C.pink)
  local a=turbineAddr()
  if not a then
    txt(7,y+4,"NO br_turbine FOUND",C.red,C.panel)
    txt(7,y+6,"Attach a Big Reactors turbine",C.grey,C.panel)
    txt(7,y+7,"to view live telemetry.",C.grey,C.panel)
  else
    local on=tread("getActive",false)==true
    local rpm=tonumber(tread("getRotorSpeed",0)) or 0
    local out=tonumber(tread("getEnergyProducedLastTick",0)) or 0
    local flow=tonumber(tread("getFluidFlowRate",0)) or 0
    local ind=tread("getInductorEngaged",false)==true
    local two=math.floor((w-9)/2)
    local x1=6
    local x2=6+two+3
    led(x1,y+3,on,C.green,on and"TURBINE ONLINE"or"TURBINE OFFLINE")
    led(x2,y+3,ind,C.purple,ind and"INDUCTOR ENGAGED"or"INDUCTOR OPEN")
    txt(x1,y+6,"ROTOR SPEED",C.grey,C.panel)
    txt(x1+18,y+6,string.format("%.1f RPM",rpm),C.cyan,C.panel)
    bar(x1,y+7,two,math.min(100,rpm/1800*100),C.cyan)
    txt(x2,y+6,"OUTPUT",C.grey,C.panel)
    txt(x2+15,y+6,math.floor(out).." RF/t",C.green,C.panel)
    txt(x1,y+10,"FLUID FLOW",C.grey,C.panel)
    txt(x1+18,y+10,math.floor(flow).." mB/t",C.yellow,C.panel)
    txt(x2,y+10,"COMPONENT",C.grey,C.panel)
    txt(x2+15,y+10,fit(a,18),C.white,C.panel)
    txt(6,y+14,"CONTROL",C.white,C.panel)
    button("tstart",6,y+16,16,"START",C.green)
    button("tstop",24,y+16,16,"STOP",C.red)
    button("tind",42,y+16,20,"INDUCTOR",C.purple,ind)
  end
  footer()
  txt(3,H-5,fit(message,W-6),C.yellow,C.bg)
end

local function draw()
  ui={}
  gpu.setBackground(C.bg)
  gpu.fill(1,1,W,H," ")
  if page=="reactor" then drawReactor()
  elseif page=="rods" then drawRods()
  else drawTurbine() end
end

local function resize()
  local mw,mh=safe(gpu.maxResolution)
  if mw and mh then safe(gpu.setResolution,mw,mh) end
  W,H=gpu.getResolution()
end

local function action(id)
  if id=="reactor" then page="reactor"
  elseif id=="rods" then page="rods"
  elseif id=="turbine" then page="turbine"
  elseif id=="prev" then changeUnit(-1)
  elseif id=="next" then changeUnit(1)
  elseif id=="scan" then scan()
  elseif id=="exit" then running=false
  elseif id=="start" then setActive(true)
  elseif id=="stop" then setActive(false)
  elseif id=="auto" then auto=not auto;say("AUTO "..(auto and"ENABLED"or"DISABLED"))
  elseif id=="minus" then changeRod(-5)
  elseif id=="plus" then changeRod(5)
  elseif id=="all0" then setAllRods(0)
  elseif id=="all50" then setAllRods(50)
  elseif id=="all100" then setAllRods(100)
  elseif id=="tstart" then invoke(turbineAddr(),"setActive",true);say("TURBINE START")
  elseif id=="tstop" then invoke(turbineAddr(),"setActive",false);say("TURBINE STOP")
  elseif id=="tind" then invoke(turbineAddr(),"setInductorEngaged",not tread("getInductorEngaged",false));say("INDUCTOR TOGGLED")
  elseif id:sub(1,3)=="rod" then rod=tonumber(id:sub(4)) or rod;say("SELECTED ROD "..rod) end
end

scan()
resize()
draw()

while running do
  local e={event.pull(0.25)}
  if e[1]=="touch" then
    local x,y=e[3],e[4]
    for id in pairs(ui) do
      if hit(id,x,y) then action(id);break end
    end
  elseif e[1]=="key_down" then
    local code=e[4]
    if code==16 then running=false
    elseif code==2 then page="reactor"
    elseif code==3 then page="rods"
    elseif code==4 then page="turbine"
    elseif code==30 then auto=not auto;say("AUTO "..(auto and"ENABLED"or"DISABLED"))
    elseif code==200 then changeRod(5)
    elseif code==208 then changeRod(-5)
    elseif code==203 then changeUnit(-1)
    elseif code==205 then changeUnit(1)
    elseif code==28 then setActive(not active()) end
  elseif e[1]=="screen_resized" then
    resize()
  end

  autoControl()
  if computer and false then end
  if page=="reactor" or page=="rods" or page=="turbine" then draw() end
end

gpu.setBackground(0x000000)
gpu.fill(1,1,W,H," ")
txt(3,3,"BULDACITY REACTOR CONTROLLER STOPPED",C.cyan,0x000000)
