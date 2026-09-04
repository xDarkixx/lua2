-- Immersive Engineering Diesel Generator Touch Dashboard
-- Minecraft 1.7.10 / IE 0.7.7 / OpenComputers 1.8.10
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local gen=component.ie_diesel_generator
if not gen then error("Kein ie_diesel_generator gefunden.") end
local W,H=132,38
local C={bg=0x080B10,panel=0x111722,blue=0x2563EB,cyan=0x06B6D4,green=0x16A34A,yellow=0xEAB308,orange=0xEA580C,red=0xDC2626,purple=0x9333EA,white=0xF8FAFC,text=0xCBD5E1,muted=0x64748B,dark=0x030712,black=0}
local mode="AUTO"; local low=10; local high=20; local running=true; local active=false; local enabled=false; local amount=0; local capacity=0; local fluid="--"; local msg="Bereit"
local function sc(fn,...)
 local ok,a,b,c=pcall(fn,...); if ok then return a,b,c end; return nil,nil,c
end
local function txt(x,y,s,fg,bg) gpu.setForeground(fg or C.text); gpu.setBackground(bg or C.bg); gpu.set(x,y,tostring(s)) end
local function box(x,y,w,h,title,accent) gpu.setBackground(C.panel); gpu.fill(x,y,w,h," "); gpu.setBackground(accent or C.blue); gpu.fill(x,y,1,h," "); txt(x+3,y,"[ "..title.." ]",accent or C.cyan,C.panel) end
local function btn(x,y,w,label,accent) gpu.setBackground(accent); gpu.fill(x,y,w,3," "); local p=x+math.max(1,math.floor((w-#label)/2)); txt(p,y+1,label,C.white,accent) end
local function bar(x,y,w,p,fg) p=math.max(0,math.min(100,p)); gpu.setBackground(C.dark); gpu.fill(x,y,w,3," "); local n=math.floor(w*p/100); if n>0 then gpu.setBackground(fg); gpu.fill(x,y,n,3," ") end end
local function read()
 active=sc(gen.isActive)==true
 local info=sc(gen.getTankInfo); local t=info
 if type(info)=="table" and info[1] then t=info[1] end
 if type(t)=="table" then capacity=tonumber(t.capacity) or 0; local f=t.fluid; if type(f)=="table" then amount=tonumber(f.amount) or 0; fluid=tostring(f.name or "--") else amount=0; fluid=tostring(f or "--") end else amount=0; capacity=0; fluid="--" end
 if mode=="AUTO" and capacity>0 then local p=amount/capacity*100; if p<=low and enabled then sc(gen.setEnabled,false); enabled=false elseif p>=high and not enabled then sc(gen.setEnabled,true); enabled=true end end
end
local function draw()
 gpu.setResolution(W,H); gpu.setBackground(C.bg); gpu.fill(1,1,W,H," ")
 gpu.setBackground(C.blue); gpu.fill(1,1,W,4," "); txt(4,2,"IMMERSIVE ENGINEERING // DIESEL GENERATOR",C.white,C.blue); txt(4,3,"TOUCH CONTROL CENTER   MC 1.7.10 | IE 0.7.7 | OC 1.8.10",0xBFDBFE,C.blue)
 local p=capacity>0 and amount/capacity*100 or 0; local fc=p<=low and C.red or p<high and C.yellow or C.green
 box(2,6,62,15,"GENERATOR STATUS",active and C.green or C.red); txt(6,8,"STATE",C.muted); txt(18,8,active and "RUNNING" or enabled and "ENABLED / IDLE" or "STOPPED",active and C.green or enabled and C.yellow or C.red); txt(6,11,"MODE",C.muted); txt(18,11,mode,mode=="AUTO" and C.cyan or C.orange); txt(6,14,"COMPONENT",C.muted); txt(18,14,"ie_diesel_generator",C.purple); txt(6,17,"FUEL",C.muted); txt(18,17,string.format("%d / %d mB",amount,capacity),fc); bar(6,18,52,p,fc)
 box(66,6,64,15,"DIESEL TANK",fc); txt(70,8,"LEVEL",C.muted); txt(116,8,string.format("%.1f%%",p),fc); bar(70,10,54,p,fc); txt(70,14,"FLUID",C.muted); txt(84,14,fluid,C.white); txt(70,16,"AUTO RANGE",C.muted); txt(84,16,low.."% - "..high.."%",C.yellow)
 box(2,23,128,12,"TOUCH CONTROLS",C.cyan); btn(6,25,22,"AUTO",C.cyan); btn(31,25,22,"ON",C.green); btn(56,25,22,"OFF",C.red); btn(81,25,22,"REFRESH",C.yellow); btn(106,25,18,"QUIT",C.purple); txt(6,29,"Tip: direkt auf die farbigen Felder klicken.",C.muted); txt(6,32,msg,C.text)
end
local function click(x,y)
 if y>=25 and y<=27 then
  if x>=6 and x<28 then mode="AUTO"; msg="Automatik aktiviert"; read()
  elseif x>=31 and x<53 then mode="MANUAL"; enabled=true; sc(gen.setEnabled,true); msg="Generator EIN"
  elseif x>=56 and x<78 then mode="MANUAL"; enabled=false; sc(gen.setEnabled,false); msg="Generator AUS"
  elseif x>=81 and x<103 then msg="Aktualisiert"
  elseif x>=106 and x<124 then running=false end
 end
end
read(); draw()
while running do
 local e,a,x,y=event.pull(1)
 if e=="touch" then click(x,y); read(); draw() elseif e=="key_down" then local c=y; if c==string.byte("q") or c==string.byte("Q") then running=false elseif c==string.byte("a") or c==string.byte("A") then mode="AUTO" elseif c==string.byte("m") or c==string.byte("M") then mode="MANUAL"; enabled=true; sc(gen.setEnabled,true) elseif c==string.byte("o") or c==string.byte("O") then mode="MANUAL"; enabled=false; sc(gen.setEnabled,false) end; read(); draw() end
end
