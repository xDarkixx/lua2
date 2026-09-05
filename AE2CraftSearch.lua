-- AE2CraftSearch.lua
-- Buldacity AE2 crafting terminal with a real clickable search window.
-- Minecraft 1.7.10 / AE2 rv3 beta 6 / OpenComputers 1.8.10

local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local me=component.me_controller
if not me then error("Kein me_controller gefunden.") end

local W,H=80,25
local running=true
local crafts={}
local filtered={}
local selected=1
local scroll=1
local search=""
local searchActive=false
local message="AE2 CRAFT SEARCH BEREIT"
local colors={bg=0x03060B,panel=0x0A111B,panel2=0x101C29,line=0x214057,cyan=0x35E8FF,pink=0xFF4CCB,green=0x35FF9A,yellow=0xFFE36A,red=0xFF466D,white=0xF3FAFF,grey=0x7D96AA,blue=0x438CFF}
local hit={}

local function safe(fn,...)
 local ok,a,b=pcall(fn,...)
 if ok then return a,b end
end

local function call(obj,name,...)
 if not obj or type(obj[name])~="function" then return nil end
 local ok,a,b=pcall(function(...) return obj[name](...) end,...)
 if ok then return a,b end
 ok,a,b=pcall(function(...) return obj[name](obj,...) end,...)
 if ok then return a,b end
end

local function text(x,y,s,fg,bg)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg or colors.white)
 gpu.setBackground(bg or colors.bg)
 gpu.set(x,y,tostring(s))
end

local function fit(s,n)
 s=tostring(s or "")
 if #s<=n then return s end
 return n<=1 and s:sub(1,1) or s:sub(1,n-1).."…"
end

local function box(x,y,w,h,title,color)
 gpu.setBackground(colors.panel);gpu.fill(x,y,w,h," ")
 gpu.setBackground(color or colors.cyan);gpu.fill(x,y,w,1," ")
 text(x+2,y,"◆ "..fit(title,w-5),colors.white,color or colors.cyan)
end

local function button(id,x,y,w,label,color,active)
 hit[id]={x=x,y=y,w=w,h=2}
 gpu.setBackground(active and colors.white or color)
 gpu.fill(x,y,w,2," ")
 text(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),active and color or colors.white,active and colors.white or color)
end

local function inside(id,x,y)
 local b=hit[id]
 return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function craftName(c)
 local s=call(c,"getItemStack")
 if type(s)=="table" then
  return tostring(s.label or s.displayName or s.name or s.id or s.item or "UNKNOWN RECIPE"),tonumber(s.size or s.amount or s.count or 1) or 1
 end
 return "UNKNOWN RECIPE",1
end

