-- RFTools_Modern.lua
-- BULDACITY // RFTOOLS COMMAND CENTER
-- Minecraft 1.7.10 / rftools-4.23.jar
-- Safe OpenComputers controller: discovers real RFTools components and only
-- calls methods that are actually exposed by the connected component.

local component=require("component")
local event=require("event")
local gpu=component.gpu

local W,H=gpu.maxResolution()
gpu.setResolution(W,H)

local C={bg=0x070914,panel=0x10152B,cyan=0x00E5FF,blue=0x3D7CFF,purple=0x9B5CFF,pink=0xFF38C8,green=0x39FF88,yellow=0xFFD84D,red=0xFF4D6D,white=0xEAF7FF,dim=0x66708A}
local devices={}
local selected=1
local page=1
local running=true
local lastScan=0

local function safe(obj,name,...)
  if not obj or type(obj[name])~="function" then return nil end
  local ok,a,b,c,d=pcall(obj[name],...)
  if ok then return a,b,c,d end
end

local function text(x,y,s,c)
  gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or ""))
end
local function box(x,y,w,h,c)
  gpu.setBackground(c); gpu.fill(x,y,w,h," ")
end
local function bar(x,y,w,p,c)
  p=math.max(0,math.min(1,tonumber(p) or 0))
  box(x,y,w,1,C.dim); box(x,y,math.floor(w*p),1,c)
end
local function header(title)
  box(1,1,W,2,C.bg); text(3,1,"BULDACITY // RFTOOLS",C.cyan); text(3,2,title,C.white)
  text(math.max(1,W-18),1,"1.7.10 // 4.23",C.dim)
end
local function card(x,y,w,h,title,accent)
  box(x,y,w,h,C.panel); text(x+2,y,title,accent or C.cyan)
  gpu.setForeground(C.dim); gpu.set(x,y+1,string.rep("─",math.max(0,w-1)))
end

local function classify(t)
  t=(t or ""):lower()
  if t:find("builder") then return "BUILDER" end
  if t:find("shield") then return "SHIELD" end
  if t:find("dial") or t:find("teleport") then return "TELEPORT" end
  if t:find("screen") then return "SCREEN" end
  if t:find("crafter") then return "CRAFTER" end
  if t:find("spawner") then return "SPAWNER" end
  if t:find("storage") then return "STORAGE" end
  if t:find("environment") then return "ENVIRONMENT" end
  if t:find("energy") or t:find("power") then return "ENERGY" end
  return string.upper(t):sub(1,18)
end

local function scan()
  devices={}
  for t in component.list() do
    local l=t:lower()
    if l:find("rftools") or l:find("builder") or l:find("shield") or l:find("dial") or l:find("teleport") or l:find("crafter") or l:find("spawner") or l:find("screen") or l:find("environment") or l:find("storage") then
      for a in component.list(t,true) do
        local p=component.proxy(a)
        devices[#devices+1]={address=a,type=t,kind=classify(t),proxy=p}
      end
    end
  end
  selected=math.max(1,math.min(selected,math.max(1,#devices)))
  lastScan=os.time()
end

local function energy(d)
  local p=d.proxy
  local e=safe(p,"getEnergyStored")
  local m=safe(p,"getMaxEnergyStored") or safe(p,"getEnergyStoredMax")
  if type(e)=="number" and type(m)=="number" and m>0 then return e,m,e/m end
end

local function drawOverview()
  header("OVERVIEW // LIVE COMPONENT DISCOVERY")
  card(2,4,math.floor(W*0.48),7,"RFTools NETWORK",C.cyan)
  text(4,6,"Detected components:",C.dim); text(25,6,#devices,C.white)
  text(4,8,"Selected:",C.dim); text(14,8,devices[selected] and devices[selected].kind or "NONE",C.white)
  text(4,10,"Scan:",C.dim); text(10,10,"S",C.yellow); text(13,10,"manual rediscovery",C.dim)
  card(math.floor(W*0.52),4,math.floor(W*0.46)-1,7,"SELECTED DEVICE",C.purple)
  local d=devices[selected]
  if d then
    text(math.floor(W*0.52)+2,6,d.kind,C.white)
    text(math.floor(W*0.52)+2,7,d.type,C.dim)
    local e,m,p=energy(d)
    if p then text(math.floor(W*0.52)+2,9,"ENERGY",C.dim); text(math.floor(W*0.52)+11,9,string.format("%.0f%%",p*100),C.green); bar(math.floor(W*0.52)+2,10,24,p,C.green) end
  else text(math.floor(W*0.52)+2,6,"NO RFTools OC COMPONENT",C.red) end
end

local function drawDevices()
  header("DEVICES // SELECT COMPONENT")
  card(2,4,W-3,H-8,"DISCOVERED RFTools / OC DEVICES",C.cyan)
  local maxRows=math.max(1,H-14)
  local first=math.max(1,math.min(selected-math.floor(maxRows/2),math.max(1,#devices-maxRows+1)))
  for i=1,maxRows do
    local n=first+i-1; local d=devices[n]; if not d then break end
    local y=6+i
    if n==selected then box(4,y,W-7,1,C.blue) end
    text(5,y,string.format("%02d",n),n==selected and C.white or C.dim)
    text(9,y,d.kind,n==selected and C.cyan or C.white)
    text(23,y,d.type,C.dim)
  end
end

local function drawDetails()
  header("DETAIL // REAL METHODS ONLY")
  local d=devices[selected]
  card(2,4,W-3,H-8,"SELECTED COMPONENT",C.purple)
  if not d then text(5,7,"No RFTools OpenComputers component detected.",C.red); return end
  text(5,6,"TYPE",C.dim); text(14,6,d.type,C.white)
  text(5,8,"CLASS",C.dim); text(14,8,d.kind,C.cyan)
  text(5,10,"ADDRESS",C.dim); text(14,10,d.address,C.white)
  local e,m,p=energy(d)
  if p then text(5,12,"ENERGY",C.dim); text(14,12,string.format("%.0f / %.0f RF",e,m),C.white); bar(14,13,34,p,C.green) end
  text(5,15,"SAFE CONTROL",C.yellow)
  text(5,17,"This dashboard never invents RFTools methods.",C.dim)
  text(5,18,"Available controls depend on the actual OC driver",C.dim)
  text(5,19,"and the RFTools block connected to the computer.",C.dim)
end

local function draw()
  gpu.setBackground(C.bg); gpu.fill(1,1,W,H," ")
  if page==1 then drawOverview() elseif page==2 then drawDevices() else drawDetails() end
  box(1,H-2,W,3,C.bg)
  text(3,H-1,"1 OVERVIEW   2 DEVICES   3 DETAIL",C.dim)
  text(math.max(1,W-29),H-1,"UP/DOWN SELECT   S SCAN   Q EXIT",C.cyan)
end

scan(); draw()
while running do
  local e,_,_,_,key=event.pull(0.5)
  if e=="key_down" then
    if key==17 then running=false
    elseif key==2 then page=1
    elseif key==3 then page=2
    elseif key==4 then page=3
    elseif key==200 then selected=math.max(1,selected-1)
    elseif key==208 then selected=math.min(math.max(1,#devices),selected+1)
    elseif key==31 then scan() end
  elseif e=="touch" then
    local _,_,x,y=event.pull(0)
    if y>=H-3 and y<=H then
      if x<18 then page=1 elseif x<31 then page=2 else page=3 end
    end
  end
  draw()
end

gpu.setBackground(0x000000); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
