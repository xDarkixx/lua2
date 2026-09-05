-- SGCraft_Modern.lua
-- BULDACITY // STARGATE COMMAND CENTER v2
-- Minecraft 1.7.10 / SGCraft-1.13.3-mc1.7.10.jar
-- OpenComputers Stargate Interface controller.
-- API based on the official SGCraft computer-interface documentation.

local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local W,H=gpu.maxResolution(); gpu.setResolution(W,H)
local C={bg=0x050711,panel=0x10152B,cyan=0x00E5FF,blue=0x3478FF,purple=0xA35CFF,pink=0xFF38C8,green=0x39FF88,yellow=0xFFD84D,red=0xFF4D6D,white=0xECF7FF,dim=0x64708A}
local gates={}; local selected=1; local page=1; local running=true; local target=""; local message=""; local log={}

local function safe(o,n,...)
  if not o or type(o[n])~="function" then return nil,"METHOD_UNAVAILABLE" end
  local ok,a,b,c=pcall(o[n],...)
  if ok then return a,b,c end
  return nil,tostring(a)
end
local function addLog(s)
  log[#log+1]=os.date("%H:%M:%S").." "..tostring(s)
  while #log>5 do table.remove(log,1) end
end
local function text(x,y,s,c) gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or "")) end
local function box(x,y,w,h,c) gpu.setBackground(c); gpu.fill(x,y,w,h," ") end
local function header(t) box(1,1,W,2,C.bg); text(3,1,"BULDACITY // SGCRAFT",C.cyan); text(3,2,t,C.white); text(math.max(1,W-18),1,"MC1.7.10",C.dim) end
local function card(x,y,w,h,t,c) box(x,y,w,h,C.panel); text(x+2,y,t,c or C.cyan); gpu.setForeground(C.dim); gpu.set(x,y+1,string.rep("-",math.max(0,w-1))) end
local function scan()
  gates={}
  for a in component.list("stargate",true) do gates[#gates+1]={address=a,proxy=component.proxy(a)} end
  selected=math.max(1,math.min(selected,math.max(1,#gates)))
  addLog("SCAN: "..#gates.." Stargate Interface(s)")
end
local function selectedGate() return gates[selected] end
local function state(g) return safe(g.proxy,"stargateState") end
local function drawOverview()
  header("GATE // LIVE STATUS")
  card(2,4,W-3,10,"STARGATE STATUS",C.cyan)
  local g=selectedGate()
  if not g then text(5,7,"NO SGCraft OpenComputers Stargate Interface",C.red); text(5,9,"Place the Open Computers Stargate Interface under the gate.",C.dim); return end
  local s,e,d=state(g); local la=safe(g.proxy,"localAddress"); local ra=safe(g.proxy,"remoteAddress"); local energy=safe(g.proxy,"energyAvailable")
  text(5,6,"STATE",C.dim); text(15,6,s or "UNKNOWN",s=="Connected" and C.green or C.white)
  text(5,8,"CHEVRONS",C.dim); text(15,8,e or 0,C.cyan); text(5,10,"DIRECTION",C.dim); text(15,10,(d and d~="") and d or "-",C.white)
  text(math.floor(W/2),6,"LOCAL",C.dim); text(math.floor(W/2)+10,6,la or "-",C.white)
  text(math.floor(W/2),8,"REMOTE",C.dim); text(math.floor(W/2)+10,8,ra or "-",C.white)
  text(math.floor(W/2),10,"ENERGY",C.dim); text(math.floor(W/2)+10,10,string.format("%s SU",energy or 0),C.yellow)
  text(5,12,"GATE",C.dim); text(15,12,string.format("%d / %d",selected,#gates),C.white)
end
local function drawGateList()
  header("GATES // INTERFACES")
  card(2,4,W-3,H-8,"DETECTED STARGATE INTERFACES",C.blue)
  if #gates==0 then text(5,7,"NONE DETECTED - press S to scan",C.red); return end
  local y=6
  for i,g in ipairs(gates) do
    if y>H-5 then break end
    local s=safe(g.proxy,"stargateState") or "Offline"
    local mark=(i==selected) and ">" or " "
    text(5,y,mark.." "..i,C.yellow); text(10,y,g.address,C.white); text(47,y,s,s=="Connected" and C.green or C.dim); y=y+2
  end
end
local function drawDial()
  header("DIAL // ADDRESS CONTROL")
  card(2,4,W-3,13,"STARGATE DIALER",C.purple)
  local g=selectedGate(); if not g then text(5,7,"NO GATE",C.red); return end
  local need=target~="" and safe(g.proxy,"energyToDial",target) or nil
  local available=safe(g.proxy,"energyAvailable")
  text(5,6,"LOCAL",C.dim); text(20,6,safe(g.proxy,"localAddress") or "-",C.white)
  text(5,8,"TARGET",C.dim); text(20,8,target=="" and "TYPE ADDRESS" or target,C.cyan)
  text(5,10,"ENERGY",C.dim); text(20,10,(need and tostring(need) or "-").." / "..tostring(available or 0).." SU",C.yellow)
  text(5,12,"D",C.green); text(8,12,"DIAL",C.white); text(18,12,"X",C.red); text(21,12,"DISCONNECT",C.white)
  text(5,14,"Addresses may be 7 or 9 characters, with or without hyphens.",C.dim)
  text(5,15,"Enter target, then press D. Backspace edits the target.",C.dim)
end
local function drawIris()
  header("IRIS // SECURITY")
  card(2,4,W-3,9,"IRIS CONTROL",C.pink)
  local g=selectedGate(); if not g then text(5,7,"NO GATE",C.red); return end
  local s=safe(g.proxy,"irisState") or "Offline"
  text(5,7,"IRIS",C.dim); text(13,7,s,s=="Closed" and C.green or C.yellow)
  text(5,9,"O",C.green); text(8,9,"OPEN IRIS",C.white)
  text(5,11,"C",C.red); text(8,11,"CLOSE IRIS",C.white)
  text(5,12,"Iris is only available when fitted to the SGCraft gate.",C.dim)
end
local function drawMessages()
  header("LINK // STARGATE MESSAGES")
  card(2,4,W-3,9,"SEND MESSAGE",C.cyan)
  local g=selectedGate(); if not g then text(5,7,"NO GATE",C.red); return end
  text(5,6,"MESSAGE",C.dim); text(15,6,message=="" and "TYPE MESSAGE" or message,C.white)
  text(5,8,"M",C.yellow); text(8,8,"SEND THROUGH OPEN WORMHOLE",C.white)
  text(5,10,"Incoming sgMessageReceived events are shown in the log below.",C.dim)
  local y=12; for _,v in ipairs(log) do text(5,y,v,C.dim); y=y+1 end
end
local function draw()
  gpu.setBackground(C.bg); gpu.fill(1,1,W,H," ")
  if page==1 then drawOverview() elseif page==2 then drawGateList() elseif page==3 then drawDial() elseif page==4 then drawIris() else drawMessages() end
  box(1,H-2,W,3,C.bg)
  text(3,H-1,"1 STATUS  2 GATES  3 DIAL  4 IRIS  5 LINK",C.dim)
  text(math.max(1,W-34),H-1,"S SCAN  TAB NEXT  Q EXIT",C.cyan)
end
local function dial()
  local g=selectedGate(); if not g or target=="" then addLog("DIAL: missing gate/target"); return end
  local r,e=safe(g.proxy,"dial",target)
  if r==nil then addLog("DIAL ERROR: "..tostring(e)) else addLog("DIAL START: "..target) end
end
local function sendMessage()
  local g=selectedGate(); if not g or message=="" then return end
  local r,e=safe(g.proxy,"sendMessage",message)
  if r==nil then addLog("MSG ERROR: "..tostring(e)) else addLog("MSG SENT: "..message) end
end
scan(); draw()
while running do
  local e,_,a,b,key,ch=event.pull(0.5)
  if e=="key_down" then
    if key==17 then running=false
    elseif key==2 then page=1 elseif key==3 then page=2 elseif key==4 then page=3 elseif key==5 then page=4 elseif key==6 then page=5
    elseif key==31 then scan()
    elseif key==15 then selected=(selected%math.max(1,#gates))+1
    elseif key==32 and page==3 then dial()
    elseif key==45 and page==3 then local g=selectedGate(); if g then local r,e=safe(g.proxy,"disconnect"); addLog(r and "DISCONNECTED" or "DISCONNECT ERROR: "..tostring(e)) end
    elseif key==24 and page==4 then local g=selectedGate(); if g then local r,e=safe(g.proxy,"openIris"); addLog(r and "IRIS OPEN" or "IRIS ERROR: "..tostring(e)) end
    elseif key==46 and page==4 then local g=selectedGate(); if g then local r,e=safe(g.proxy,"closeIris"); addLog(r and "IRIS CLOSED" or "IRIS ERROR: "..tostring(e)) end
    elseif key==50 and page==5 then sendMessage()
    elseif key==14 then if page==3 then target=target:sub(1,-2) elseif page==5 then message=message:sub(1,-2) end
    elseif ch and ch>=32 and ch<=126 then
      if page==3 then target=target..string.char(ch):upper() elseif page==5 then message=message..string.char(ch) end
    end
    draw()
  elseif e=="touch" then
    local x,y=a,b
    if y>=H-3 then if x<15 then page=1 elseif x<27 then page=2 elseif x<38 then page=3 elseif x<48 then page=4 else page=5 end; draw()
    elseif page==2 and y>=6 and y<=H-5 then local i=math.floor((y-6)/2)+1; if gates[i] then selected=i; page=1; draw() end
    end
  elseif e=="sgStargateStateChange" or e=="sgChevronEngaged" or e=="sgIrisStateChange" or e=="sgDialIn" or e=="sgDialOut" then
    addLog(e); draw()
  elseif e=="sgMessageReceived" then
    addLog("REMOTE MSG: "..tostring(a)); draw()
  end
end

gpu.setBackground(0); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