local function rebuild()
 filtered={}
 local q=string.lower(search)
 for i=1,#crafts do
  local n=craftName(crafts[i])
  if q=="" or string.lower(n):find(q,1,true) then filtered[#filtered+1]=i end
 end
 if #filtered==0 then selected=1 else selected=math.max(1,math.min(selected,#filtered)) end
 scroll=1
end

local function refresh()
 local c=safe(me.getCraftables)
 crafts=type(c)=="table" and c or {}
 rebuild()
 message="CRAFTABLES: "..#crafts
end

local function visibleCount()
 return math.max(1,H-12)
end

local function clamp()
 local v=visibleCount()
 if #filtered==0 then return end
 if selected<scroll then scroll=selected end
 if selected>scroll+v-1 then scroll=selected-v+1 end
 local max=math.max(1,#filtered-v+1)
 if scroll>max then scroll=max end
 if scroll<1 then scroll=1 end
end

local function draw()
 hit={}
 gpu.setBackground(colors.bg);gpu.fill(1,1,W,H," ")
 gpu.setBackground(colors.panel);gpu.fill(1,1,W,4," ")
 text(2,1,"╔ BULDACITY // AE2 CRAFTING ╗",colors.cyan,colors.panel)
 text(3,2,"CRAFTING SEARCH",colors.white,colors.panel)
 text(W-18,2,"ONLINE",colors.green,colors.panel)

 local y=5
 local left=math.max(40,math.floor(W*0.66))
 local right=W-left-5
 box(2,y,left,H-y-4,"CRAFTABLE RECIPES",colors.pink)

 -- Real search window: visible box + click target.
 local sx=4;local sy=y+2;local sw=left-4
 hit.search={x=sx,y=sy,w=sw,h=3}
 gpu.setBackground(searchActive and colors.panel2 or colors.bg)
 gpu.fill(sx,sy,sw,3," ")
 gpu.setBackground(searchActive and colors.cyan or colors.line)
 gpu.fill(sx,sy,sw,1," ")
 text(sx+2,sy+1,"🔎 SEARCH",searchActive and colors.cyan or colors.yellow,searchActive and colors.panel2 or colors.bg)
 text(sx+12,sy+1,fit(search,math.max(1,sw-16)),colors.white,searchActive and colors.panel2 or colors.bg)
 if searchActive then
  local cursor=sx+12+#search
  if cursor<sx+sw-1 then text(cursor,sy+1,"_",colors.cyan,colors.panel2) end
 end
 text(sx+2,sy+2,searchActive and "TIPPE SUCHTEXT • ENTER = CRAFT x1 • ESC = SCHLIESSEN" or "KLICKEN, DANN SUCHTEXT EINGEBEN",colors.grey,searchActive and colors.panel2 or colors.bg)

 text(5,y+6,string.format("%d / %d REZEPTE",#filtered,#crafts),colors.grey,colors.panel)
 local v=visibleCount();clamp()
 for p=scroll,math.min(#filtered,scroll+v-1) do
  local original=filtered[p]
  local n,a=craftName(crafts[original])
  local yy=y+7+(p-scroll)
  hit["row"..p]={x=4,y=yy,w=left-6,h=1}
  if p==selected then gpu.setBackground(colors.panel2);gpu.fill(4,yy,left-6,1," ") end
  text(6,yy,string.format("%02d",p),p==selected and colors.yellow or colors.cyan,colors.panel)
  text(11,yy,fit(n,math.max(8,left-24)),colors.white,colors.panel)
  text(12+math.max(8,left-24),yy,"x"..a,colors.pink,colors.panel)
 end
 if #filtered==0 then text(7,y+9,search=="" and "KEINE CRAFTBAREN REZEPTE" or "KEIN TREFFER",colors.red,colors.panel) end

 local x=left+4
 box(x,y,right,H-y-4,"CRAFT CONSOLE",colors.green)
 local n,a=craftName(crafts[filtered[selected]])
 text(x+3,y+3,"AUSGEWÄHLT",colors.grey,colors.panel)
 text(x+3,y+5,fit(n,math.max(8,right-6)),colors.white,colors.panel)
 text(x+3,y+7,"OUTPUT",colors.grey,colors.panel)
 text(x+3,y+8,"x"..a,colors.pink,colors.panel)
 button("craft1",x+3,y+10,math.max(8,right-6),"CRAFT x1",colors.cyan)
 button("craft16",x+3,y+12,math.max(8,right-6),"CRAFT x16",colors.blue)
 button("refresh",x+3,y+14,math.max(8,right-6),"SCAN",colors.yellow)

 local fy=H-3
 button("home",2,fy,12,"HOME",colors.blue)
 button("search",15,fy,15,"SEARCH",colors.pink,searchActive)
 button("craft",31,fy,15,"CRAFT",colors.green)
 button("exit",W-15,fy,14,"EXIT",colors.red)
 text(2,H,fit(message,math.max(1,W-4)),colors.grey,colors.bg)
end

local function doCraft(count)
 local original=filtered[selected]
 local c=original and crafts[original]
 if not c then message="KEIN REZEPT AUSGEWÄHLT";return end
 local n=craftName(c)
 local result,reason=call(c,"request",count,true)
 if result then message="CRAFT GESTARTET: "..n.." x"..count
 else message="CRAFT FEHLER: "..tostring(reason or "REQUEST FEHLGESCHLAGEN") end
end

local function searchKey(char,code)
 if code==1 then searchActive=false;message="SEARCH GESCHLOSSEN";return end
 if code==14 then
  if #search>0 then search=search:sub(1,#search-1);rebuild() end
  return
 end
 if code==28 then doCraft(1);return end
 if code==200 then selected=math.max(1,selected-1);clamp();return end
 if code==208 then selected=math.min(#filtered,selected+1);clamp();return end
 if char and char>=32 and char<=126 then
  search=search..string.char(char);rebuild();message="SUCHE: "..search
 end
end

refresh()
local mw,mh=safe(gpu.maxResolution)
local rw,rh=safe(gpu.getResolution)
W=rw or mw or 80;H=rh or mh or 25
draw()

while running do
 local e,a,b,c=event.pull(0.5)
 if e=="touch" then
  local x,y=b,c
  if inside("search",x,y) then searchActive=true;message="SEARCH AKTIV - JETZT TIPPEN"
  elseif inside("row"..selected,x,y) then searchActive=false
  elseif inside("craft1",x,y) then doCraft(1)
  elseif inside("craft16",x,y) then doCraft(16)
  elseif inside("refresh",x,y) then refresh()
  elseif inside("exit",x,y) then running=false
  elseif inside("search",x,y) then searchActive=true end
  draw()
 elseif e=="key_down" then
  local char=tonumber(b) or 0
  local code=tonumber(c) or 0
  if searchActive then searchKey(char,code)
  elseif code==200 then selected=math.max(1,selected-1);clamp()
  elseif code==208 then selected=math.min(#filtered,selected+1);clamp()
  elseif code==28 then doCraft(1)
  elseif char==27 or code==16 then running=false end
  draw()
 elseif e=="scroll" then
  local dir=tonumber(c) or 0
  if dir>0 then selected=math.max(1,selected-1) elseif dir<0 then selected=math.min(#filtered,selected+1) end
  clamp();draw()
 elseif e=="screen_resize" then
  W,H=safe(gpu.getResolution);W=W or 80;H=H or 25;draw()
 end
end
