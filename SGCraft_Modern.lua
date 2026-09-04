-- SGCraft_Modern.lua
-- BULDACITY // STARGATE COMMAND CENTER
-- Minecraft 1.7.10 / SGCraft-1.13.3-mc1.7.10.jar
-- OpenComputers Stargate Interface controller.
-- The interface API is verified against the SGCraft computer documentation.

local component=require("component")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.maxResolution(); gpu.setResolution(W,H)
local C={bg=0x050711,panel=0x10152B,cyan=0x00E5FF,blue=0x3478FF,purple=0xA35CFF,pink=0xFF38C8,green=0x39FF88,yellow=0xFFD84D,red=0xFF4D6D,white=0xECF7FF,dim=0x64708A}
local gates={}; local selected=1; local page=1; local running=true; local target=""

local function safe(o,n,...)
  if not o or type(o[n])~="function" then return nil end
  local ok,a,b,c=pcall(o[n],...); if ok then return a,b,c end
end
local function text(x,y,s,c) gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or "")) end
local function box(x,y,w,h,c) gpu.setBackground(c); gpu.fill(x,y,w,h," ") end
local function header(t) box(1,1,W,2,C.bg); text(3,1,"BULDACITY // SGCRAFT",C.cyan); text(3,2,t,C.white); text(math.max(1,W-18),1,"MC1.7.10",C.dim) end
local function card(x,y,w,h,t,c) box(x,y,w,h,C.panel); text(x+2,y,t,c or C.cyan); gpu.setForeground(C.dim); gpu.set(x,y+1,string.rep("─",math.max(0,w-1))) end
local function scan()
  gates={}
  for a in component.list("stargate",true) do gates[#gates+1]={address=a,proxy=component.proxy(a)} end
  selected=math.max(1,math.min(selected,math.max(1,#gates)))
end
local function state(g)
  local s,e,d=safe(g.proxy,"stargateState"); return s,e,d
end
local function selectedGate() return gates[selected] end
local function drawOverview()
  header("GATE // LIVE STATUS")
  card(2,4,W-3,8,"STARGATE STATUS",C.cyan)
  local g=selectedGate()
  if not g then text(5,7,"NO SGCraft OpenComputers Stargate Interface",C.red); text(5,9,"Connect an Open Computers Stargate Interface by cable.",C.dim); return end
  local s,e,d=state(g); local la=safe(g.proxy,"localAddress"); local ra=safe(g.proxy,"remoteAddress"); local energy=safe(g.proxy,"energyAvailable")
  text(5,6,"STATE",C.dim); text(15,6,s or "UNKNOWN",s=="Connected" and C.green or C.white)
  text(5,8,"CHEVRONS",C.dim); text(15,8,e or 0,C.cyan); text(5,10,"DIRECTION",C.dim); text(15,10,d~="" and (d or "-") or "-",C.white)
  text(math.floor(W/2),6,"LOCAL",C.dim); text(math.floor(W/2)+10,6,la or "-",C.white)
  text(math.floor(W/2),8,"REMOTE",C.dim); text(math.floor(W/2)+10,8,ra or "-",C.white)
  text(math.floor(W/2),10,"ENERGY",C.dim); text(math.floor(W/2)+10,10,string.format("%s SU",energy or 0),C.yellow)
end
local function drawDial()
  header("DIAL // ADDRESS CONTROL")
  card(2,4,W-3,10,"STARGATE DIALER",C.purple)
  local g=selectedGate(); if not g then text(5,7,"NO GATE",C.red); return end
  text(5,6,"LOCAL ADDRESS",C.dim); text(20,6,safe(g.proxy,"localAddress") or "-",C.white)
  text(5,8,"TARGET",C.dim); text(20,8,target=="" and "TYPE ADDRESS BELOW" or target,C.cyan)
  text(5,10,"D",C.yellow); text(8,10,"DIAL TARGET",C.white)
  text(22,10,"X",C.yellow); text(25,10,"DISCONNECT",C.white)
  text(5,12,"Address can be 7 or 9 characters; hyphens are accepted.",C.dim)
end
local function drawIris()
  header("IRIS // SECURITY")
  card(2,4,W-3,9,"IRIS CONTROL",C.pink)
  local g=selectedGate(); if not g then text(5,7,"NO GATE",C.red); return end
  local s=safe(g.proxy,"irisState") or "Offline"
  text(5,7,"IRIS",C.dim); text(13,7,s,s=="Closed" and C.green or C.yellow)
  text(5,9,"O",C.green); text(8,9,"OPEN IRIS",C.white)
  text(5,11,"C",C.red); text(8,11,"CLOSE IRIS",C.white)
  text(5,12,"Only use iris controls when an iris upgrade is installed.",C.dim)
end
local function drawMessages()
  header("LINK // MESSAGE CHANNEL")
  card(2,4,W-3,9,"OPEN STARGATE MESSAGE LINK",C.cyan)
  text(5,7,"SEND",C.yellow); text(12,7,"Use target/message code in this page.",C.white)
  text(5,9,"SGCraft sendMessage(...) is supported on an open connection.",C.dim)
  text(5,11,"Incoming sgMessageReceived events are shown while running.",C.dim)
end
local function draw()
  gpu.setBackground(C.bg); gpu.fill(1,1,W,H," ")
  if page==1 then drawOverview() elseif page==2 then drawDial() elseif page==3 then drawIris() else drawMessages() end
  box(1,H-2,W,3,C.bg)
  text(3,H-1,"1 STATUS   2 DIAL   3 IRIS   4 LINK",C.dim)
  text(math.max(1,W-31),H-1,"S SCAN   D DIAL   X DISCONNECT   Q EXIT",C.cyan)
end
scan(); draw()
while running do
  local e,_,_,_,key,ch=event.pull(0.5)
  if e=="key_down" then
    if key==17 then running=false
    elseif key==2 then page=1 elseif key==3 then page=2 elseif key==4 then page=3 elseif key==5 then page=4
    elseif key==31 then scan()
    elseif key==32 then local g=selectedGate(); if g then safe(g.proxy,"dial",target) end
    elseif key==45 then local g=selectedGate(); if g then safe(g.proxy,"disconnect") end
    elseif page==3 and key==24 then local g=selectedGate(); if g then safe(g.proxy,"openIris") end
    elseif page==3 and key==46 then local g=selectedGate(); if g then safe(g.proxy,"closeIris") end
    elseif ch and ch>=32 and ch<=126 and page==2 then target=target..string.char(ch):upper() end
    if key==14 and page==2 then target=target:sub(1,-2) end
  elseif e=="touch" then
    local _,_,x,y=event.pull(0)
    if y>=H-3 then if x<16 then page=1 elseif x<27 then page=2 elseif x<37 then page=3 else page=4 end end
  elseif e=="sgStargateStateChange" or e=="sgChevronEngaged" or e=="sgIrisStateChange" or e=="sgDialIn" or e=="sgDialOut" then
    draw()
  elseif e=="sgMessageReceived" then draw() end
  draw()
end

gpu.setBackground(0); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
