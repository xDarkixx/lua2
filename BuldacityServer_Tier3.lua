-- BuldacityServer_Tier3.lua
-- BULDACITY // TIER 3 NETWORK DESKTOP
-- OpenComputers 1.7.10
-- Receives the shared BULDACITY/1 protocol on a wireless/network card.

local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu

local PORT=4242
local PROTOCOL="BULDACITY/1"
local devices={}
local running=true
local page=1
local selected=1
local lastDraw=0

local C={bg=0x050711,panel=0x10152B,cyan=0x00E5FF,blue=0x3478FF,purple=0xA35CFF,pink=0xFF38C8,green=0x39FF88,yellow=0xFFD84D,red=0xFF4D6D,white=0xECF7FF,dim=0x64708A}

local modem
for address in component.list("modem",true) do modem=component.proxy(address); break end
if not modem then error("Buldacity Tier-3 Server requires a Network/Wireless Network Card") end
modem.open(PORT)

local function text(x,y,s,c) gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or "")) end
local function box(x,y,w,h,c) gpu.setBackground(c); gpu.fill(x,y,w,h," ") end
local function card(x,y,w,h,title,accent) box(x,y,w,h,C.panel); text(x+2,y,title,accent or C.cyan); gpu.setForeground(C.dim); gpu.set(x,y+1,string.rep("─",math.max(0,w-1))) end
local function online(d) return computer.uptime()-d.last<=10 end
local function sortDevices() table.sort(devices,function(a,b) return tostring(a.name)<tostring(b.name) end) end
local function upsert(address,data)
  local d=devices[address]
  if not d then d={address=address}; devices[address]=d end
  for k,v in pairs(data or {}) do d[k]=v end
  d.last=computer.uptime()
  sortDevices()
end
local function broadcast(kind,data)
  modem.broadcast(PORT,{protocol=PROTOCOL,kind=kind,sender=computer.address(),time=computer.uptime(),data=data or {}})
end
local function process(e,receiver,sender,port,distance,payload)
  if e~="modem_message" or port~=PORT or type(payload)~="table" or payload.protocol~=PROTOCOL then return end
  local d=payload.data or {}
  if payload.kind=="HELLO" or payload.kind=="HEARTBEAT" or payload.kind=="STATUS" or payload.kind=="SCREEN" then
    d.role=d.role or "CLIENT"; d.last=computer.uptime(); upsert(sender,d)
  end
end
local function drawHeader(title)
  box(1,1,W,2,C.bg); text(3,1,"BULDACITY // TIER 3",C.cyan); text(3,2,title,C.white); text(math.max(1,W-17),1,"NETWORK DESKTOP",C.dim)
end
local function drawHome()
  drawHeader("DESKTOP // NETWORK OVERVIEW")
  card(2,4,math.floor(W*.48),8,"NETWORK",C.cyan)
  local count=0; for _,d in pairs(devices) do if online(d) then count=count+1 end end
  text(5,6,"ONLINE",C.dim); text(15,6,count,C.green)
  text(5,8,"KNOWN",C.dim); text(15,8,#devices,C.white)
  text(5,10,"PORT",C.dim); text(15,10,PORT,C.yellow)
  text(math.floor(W*.52),6,"WIRELESS / NETWORK",C.cyan)
  text(math.floor(W*.52),8,"Protocol",C.dim); text(math.floor(W*.52)+12,8,PROTOCOL,C.white)
  text(math.floor(W*.52),10,"Server",C.dim); text(math.floor(W*.52)+12,10,"TIER 3",C.green)
end
local function drawDevices()
  drawHeader("DEVICES // REMOTE DESKTOP")
  card(2,4,W-3,H-8,"CONNECTED BULDACITY CLIENTS",C.purple)
  local row=6; local i=0
  for _,d in pairs(devices) do
    i=i+1
    if row>H-5 then break end
    local ok=online(d); if i==selected then box(4,row,W-7,1,C.blue) end
    text(5,row,string.format("%02d",i),i==selected and C.white or C.dim)
    text(9,row,(d.name or "UNKNOWN"):sub(1,22),i==selected and C.cyan or C.white)
    text(33,row,d.role or "CLIENT",C.dim)
    text(45,row,ok and "ONLINE" or "OFFLINE",ok and C.green or C.red)
    row=row+1
  end
end
local function selectedDevice()
  local list={}; for _,d in pairs(devices) do list[#list+1]=d end; table.sort(list,function(a,b) return tostring(a.name)<tostring(b.name) end); return list[selected]
end
local function drawRemote()
  drawHeader("REMOTE // DEVICE DESKTOP")
  local d=selectedDevice(); card(2,4,W-3,H-8,"REMOTE DEVICE",C.pink)
  if not d then text(5,7,"No Buldacity client discovered.",C.red); return end
  text(5,6,"NAME",C.dim); text(17,6,d.name or "-",C.white)
  text(5,8,"ROLE",C.dim); text(17,8,d.role or "CLIENT",C.cyan)
  text(5,10,"STATE",C.dim); text(17,10,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red)
  text(5,12,"APP",C.dim); text(17,12,d.app or "-",C.white)
  text(5,14,"ADDRESS",C.dim); text(17,14,d.address or "-",C.dim)
  text(5,16,"REMOTE VIEW",C.yellow)
  text(5,18,d.screen or "No screen snapshot reported.",C.white)
end
local function draw()
  W,H=gpu.maxResolution(); gpu.setResolution(W,H); gpu.setBackground(C.bg); gpu.fill(1,1,W,H," ")
  if page==1 then drawHome() elseif page==2 then drawDevices() else drawRemote() end
  box(1,H-2,W,3,C.bg)
  text(3,H-1,"1 DESKTOP   2 DEVICES   3 REMOTE",C.dim)
  text(math.max(1,W-30),H-1,"UP/DOWN SELECT   R REFRESH   Q EXIT",C.cyan)
end
broadcast("SERVER",{name="BULDACITY TIER 3 SERVER",role="SERVER"})
draw()
while running do
  local e,a,b,c,d=event.pull(0.5)
  if e=="key_down" then
    local key=d
    if key==17 then running=false
    elseif key==2 then page=1 elseif key==3 then page=2 elseif key==4 then page=3
    elseif key==200 then selected=math.max(1,selected-1)
    elseif key==208 then selected=math.min(math.max(1,#devices),selected+1)
    elseif key==19 then broadcast("SERVER",{name="BULDACITY TIER 3 SERVER",role="SERVER"}) end
  elseif e=="modem_message" then process(e,a,b,c,d)
  end
  if computer.uptime()-lastDraw>=1 then lastDraw=computer.uptime(); draw() end
end

gpu.setBackground(0); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
