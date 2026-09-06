-- ReactorBigReactors043A_Touch_Responsive.lua
-- BULDACITY Big Reactors 0.4.3A / OpenComputers 1.7.10
-- Repaired control-rod handling: 0-based rod indexes, no false getConnected gate,
-- real API errors, readback verification and touch/keyboard controls.

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
local lastRodCount=0

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

local function invoke(addr,name,...)
  if not addr then return false,nil,"NO br_reactor COMPONENT" end
  local ok,a,b,c,d=pcall(component.invoke,addr,name,...)
  if not ok then return false,nil,tostring(a) end
  if a==nil and type(b)=="string" then return false,nil,b end
  return true,a,b,c,d
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
  if w<=0 or h<=0 or x>W or y>H then return end
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
  txt(x+math.max(1,math.floor((w-#label)/2)),y,label,on and c or C.white,on and C.white or c)
end

local function hit(id,x,y)
  local b=ui[id]
  return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function say(s) message=fit(s,W-6) end
local function reactorAddr() return reactors[selected] end

local function callReactor(name,...)
  return invoke(reactorAddr(),name,...)
end

local function read(name,default,...)
  local ok,v=callReactor(name,...)
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

-- Big Reactors 0.4.3A uses zero-based control-rod indexes.
local function rodCount()
  local ok,v,err=callReactor("getNumberOfControlRods")
  if not ok then return 0,err end
  local n=tonumber(v) or 0
  lastRodCount=n
  return n,nil
end

local function rodLevel(i)
  local n=lastRodCount
  if n<=0 then n=rodCount() end
  if n<=0 then return nil,"NO CONTROL RODS" end
  i=math.floor(tonumber(i) or 0)
  if i<0 or i>=n then return nil,"ROD INDEX OUT OF RANGE (0-"..(n-1)..")" end
  local ok,v,err=callReactor("getControlRodLevel",i)
  if not ok then return nil,err end
  v=tonumber(v)
  if v==nil then return nil,"INVALID ROD LEVEL" end
  return math.max(0,math.min(100,v)),nil
end

local function setActive(v)
  local ok,_,err=callReactor("setActive",v==true)
  if ok then say(v and"REACTOR STARTED"or"REACTOR STOPPED")
  else say("REACTOR ERROR: "..fit(err,W-22)) end
end

-- IMPORTANT: do not use getConnected() as a write gate.
-- The br_reactor component itself is the OpenComputers control-port interface.
-- Some 0.4.3A/OC combinations report getConnected() unexpectedly while the
-- normal reactor methods remain callable. The setter is therefore authoritative.
local function setRod(i,v)
  local n=rodCount()
  if n<=0 then say("NO CONTROL RODS: "..fit(select(2,rodCount()),W-20)) return false end
  i=math.max(0,math.min(n-1,math.floor(tonumber(i) or 0)))
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))

  -- Read first: this prevents a write to an invalid rod index.
  local before,readErr=rodLevel(i)
  if before==nil then
    say("ROD "..i.." READ ERROR: "..fit(readErr,W-19))
    return false
  end

  local ok,ret,err=callReactor("setControlRodLevel",i,v)
  if not ok then
    say("ROD "..i.." SET ERROR: "..fit(err,W-21))
    return false
  end

  local actual,verifyErr=rodLevel(i)
  rod=i
  if actual==nil then
    say("ROD "..i.." COMMAND OK // READBACK ERROR: "..fit(verifyErr,W-37))
    return true
  end
  if math.floor(actual)~=v then
    say("ROD "..i.." MISMATCH: CMD "..v.."% / ACT "..math.floor(actual).."%")
    return false
  end
  say("ROD "..i.." = "..math.floor(actual).."% // VERIFIED")
  return true
end

local function setAllRods(v)
  local n=rodCount()
  if n<=0 then say("NO CONTROL RODS") return false end
  v=math.max(0,math.min(100,math.floor(tonumber(v) or 0)))

  local ok,ret,err=callReactor("setAllControlRodLevels",v)
  if not ok then
    say("ALL RODS SET ERROR: "..fit(err,W-22))
    return false
  end

  local bad=0
  local firstBad=nil
  for i=0,n-1 do
    local actual=rodLevel(i)
    if actual==nil or math.floor(actual)~=v then
      bad=bad+1
      firstBad=firstBad or i
    end
  end
  if bad>0 then
    say("ALL RODS MISMATCH: "..bad.." // FIRST ROD "..tostring(firstBad))
    return false
  end
  say("ALL "..n.." RODS = "..v.."% // VERIFIED")
  return true
end

local function changeRod(delta)
  local lv,err=rodLevel(rod)
  if lv==nil then say("ROD READ ERROR: "..fit(err,W-17)) return end
  setRod(rod,lv+delta)
end

local function copySelectedToAll()
  local lv,err=rodLevel(rod)
  if lv==nil then say("COPY ERROR: "..fit(err,W-13)) return end
  setAllRods(lv)
end

local function rodDiagnostics()
  local n,err=rodCount()
  if n<=0 then say("ROD DIAGNOSTIC FAILED: "..fit(err,W-25)) return end
  local ok=0
  for i=0,n-1 do
    local lv=rodLevel(i)
    if lv~=nil then ok=ok+1 end
  end
  say("ROD API OK // "..ok.."/"..n.." READABLE // INDEX 0.."..(n-1))
end

local function scan()
  reactors={}
  for a in component.list("br_reactor") do reactors[#reactors+1]=a end
  if #reactors==0 then
    selected=1;rod=0;lastRodCount=0
    say("NO br_reactor DETECTED")
    return
  end
  if selected>#reactors then selected=1 end
  rod=0
  local n,err=rodCount()
  if n>0 then
    local lv=rodLevel(0)
    if lv~=nil then
      say(#reactors.." REACTOR(S) // "..n.." CONTROL RODS // API READY")
    else
      say(#reactors.." REACTOR(S) // ROD READ ERROR: "..fit(err,W-36))
    end
  else
    say(#reactors.." REACTOR(S) // NO CONTROL RODS")
  end
end

local function changeUnit(delta)
  if #reactors==0 then return end
  selected=((selected-1+delta)%#reactors)+1
  rod=0
  scan()
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

local function turbineSet(name,...)
  local a=turbineAddr()
  if not a then say("NO br_turbine DETECTED") return false end
  local ok,_,err=invoke(a,name,...)
  if not ok then say("TURBINE ERROR: "..fit(err,W-18)) return false end
  say("TURBINE // "..name.." OK")
  return true
end

local function autoControl()
  if not auto or not reactorAddr() then return end
  local ep=energy()
  local _,fa=fuel()
  local temp=temperature()
  if fa<=AUTO_MIN_FUEL then
    if active() then setActive(false) end
    return
  end
  if active() and temp>=AUTO_TEMP then
    setActive(false)
    return
  end
  if not active() and ep<AUTO_ON then
    setActive(true)
  elseif active() and ep>=AUTO_OFF then
    setActive(false)
  end
end

local function header(title)
  fill(1,1,W,4,C.panel)
  txt(3,1,"BULDACITY // BIG REACTORS 0.4.3A",C.cyan,C.panel)
  txt(3,2,title,C.white,C.panel)
  if reactorAddr() then led(math.max(5,W-22),2,active(),active() and C.green or C.red,active() and"ONLINE"or"OFFLINE") end
  rule(4,C.cyan)
end

local function footer()
  local y=math.max(6,H-4)
  ui={}
  local labels={
    {"reactor","CORE",C.cyan},{"rods","RODS",C.orange},{"turbine","TURBINE",C.pink},
    {"prev","< UNIT",C.blue},{"next","UNIT >",C.blue},{"scan","SCAN",C.yellow},{"exit","EXIT",C.red}
  }
  local gap=1
  local bw=math.max(6,math.floor((W-4-(#labels-1)*gap)/#labels))
  local x=2
  for _,b in ipairs(labels) do
    button(b[1],x,y,bw,b[2],b[3],page==b[1])
    x=x+bw+gap
  end
  txt(2,H,"[Q] EXIT [1] CORE [2] RODS [3] TURBINE [A] AUTO [UP/DOWN] ROD",C.grey,C.bg)
end

local function drawReactor()
  header("CORE // LIVE TELEMETRY + AUTO ENERGY")
  local y=6
  local h=H-11
  local gap=2
  local pw=math.max(18,math.floor((W-6-gap)/2))
  local x1=3
  local x2=x1+pw+gap
  panel(x1,y,pw,h,"REACTOR",C.cyan)
  panel(x2,y,pw,h,"POWER CONTROL",C.purple)
  if not reactorAddr() then
    txt(x1+3,y+4,"NO br_reactor FOUND",C.red,C.panel)
  else
    local ep,en=energy()
    local fp,fa=fuel()
    local temp=temperature()
    local n=lastRodCount>0 and lastRodCount or rodCount()
    txt(x1+3,y+2,"UNIT",C.grey,C.panel);txt(x1+17,y+2,selected.." / "..#reactors,C.white,C.panel)
    led(x1+3,y+4,true,C.green,"br_reactor COMPONENT")
    led(x1+3,y+7,active(),C.green,active() and"REACTOR ONLINE"or"REACTOR OFFLINE")
    led(x1+3,y+9,auto,C.purple,auto and"AUTO ENABLED"or"AUTO DISABLED")
    txt(x1+3,y+12,"ENERGY",C.grey,C.panel);txt(x1+17,y+12,string.format("%.1f %%",ep),C.cyan,C.panel)
    bar(x1+3,y+13,pw-6,ep,C.cyan)
    txt(x1+3,y+15,"STORED",C.grey,C.panel);txt(x1+17,y+15,math.floor(en).." RF",C.white,C.panel)
    txt(x1+3,y+17,"FUEL",C.grey,C.panel);txt(x1+17,y+17,string.format("%.1f %%",fp),C.yellow,C.panel)
    bar(x1+3,y+18,pw-6,fp,C.yellow)
    txt(x1+3,y+20,"TEMP",C.grey,C.panel);txt(x1+17,y+20,math.floor(temp).." C",temp>=AUTO_TEMP and C.red or C.orange,C.panel)
    txt(x1+3,y+22,"RODS",C.grey,C.panel);txt(x1+17,y+22,n.." // SELECTED "..rod,C.orange,C.panel)
  end

  local ep=energy()
  txt(x2+3,y+2,"AUTO THRESHOLDS",C.white,C.panel)
  txt(x2+3,y+4,"START",C.grey,C.panel);txt(x2+18,y+4,"< "..AUTO_ON.." %",C.red,C.panel)
  txt(x2+3,y+6,"STOP",C.grey,C.panel);txt(x2+18,y+6,">= "..AUTO_OFF.." %",C.green,C.panel)
  txt(x2+3,y+8,"CURRENT",C.grey,C.panel);txt(x2+18,y+8,string.format("%.1f %%",ep),C.cyan,C.panel)
  bar(x2+3,y+9,pw-6,ep,C.cyan)
  button("start",x2+3,y+12,math.max(8,math.floor((pw-8)/2)),"START",C.green)
  button("stop",x2+5+math.floor((pw-8)/2),y+12,math.max(8,math.floor((pw-8)/2)),"STOP",C.red)
  button("auto",x2+3,y+15,pw-6,auto and"AUTO: ON"or"AUTO: OFF",C.purple,auto)
  button("diag",x2+3,y+18,pw-6,"ROD API DIAGNOSTIC",C.orange)
  txt(x2+3,y+21,"STATUS",C.grey,C.panel)
  txt(x2+3,y+22,fit(message,pw-6),C.white,C.panel)
end

local function drawRods()
  header("CONTROL RODS // DIRECT API + READBACK")
  local y=6
  local h=H-11
  local w=W-6
  panel(3,y,w,h,"CONTROL ROD ARRAY",C.orange)
  if not reactorAddr() then
    txt(6,y+4,"NO REACTOR",C.red,C.panel);return
  end
  local n=rodCount()
  if n<=0 then
    txt(6,y+4,"NO CONTROL RODS / API ERROR",C.red,C.panel);return
  end
  txt(6,y+2,"ROD ",C.grey,C.panel);txt(13,y+2,tostring(rod),C.orange,C.panel)
  local lv,err=rodLevel(rod)
  if lv then
    txt(18,y+2,string.format("LEVEL %d%%",math.floor(lv)),C.white,C.panel)
    bar(30,y+2,math.max(10,w-33),lv,C.orange)
  else txt(18,y+2,fit(err,w-18),C.red,C.panel) end

  local cols=math.min(4,math.max(1,math.floor((W-8)/18)))
  local bw=math.floor((w-6-(cols-1)*2)/cols)
  for i=0,n-1 do
    local col=i%cols
    local row=math.floor(i/cols)
    local bx=6+col*(bw+2)
    local by=y+5+row*3
    if by+1<H-6 then
      local rlv=rodLevel(i)
      button("rod"..i,bx,by,bw,string.format("R%02d %3d%%",i,math.floor(rlv or 0)),C.orange,i==rod)
    end
  end
  local cy=math.min(H-8,y+8+math.ceil(n/cols)*3)
  button("minus10",6,cy,8,"-10",C.red)
  button("minus5",15,cy,8,"-5",C.red)
  button("minus1",24,cy,8,"-1",C.red)
  button("plus1",33,cy,8,"+1",C.green)
  button("plus5",42,cy,8,"+5",C.green)
  button("plus10",51,cy,8,"+10",C.green)
  button("copy",60,cy,12,"COPY -> ALL",C.cyan)
  button("all0",6,cy+3,12,"ALL 0%",C.blue)
  button("all50",19,cy+3,12,"ALL 50%",C.yellow)
  button("all100",32,cy+3,12,"ALL 100%",C.red)
  button("diag",45,cy+3,15,"DIAGNOSTIC",C.orange)
  txt(6,H-6,fit(message,W-12),C.white,C.bg)
end

local function drawTurbine()
  header("TURBINE // br_turbine")
  local y=6
  local h=H-11
  panel(3,y,W-6,h,"TURBINE TELEMETRY",C.pink)
  local a=turbineAddr()
  if not a then txt(6,y+4,"NO br_turbine DETECTED",C.red,C.panel);return end
  local on=tread("getActive",false)==true
  local rpm=tonumber(tread("getRotorSpeed",0)) or 0
  local rf=tonumber(tread("getEnergyProducedLastTick",0)) or 0
  local flow=tonumber(tread("getFluidFlowRate",0)) or 0
  local coils=tread("getInductorEngaged",false)==true
  led(6,y+3,on,C.green,on and"TURBINE ONLINE"or"TURBINE OFFLINE")
  txt(6,y+6,"ROTOR",C.grey,C.panel);txt(20,y+6,math.floor(rpm).." RPM",C.cyan,C.panel)
  txt(6,y+8,"OUTPUT",C.grey,C.panel);txt(20,y+8,math.floor(rf).." RF/t",C.green,C.panel)
  txt(6,y+10,"FLOW",C.grey,C.panel);txt(20,y+10,math.floor(flow).." mB/t",C.blue,C.panel)
  txt(6,y+12,"COILS",C.grey,C.panel);txt(20,y+12,coils and"ENGAGED"or"DISENGAGED",coils and C.yellow or C.grey,C.panel)
  button("ton",6,y+15,18,"TURBINE ON",C.green,on)
  button("toff",26,y+15,18,"TURBINE OFF",C.red,not on)
  button("con",46,y+15,18,"COILS ON",C.yellow,coils)
  button("coff",66,y+15,18,"COILS OFF",C.blue,not coils)
  txt(6,H-6,fit(message,W-12),C.white,C.bg)
end

local function draw()
  gpu.setBackground(C.bg);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
  if page=="rods" then drawRods()
  elseif page=="turbine" then drawTurbine()
  else drawReactor() end
  footer()
end

local function click(x,y)
  if hit("reactor",x,y) then page="reactor";return end
  if hit("rods",x,y) then page="rods";return end
  if hit("turbine",x,y) then page="turbine";return end
  if hit("prev",x,y) then changeUnit(-1);return end
  if hit("next",x,y) then changeUnit(1);return end
  if hit("scan",x,y) then scan();return end
  if hit("exit",x,y) then running=false;return end
  if hit("start",x,y) then setActive(true);return end
  if hit("stop",x,y) then setActive(false);return end
  if hit("auto",x,y) then auto=not auto;say(auto and"AUTO ENABLED"or"AUTO DISABLED");return end
  if hit("diag",x,y) then rodDiagnostics();return end
  if hit("minus10",x,y) then changeRod(-10);return end
  if hit("minus5",x,y) then changeRod(-5);return end
  if hit("minus1",x,y) then changeRod(-1);return end
  if hit("plus1",x,y) then changeRod(1);return end
  if hit("plus5",x,y) then changeRod(5);return end
  if hit("plus10",x,y) then changeRod(10);return end
  if hit("copy",x,y) then copySelectedToAll();return end
  if hit("all0",x,y) then setAllRods(0);return end
  if hit("all50",x,y) then setAllRods(50);return end
  if hit("all100",x,y) then setAllRods(100);return end
  if hit("ton",x,y) then turbineSet("setActive",true);return end
  if hit("toff",x,y) then turbineSet("setActive",false);return end
  if hit("con",x,y) then turbineSet("setInductorEngaged",true);return end
  if hit("coff",x,y) then turbineSet("setInductorEngaged",false);return end
  for i=0,lastRodCount-1 do
    if hit("rod"..i,x,y) then rod=i;say("SELECTED ROD "..i);return end
  end
end

scan()
while running do
  local ev={event.pull(0.5)}
  if ev[1]=="touch" then click(ev[3],ev[4])
  elseif ev[1]=="key_down" then
    local char,code=ev[3],ev[4]
    if char==113 or char==81 then running=false
    elseif char==49 then page="reactor"
    elseif char==50 then page="rods"
    elseif char==51 then page="turbine"
    elseif char==97 or char==65 then auto=not auto;say(auto and"AUTO ENABLED"or"AUTO DISABLED")
    elseif page=="rods" and code==200 then changeRod(5)
    elseif page=="rods" and code==208 then changeRod(-5)
    elseif page=="rods" and code==201 then changeRod(10)
    elseif page=="rods" and code==209 then changeRod(-10)
    end
  end
  autoControl()
  draw()
end

gpu.setBackground(0x000000);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,W,H," ")
txt(3,3,"BULDACITY REACTOR CONTROLLER STOPPED",C.cyan,C.bg)
