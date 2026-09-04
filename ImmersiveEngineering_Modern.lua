-- Buldacity / Immersive Engineering 0.7.7 / Minecraft 1.7.10
-- Diesel Generator is intentionally NOT controlled here; use DieselGenerator_Modern.lua.
local component=require("component")
local computer=require("computer")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.getResolution()
local BG=0x080C14; local FG=0x66FFFF; local GREEN=0x66FF99; local ORANGE=0xFFAA55
local function fit(s,n) s=tostring(s or ""); return #s>n and s:sub(1,n-3).."..." or s end
local function clear() gpu.setBackground(BG); gpu.setForeground(FG); gpu.fill(1,1,W,H," ") end
local function line(y,s) if y<=H then gpu.set(2,y,fit(s,W-2)) end end
local function title(s) gpu.fill(1,1,W,1," "); gpu.set(2,1,"BULDACITY // IMMERSIVE ENGINEERING // "..fit(s,W-39)) end
local function buttons(a,y) local n=#a; local bw=math.max(8,math.floor((W-4)/n)-1); for i,b in ipairs(a) do local x=2+(i-1)*(bw+1); gpu.fill(x,y,bw,2," "); gpu.set(x+1,y,b) end end
local function scan()
 local r={}
 for addr,typ in component.list() do local ok,m=pcall(component.methods,addr); local t=tostring(typ):lower(); local score=0
  if t:find("immers") or t:find("engine") or t:find("wire") or t:find("capacitor") then score=score+5 end
  if ok and m then for k,_ in pairs(m) do local x=tostring(k):lower(); if x:find("energy") or x:find("fluid") or x:find("redstone") or x:find("inventory") then score=score+1 end end end
  if score>0 then table.insert(r,{addr=addr,typ=tostring(typ),methods=m or {}}) end
 end
 return r
end
local dev=scan(); local page="HOME"; local last=0
local function refresh() if computer.uptime()-last>=2 then last=computer.uptime(); dev=scan(); return true end end
local function draw()
 clear(); title(page)
 if page=="HOME" then
  line(3,"IMMERSIVE ENGINEERING 0.7.7 • MC 1.7.10")
  line(5,"Diesel Generator: handled by DieselGenerator_Modern.lua")
  line(7,"Detected IE-related OC components: "..#dev)
  line(9,"Live component discovery: ON • refresh: 2s")
  line(11,"Dashboard exposes only methods actually provided by OpenComputers.")
  buttons({"COMPONENTS","API","ENERGY","FLUID"},H-3)
 elseif page=="COMPONENTS" then
  local y=3; for i,c in ipairs(dev) do if y>H-4 then break end; line(y,string.format("%02d  %-22s  %s",i,fit(c.typ,22),c.addr:sub(1,12))); y=y+1 end
  line(H-4,"LIVE LIST • automatic rescan every 2 seconds"); buttons({"HOME","API","REFRESH"},H-3)
 elseif page=="API" then
  local y=3; for _,c in ipairs(dev) do line(y,c.typ.." @"..c.addr:sub(1,12)); y=y+1; for m,_ in pairs(c.methods) do if y>H-4 then break end; line(y,"  • "..fit(m,W-6)); y=y+1 end end
  buttons({"HOME","COMPONENTS","REFRESH"},H-3)
 elseif page=="ENERGY" then
  line(3,"ENERGY / POWER COMPONENTS"); local y=5; for _,c in ipairs(dev) do local hit=false; for m,_ in pairs(c.methods) do if tostring(m):lower():find("energy") then hit=true end end; if hit then line(y,c.typ.." @"..c.addr:sub(1,12)); y=y+1 end end
  line(H-4,"Only runtime-exposed energy methods are shown."); buttons({"HOME","COMPONENTS"},H-3)
 else
  line(3,"FLUID / TANK COMPONENTS"); local y=5; for _,c in ipairs(dev) do local hit=false; for m,_ in pairs(c.methods) do if tostring(m):lower():find("fluid") or tostring(m):lower():find("tank") then hit=true end end; if hit then line(y,c.typ.." @"..c.addr:sub(1,12)); y=y+1 end end
  line(H-4,"Diesel Generator control remains in the dedicated controller."); buttons({"HOME","COMPONENTS"},H-3)
 end
end
local function go(a) if a=="REFRESH" then dev=scan() end; page=a; draw() end
draw()
while true do if refresh() then draw() end; local e={event.pull(1)}; if e[1]=="touch" and e[4]>=H-3 then local x=e[3]; local n=(page=="HOME" and 4 or 3); local i=math.floor((x-2)/math.max(1,math.floor((W-4)/n)))+1; local maps={HOME={"COMPONENTS","API","ENERGY","FLUID"},COMPONENTS={"HOME","API","REFRESH"},API={"HOME","COMPONENTS","REFRESH"},ENERGY={"HOME","COMPONENTS"},FLUID={"HOME","COMPONENTS"}}; go((maps[page] or {})[i] or page) elseif e[1]=="key_down" then local c=e[3]; if c==16 or c==28 then break elseif c==19 then dev=scan(); draw() end elseif e[1]=="interrupted" then break end end
