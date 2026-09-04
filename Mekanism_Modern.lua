-- Mekanism_Modern.lua
-- BULDACITY NEON HUD / Mekanism 9.1.1.1031 / OpenComputers / MC 1.7.10
-- Safe component discovery: never requires a Mekanism component to be PRIMARY.

local component=require("component")
local event=require("event")
local gpu=component.gpu

local W,H=gpu.getResolution()
local C={bg=0x05060D,panel=0x0B1020,cyan=0x00E5FF,blue=0x2488FF,purple=0xB54CFF,green=0x39FF88,yellow=0xFFE45C,red=0xFF4568,white=0xEAF6FF,dim=0x71809A}
local running=true
local selected=1
local status="SCANNING MEKANISM NETWORK..."
local devices={}
local lastScan=0

local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function safe(proxy,method,...)
  if not proxy or type(proxy[method])~="function" then return nil end
  local ok,a,b,c,d=pcall(proxy[method],...)
  if ok then return a,b,c,d end
end
local function text(x,y,s,col)
  gpu.setForeground(col or C.white); gpu.set(x,y,tostring(s or ""))
end
local function box(x,y,w,h,col)
  gpu.setBackground(col); gpu.fill(x,y,w,h," ")
end
local function line(x,y,w,col) box(x,y,w,1,col) end
local function pct(v,m)
  v=tonumber(v) or 0; m=tonumber(m) or 0
  if m<=0 then return 0 end
  return clamp(v/m*100,0,100)
end
local function bar(x,y,w,p,label)
  p=clamp(tonumber(p) or 0,0,100)
  box(x,y,w,1,C.panel)
  local n=math.floor(w*p/100)
  if n>0 then box(x,y,n,1,C.cyan) end
  text(x,y,label or string.format("%5.1f%%",p),C.white)
end

local function classify(t)
  t=tostring(t or ""):lower()
  if t:find("digital") then return "DIGITAL MINER" end
  if t:find("machine") or t:find("factory") then return "MACHINE" end
  if t:find("induction") then return "INDUCTION" end
  if t:find("energy") then return "ENERGY" end
  if t:find("fluid") then return "FLUID" end
  if t:find("gas") then return "GAS" end
  return string.upper(t)
end

local function scan()
  devices={}
  for address,ctype in component.list() do
    local s=tostring(ctype):lower()
    if s:find("mekanism") or s:find("digital") or s:find("induction") or s:find("factory") or s:find("energy") or s:find("fluid") or s:find("gas") then
      local p=component.proxy(address)
      devices[#devices+1]={address=address,type=ctype,name=classify(ctype),proxy=p}
    end
  end
  table.sort(devices,function(a,b) return a.name<b.name end)
  selected=clamp(selected,1,math.max(1,#devices))
  lastScan=os.time()
  status=(#devices>0 and "MEKANISM COMPONENTS ONLINE" or "NO MEKANISM COMPONENT FOUND")
end

local function energy(p)
  local a=safe(p,"getEnergyStored")
  local m=safe(p,"getMaxEnergyStored") or safe(p,"getEnergyStoredMax")
  if tonumber(a) and tonumber(m) and tonumber(m)>0 then return a,m,pct(a,m) end
end

local function drawHeader()
  box(1,1,W,H,C.bg)
  box(1,1,W,3,C.panel)
  text(2,2,"BULDACITY // MEKANISM CONTROL",C.cyan)
  text(math.max(2,W-24),2,"9.1.1.1031 // MC1.7.10",C.dim)
  line(1,4,W,C.blue)
end

local function draw()
  drawHeader()
  text(2,5,status,C.green)
  text(math.max(2,W-18),5,"DEVICES: "..#devices,C.white)
  local left=2; local top=7; local lw=26
  box(left,top,lw,H-top-2,C.panel)
  text(left+2,top+1,"COMPONENTS",C.purple)
  line(left+1,top+2,lw-2,C.purple)
  for i=1,math.min(#devices,H-top-5) do
    local d=devices[i]; local y=top+2+i
    if i==selected then box(left+1,y,lw-2,1,C.blue); text(left+2,y,d.name,C.white)
    else text(left+2,y,d.name,C.dim) end
  end
  local x=30; local y=7; local rw=W-x-1
  box(x,y,rw,H-y-2,C.panel)
  if #devices==0 then
    text(x+3,y+2,"NO SUPPORTED MEKANISM COMPONENT DETECTED",C.yellow)
    text(x+3,y+4,"Use an Adapter/OpenComponents integration where required.",C.dim)
    text(x+3,y+6,"Press S to scan again.",C.cyan)
    return
  end
  local d=devices[selected]; text(x+2,y+1,d.name,C.cyan); text(x+2,y+2,d.address,C.dim)
  local e,m,p=energy(d.proxy)
  if e then
    text(x+2,y+5,"ENERGY STORAGE",C.white)
    text(x+2,y+7,string.format("%s / %s RF",math.floor(e),math.floor(m)),C.white)
    bar(x+2,y+9,rw-4,p,string.format("%5.1f%%",p))
  else
    text(x+2,y+5,"TELEMETRY",C.white)
    text(x+2,y+7,"No compatible energy method exposed.",C.dim)
  end
  text(x+2,y+12,"SAFE CONTROL",C.purple)
  text(x+2,y+14,"This dashboard only calls methods exposed by the detected component.",C.dim)
  text(x+2,y+16,"No PRIMARY component is required.",C.green)
  text(x+2,y+19,"[ S ] SCAN     [ UP/DOWN ] SELECT     [ Q ] EXIT",C.cyan)
  text(x+2,y+21,"Mekanism 9.1.1.1031 detected as target version.",C.dim)
end

scan(); draw()
while running do
  local e=event.pull(0.5)
  if e then
    if e[1]=="key_down" then
      local ch=e[3]
      if ch==113 then running=false
      elseif ch==115 then scan(); draw()
      elseif ch==200 then selected=clamp(selected-1,1,math.max(1,#devices)); draw()
      elseif ch==208 then selected=clamp(selected+1,1,math.max(1,#devices)); draw() end
    elseif e[1]=="touch" then
      local x=e[3] or 0; local y=e[4] or 0
      if x>=1 and y>=1 and y<=H then
        if y>=8 and y<=H-4 and x<=28 then
          local i=y-9; if i>=1 and i<=#devices then selected=i; draw() end
        end
      end
    end
  end
end
gpu.setBackground(0x000000); gpu.setForeground(0xFFFFFF); gpu.fill(1,1,W,H," ")
