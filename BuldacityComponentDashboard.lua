-- BuldacityComponentDashboard.lua
local component=require("component")
local event=require("event")
local computer=require("computer")
local UI=require("BuldacityUI")
local M={}
function M.run(cfg)
 local page="OVERVIEW";local devices={};local last=0;local running=true
 local function scan()
  devices={}
  for addr,typ in component.list() do
   local s=string.lower(tostring(typ));local ok=false
   for _,needle in ipairs(cfg.filters or {}) do if s:find(string.lower(needle),1,true) then ok=true;break end end
   if ok then local methods={};pcall(function() methods=component.methods(addr) or {} end);devices[#devices+1]={addr=addr,typ=tostring(typ),methods=methods} end
  end
 end
 local function draw()
  UI.clear();UI.header(cfg.title,cfg.subtitle,(cfg.accent or UI.C.cyan))
  local y=6;local w=UI.W>=90 and math.floor(UI.W*0.58) or UI.W-6
  UI.panel(3,y,w,UI.H-10,"DEVICE FLEET",cfg.accent or UI.C.cyan)
  UI.text(6,y+2,"LIVE COMPONENTS",UI.C.muted,UI.C.panel);UI.text(24,y+2,string.format("%02d detected",#devices),UI.C.green,UI.C.panel)
  local max=math.min(#devices,UI.H-y-7)
  for i=1,max do local d=devices[i];local yy=y+4+i-1;UI.text(6,yy,string.format("%02d",i),UI.C.muted,UI.C.panel);UI.text(10,yy,UI.fit(d.typ,24),UI.C.white,UI.C.panel);UI.text(36,yy,"@"..UI.fit(d.addr,20),UI.C.cyan,UI.C.panel);UI.text(59,yy,"● ONLINE",UI.C.green,UI.C.panel) end
  if w<UI.W-8 then local x=3+w+2;UI.panel(x,y,UI.W-x-2,UI.H-10,"SYSTEM",UI.C.purple);UI.text(x+3,y+3,"STATUS",UI.C.muted,UI.C.panel);UI.badge(x+3,y+4,#devices>0,"LINK ACTIVE",UI.C.green);UI.text(x+3,y+7,"SCAN RATE",UI.C.muted,UI.C.panel);UI.text(x+3,y+8,"2 SEC",UI.C.cyan,UI.C.panel);UI.text(x+3,y+11,"PAGE",UI.C.muted,UI.C.panel);UI.text(x+3,y+12,page,UI.C.white,UI.C.panel) end
  UI.footer({{"scan","SCAN",UI.C.yellow},{"overview","OVERVIEW",cfg.accent or UI.C.cyan,page=="OVERVIEW"},{"api","API",UI.C.purple,page=="API"},{"exit","EXIT",UI.C.red}})
  if page=="API" then
   UI.panel(3,6,UI.W-6,UI.H-10,"COMPONENT API",UI.C.purple);local yy=8
   for i=1,math.min(#devices,UI.H-10) do local d=devices[i];UI.text(5,yy,UI.fit(d.typ,22),UI.C.white,UI.C.panel);local n=0;for name,_ in pairs(d.methods) do if n<3 then UI.text(29+n*16,yy,UI.fit(name,14),UI.C.cyan,UI.C.panel);n=n+1 end end;yy=yy+2 end
  end
  UI.text(2,UI.H,string.format("BULDACITY // %s // %d component(s)",cfg.id or "DEVICE",#devices),UI.C.muted,UI.C.bg)
 end
 scan();draw()
 while running do
  if computer.uptime()-last>=2 then last=computer.uptime();scan();draw() end
  local e={event.pull(1)}
  if e[1]=="key_down" then local c=e[3];if c==16 or c==28 then running=false elseif c==19 then scan();draw() elseif c==30 then page="OVERVIEW";draw() elseif c==48 then page="API";draw() end
  elseif e[1]=="touch" then local x,y=e[3],e[4];if UI.hit("scan",x,y) then scan();draw() elseif UI.hit("overview",x,y) then page="OVERVIEW";draw() elseif UI.hit("api",x,y) then page="API";draw() elseif UI.hit("exit",x,y) then running=false end
  elseif e[1]=="interrupted" then running=false end
 end
 UI.clear()
end
return M
