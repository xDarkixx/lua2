-- BuldacityComponentDashboard.lua
-- BULDACITY graphical local hardware + modem diagnostic dashboard.
local component=require("component")
local event=require("event")
local computer=require("computer")
local UI=require("BuldacityUI")
local M={}
function M.run(cfg)
 cfg=cfg or{};local page="OVERVIEW";local devices={};local last=0;local running=true;local scanState="READY";local accent=cfg.accent or UI.C.cyan
 local function scan()
  devices={};local ms={}
  for a,k in component.list("modem",true)do local m=component.proxy(a);if m then local wireless=type(m.getStrength)=="function"or type(m.setStrength)=="function";local strength=0;if wireless and type(m.setStrength)=="function"then pcall(function()m.setStrength(400)end)end;if wireless and type(m.getStrength)=="function"then pcall(function()strength=m.getStrength()or 0 end)end;local opened=pcall(function()m.open(4242)end);ms[#ms+1]={addr=a,typ=tostring(k),wireless=wireless,strength=tonumber(strength)or 0,opened=opened}end end
  for addr,typ in component.list()do local s=tostring(typ):lower();local ok=(not cfg.filters or#cfg.filters==0);if not ok then for _,needle in ipairs(cfg.filters)do if s:find(tostring(needle):lower(),1,true)then ok=true;break end end end;if ok then local methods={};pcall(function()methods=component.methods(addr)or{}end);devices[#devices+1]={addr=addr,typ=tostring(typ),methods=methods}end end
  table.sort(devices,function(a,b)return a.typ..a.addr<b.typ..b.addr end);return ms
 end
 local modems=scan()
 local function draw()
  UI.clear();UI.header(cfg.title or"BULDACITY DIAGNOSTICS",cfg.subtitle or"LOCAL HARDWARE // MODEM MATRIX // PORT 4242",accent)
  if page=="MODEMS"then
   UI.panel(2,6,UI.W-4,UI.H-10,"ALL ATTACHED MODEMS",UI.C.blue);UI.text(5,8,"COUNT",UI.C.muted,UI.C.panel);UI.text(13,8,tostring(#modems),UI.C.cyan,UI.C.panel);UI.text(25,8,"PORT",UI.C.muted,UI.C.panel);UI.text(32,8,"4242",UI.C.cyan,UI.C.panel);local y=11
   for i,m in ipairs(modems)do if y>UI.H-5 then break end;local c=m.opened and UI.C.green or UI.C.red;UI.statusLed(5,y,m.opened);UI.text(9,y,"MODEM "..i,UI.C.white,UI.C.panel);UI.text(19,y,m.wireless and"WIRELESS"or"WIRED",m.wireless and UI.C.purple or UI.C.cyan,UI.C.panel);UI.text(32,y,"SIG "..tostring(m.strength),UI.C.yellow,UI.C.panel);UI.text(44,y,"PORT 4242",UI.C.muted,UI.C.panel);UI.text(55,y,m.opened and"READY"or"OPEN FAILED",c,UI.C.panel);UI.text(69,y,"@"..UI.fit(m.addr,35),UI.C.cyan,UI.C.panel);y=y+2 end
   if#modems==0 then UI.icon(6,12,"network",UI.C.red,2);UI.text(15,12,"NO MODEM DETECTED",UI.C.red,UI.C.panel);UI.text(15,14,"Install a wired or wireless modem and restart the controller.",UI.C.yellow,UI.C.panel)end
  elseif page=="API"then
   UI.panel(2,6,UI.W-4,UI.H-10,"COMPONENT API / METHODS",UI.C.purple);local yy=8;for _,d in ipairs(devices)do if yy>UI.H-5 then break end;UI.icon(5,yy,d.typ,UI.C.purple);UI.text(10,yy,UI.fit(d.typ,18),UI.C.white,UI.C.panel);UI.text(29,yy,UI.fit(d.addr,22),UI.C.cyan,UI.C.panel);local names={};for n,_ in pairs(d.methods)do names[#names+1]=tostring(n)end;table.sort(names);UI.text(53,yy,UI.fit(table.concat(names,", "),UI.W-55),UI.C.muted,UI.C.panel);yy=yy+2 end
  else
   local w=UI.W>=100 and math.floor(UI.W*.62)or UI.W-6;UI.panel(2,6,w,UI.H-10,"LOCAL HARDWARE",accent);UI.text(5,8,"COMPONENTS",UI.C.muted,UI.C.panel);UI.text(18,8,tostring(#devices),UI.C.green,UI.C.panel);UI.text(30,8,"MODEMS",UI.C.muted,UI.C.panel);UI.text(39,8,tostring(#modems),#modems>0 and UI.C.green or UI.C.red,UI.C.panel);local max=math.min(#devices,UI.H-15);for i=1,max do local d=devices[i];local yy=10+i-1;UI.icon(5,yy,d.typ,accent);UI.text(10,yy,UI.fit(d.typ,20),UI.C.white,UI.C.panel);UI.text(32,yy,"@"..UI.fit(d.addr,22),UI.C.cyan,UI.C.panel);UI.text(57,yy,"ONLINE",UI.C.green,UI.C.panel)end;local x=4+w;UI.panel(x,6,UI.W-x-2,UI.H-10,"MODEM STATUS",UI.C.blue);UI.text(x+4,9,"MODEMS",UI.C.muted,UI.C.panel);UI.text(x+14,9,tostring(#modems),#modems>0 and UI.C.green or UI.C.red,UI.C.panel);local wireless=0;for _,m in ipairs(modems)do if m.wireless then wireless=wireless+1 end end;UI.text(x+4,11,"WIRELESS",UI.C.muted,UI.C.panel);UI.text(x+14,11,tostring(wireless),wireless>0 and UI.C.purple or UI.C.muted,UI.C.panel);UI.text(x+4,13,"4242",UI.C.muted,UI.C.panel);UI.text(x+14,13,#modems>0 and"OPEN"or"CLOSED",#modems>0 and UI.C.green or UI.C.red,UI.C.panel);UI.text(x+4,16,"SCAN",UI.C.yellow,UI.C.panel);UI.text(x+4,18,scanState,UI.C.cyan,UI.C.panel)end
  UI.statusLine(string.format("BULDACITY // %s // %d component(s) // %d modem(s)",cfg.id or"DEVICE",#devices,#modems),UI.C.muted);UI.footer({{"scan","SCAN",UI.C.yellow},{"overview","OVERVIEW",accent,page=="OVERVIEW"},{"modems","MODEMS",UI.C.blue,page=="MODEMS"},{"api","API",UI.C.purple,page=="API"},{"exit","EXIT",UI.C.red}})
 end
 draw()
 while running do
  if computer.uptime()-last>=2 then last=computer.uptime();modems=scan();scanState=#modems>0 and"MODEMS READY"or"NO MODEM";draw()end
  local e={event.pull(1)}
  if e[1]=="key_down"then local c=e[3];if c==16 or c==28 then running=false elseif c==19 then modems=scan();scanState=#modems>0 and"SCAN PASS"or"NO MODEM";draw()elseif c==30 then page="OVERVIEW";draw()elseif c==48 then page="API";draw()elseif c==50 then page="MODEMS";draw()end elseif e[1]=="touch"then local x,y=e[3],e[4];if UI.hit("scan",x,y)then modems=scan();scanState=#modems>0 and"SCAN PASS"or"NO MODEM";draw()elseif UI.hit("overview",x,y)then page="OVERVIEW";draw()elseif UI.hit("modems",x,y)then page="MODEMS";draw()elseif UI.hit("api",x,y)then page="API";draw()elseif UI.hit("exit",x,y)then running=false end elseif e[1]=="interrupted"then running=false end
 end
 UI.clear()
end
return M
