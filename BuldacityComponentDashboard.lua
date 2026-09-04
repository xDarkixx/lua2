-- BuldacityComponentDashboard.lua
local component=require("component")
local event=require("event")
local computer=require("computer")
local UI=require("BuldacityUI")
local M={}
function M.run(cfg)
 local page="OVERVIEW";local devices={};local last=0;local running=true;cfg=cfg or{}
 local accent=cfg.accent or UI.C.cyan
 local function scan()
  devices={}
  for addr,typ in component.list() do
   local s=string.lower(tostring(typ));local ok=(not cfg.filters or #cfg.filters==0)
   if not ok then for _,needle in ipairs(cfg.filters)do if s:find(string.lower(needle),1,true)then ok=true;break end end end
   if ok then local methods={};pcall(function()methods=component.methods(addr)or{}end);devices[#devices+1]={addr=addr,typ=tostring(typ),methods=methods}end
  end
  table.sort(devices,function(a,b)return a.typ..a.addr<b.typ..b.addr end)
 end
 local function draw()
  UI.clear();UI.header(cfg.title or"COMPONENT CENTER",cfg.subtitle or"LIVE COMPONENT INVENTORY // GPU HUD",accent)
  if page=="API"then
   UI.panel(2,6,UI.W-4,UI.H-10,"COMPONENT API / METHODS",UI.C.purple);local yy=8
   for i=1,#devices do local d=devices[i];if yy>UI.H-5 then break end;UI.icon(5,yy,d.typ,UI.C.purple);UI.text(10,yy,UI.fit(d.typ,18),UI.C.white,UI.C.panel);UI.text(29,yy,UI.fit(d.addr,22),UI.C.cyan,UI.C.panel);local names={};for n,_ in pairs(d.methods)do names[#names+1]=tostring(n)end;table.sort(names);UI.text(53,yy,UI.fit(table.concat(names,", "),UI.W-55),UI.C.muted,UI.C.panel);yy=yy+2 end
  else
   local w=UI.W>=100 and math.floor(UI.W*.62)or UI.W-6;UI.panel(2,6,w,UI.H-10,"DEVICE FLEET",accent);UI.text(5,8,"LIVE COMPONENTS",UI.C.muted,UI.C.panel);UI.text(25,8,string.format("%02d detected",#devices),UI.C.green,UI.C.panel)
   local max=math.min(#devices,UI.H-15);for i=1,max do local d=devices[i];local yy=10+i-1;UI.icon(5,yy,d.typ,accent);UI.text(10,yy,UI.fit(d.typ,20),UI.C.white,UI.C.panel);UI.text(32,yy,"@"..UI.fit(d.addr,22),UI.C.cyan,UI.C.panel);UI.text(57,yy,"● ONLINE",UI.C.green,UI.C.panel)end
   if w<UI.W-8 then local x=4+w;UI.panel(x,6,UI.W-x-2,UI.H-10,"GRAPHICS",UI.C.purple);UI.icon(x+4,9,"computer",UI.C.cyan,2);UI.text(x+4,15,"COMPONENTS",UI.C.muted,UI.C.panel);UI.text(x+4,16,tostring(#devices),UI.C.white,UI.C.panel);UI.bar(x+4,18,math.max(8,UI.W-x-8),math.min(100,#devices*10),accent);UI.text(x+4,20,"SCAN",UI.C.muted,UI.C.panel);UI.text(x+4,21,"2 SEC",UI.C.cyan,UI.C.panel)end
  end
  UI.statusLine(string.format("BULDACITY // %s // %d component(s)",cfg.id or"DEVICE",#devices),UI.C.muted)
  UI.footer({{"scan","SCAN",UI.C.yellow},{"overview","OVERVIEW",accent,page=="OVERVIEW"},{"api","API",UI.C.purple,page=="API"},{"exit","EXIT",UI.C.red}})
 end
 scan();draw()
 while running do
  if computer.uptime()-last>=2 then last=computer.uptime();scan();draw()end
  local e={event.pull(1)}
  if e[1]=="key_down"then local c=e[3];if c==16 or c==28 then running=false elseif c==19 then scan();draw()elseif c==30 then page="OVERVIEW";draw()elseif c==48 then page="API";draw()end
  elseif e[1]=="touch"then local x,y=e[3],e[4];if UI.hit("scan",x,y)then scan();draw()elseif UI.hit("overview",x,y)then page="OVERVIEW";draw()elseif UI.hit("api",x,y)then page="API";draw()elseif UI.hit("exit",x,y)then running=false end
  elseif e[1]=="interrupted"then running=false end
 end
 UI.clear()
end
return M
