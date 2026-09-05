-- BuldacityDesktop.lua
-- BULDACITY OS v10.2 - central Tier-3 fleet desktop.
-- Client discovery is active and fleet/device entries are touch clickable.
local component=require("component")
local event=require("event")
local computer=require("computer")
local network=require("Network")
local UI=require("BuldacityUI")
local gpu=component.gpu
local VERSION="10.2"
local PORT=4242
local page="DESKTOP"
local selected=1
local running=true
local dirty=true
local status="STARTING"
local devices={}
local frames={}
local frameSize={}
local reactor={}
local history={power={},temp={},fuel={}}

local function now()return computer.uptime()end
local function fit(s,n)return UI.fit(s,n)end
local function online(d)return d and now()-(tonumber(d.last)or 0)<12 end
local function merge(a,b)if type(b)=="table"then for k,v in pairs(b)do a[k]=v end end;return a end
local function listDevices()local r={};for _,d in pairs(devices)do r[#r+1]=d end;table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address)end);return r end
local function selectedDevice()local l=listDevices();if#l==0 then return nil end;selected=math.max(1,math.min(selected,#l));return l[selected]end
local function componentList(d)local r={};for _,c in ipairs((d and d.components)or{})do if type(c)=="table"then r[#r+1]=c end end;return r end

local function sync()
 local ok,diag=pcall(network.getDiagnostics)
 if ok and type(diag)=="table"then
  for a,d in pairs(diag)do devices[a]=merge(devices[a]or{address=a},d);devices[a].address=a end
 end
 local inv=_G.BuldacityComponents
 if type(inv)=="table"then
  for a,d in pairs(inv.clients or{})do devices[a]=merge(devices[a]or{address=a},d);devices[a].address=a;devices[a].componentCount=tonumber(d.count)or(type(d.components)=="table"and#d.components or 0)end
 end
 dirty=true
end

local function scan()
 status="DISCOVERY...";dirty=true
 local s=network.status()
 if(tonumber(s.modemCount)or 0)==0 then status="NO MODEM DETECTED";return end
 local ok,err=network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol=network.PROTOCOL,port=PORT,discover=true,scan=true,serverAddress=network.address()})
 status=ok and("DISCOVERY SENT // "..tostring(s.modemCount).." MODEM(S)")or("NETWORK ERROR: "..tostring(err))
 sync()
end

local function requestScreen(d)
 if d and online(d)then local ok,err=network.send(d.address,"SCREEN_REQUEST",{from="BULDACITY OS",version=VERSION});status=ok and"SCREEN REQUEST SENT"or("SCREEN ERROR: "..tostring(err));dirty=true end
end

local function desktop()
 UI.clear();UI.header("DESKTOP","FLEET COMMAND // BULDACITY OS "..VERSION,UI.C.cyan)
 local l=listDevices();local up=0;local linked=0;local comps=0
 for _,d in ipairs(l)do if online(d)then up=up+1 end;if d.linked then linked=linked+1 end;comps=comps+(tonumber(d.componentCount)or 0)end
 local cw=math.max(16,math.floor((UI.W-8)/4));local s=network.status()
 UI.card(2,6,cw,6,"network","ONLINE",up.." / "..#l,#l>0 and up/#l*100 or 0,UI.C.cyan)
 UI.card(3+cw,6,cw,6,"computer","LINKED",linked,#l>0 and linked/#l*100 or 0,UI.C.green)
 UI.card(4+cw*2,6,cw,6,"gear","COMPONENTS",comps,nil,UI.C.purple)
 UI.card(5+cw*3,6,cw,6,"network","MODEMS",tostring(s.modemCount or 0),s.modemCount and math.min(100,s.modemCount*25)or 0,UI.C.orange)
 UI.panel(2,14,UI.W-4,UI.H-18,"CLIENT FLEET // TOUCH TO SELECT",UI.C.green)
 if#l==0 then UI.icon(6,19,"network",UI.C.yellow,2);UI.text(15,19,"NO CLIENTS DISCOVERED",UI.C.yellow,UI.C.panel);UI.text(15,21,"R = DISCOVER   NETWORK = MODEM DIAGNOSTICS",UI.C.muted,UI.C.panel)end
 for i,d in ipairs(l)do local y=16+(i-1)*2;if y>UI.H-7 then break end;local a=i==selected;local c=online(d)and UI.C.green or UI.C.red
  UI.button("client"..i,4,y,UI.W-8,fit((d.name or"CLIENT").."  //  "..(d.app or d.controller or"CONTROLLER"),math.max(10,UI.W-10)),a and UI.C.cyan or c,a)
  UI.text(7,y,fit(d.name or"CLIENT",26),a and UI.C.cyan or UI.C.white, a and UI.C.panel2 or c)
  UI.text(math.min(35,UI.W-32),y,fit(d.mod or d.controller or d.app or"CONTROLLER",22),UI.C.muted,a and UI.C.panel2 or c)
  UI.text(math.min(61,UI.W-20),y,d.wireless and"WIRELESS"or"WIRED",d.wireless and UI.C.purple or UI.C.cyan,a and UI.C.panel2 or c)
  UI.text(math.min(77,UI.W-12),y,online(d)and"ONLINE"or"OFFLINE",c,a and UI.C.panel2 or c)
 end
 UI.statusLine("TOUCH CLIENT = SELECT   ENTER = REMOTE   R = SCAN   UP/DOWN   TAB   Q",UI.C.muted)
 UI.footer({{"home","HOME",UI.C.cyan,true},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple},{"pc","REMOTE",UI.C.green}})
end

local function appsPage()
 UI.clear();UI.header("APPS","APPLICATION CENTER // ALL CONNECTED PCs",UI.C.pink);local l=listDevices();UI.panel(2,6,UI.W-4,UI.H-11,"AVAILABLE CLIENT APPLICATIONS",UI.C.pink)
 if#l==0 then UI.text(15,11,"NO CLIENTS VISIBLE",UI.C.yellow,UI.C.panel)else for i,d in ipairs(l)do local y=9+(i-1)*3;if y>UI.H-8 then break end;local a=i==selected;local c=online(d)and UI.C.green or UI.C.red;UI.button("app"..i,4,y,UI.W-8,fit(d.name or d.app or"CLIENT",UI.W-10),a and UI.C.cyan or c,a);UI.text(14,y,fit(d.name or d.app or"CLIENT",30),a and UI.C.cyan or UI.C.white,a and UI.C.panel2 or c);UI.text(47,y,fit(d.mod or d.controller or d.app or"NETWORK CONTROLLER",24),UI.C.muted,a and UI.C.panel2 or c);UI.text(86,y,online(d)and"ONLINE"or"OFFLINE",c,a and UI.C.panel2 or c)end end
 UI.statusLine("TOUCH APP = SELECT   ENTER = REMOTE   R = RESCAN   UP/DOWN",UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink,true},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple},{"pc","REMOTE",UI.C.green}})
end

local function networkPage()
 UI.clear();UI.header("NETWORK","NETWORK DIAGNOSTICS // EVERY MODEM",UI.C.blue);local s=network.status();local l=listDevices();local ms=s.modems or{};local wc=0;for _,m in ipairs(ms)do if m.wireless then wc=wc+1 end end
 UI.card(2,6,24,7,"network","SERVER MODEMS",tostring(s.modemCount or 0),s.modemCount and math.min(100,s.modemCount*25)or 0,UI.C.cyan);UI.card(28,6,24,7,"network","WIRELESS",tostring(wc),wc>0 and 100 or 0,UI.C.purple);UI.card(54,6,24,7,"network","CLIENTS",tostring(#l),#l>0 and 100 or 0,UI.C.green)
 UI.panel(2,14,UI.W-4,UI.H-18,"MODEM INVENTORY",UI.C.blue);local y=17
 for i,m in ipairs(ms)do if y>UI.H-9 then break end;local c=m.open and UI.C.green or UI.C.red;UI.statusLed(5,y,m.open);UI.text(10,y,"M"..i,UI.C.white,UI.C.panel);UI.text(15,y,m.wireless and"WIRELESS"or"WIRED",m.wireless and UI.C.purple or UI.C.cyan,UI.C.panel);UI.text(30,y,"SIG "..tostring(m.strength or 0),UI.C.yellow,UI.C.panel);UI.text(43,y,"4242",UI.C.muted,UI.C.panel);UI.text(50,y,m.open and"READY"or"OPEN FAIL",c,UI.C.panel);UI.text(63,y,"@"..fit(m.address or"?",22),UI.C.cyan,UI.C.panel);y=y+2 end
 UI.text(5,math.min(UI.H-5,y+1),"DISCOVERED CLIENTS: "..tostring(#l),UI.C.green,UI.C.panel)
 UI.statusLine("R SCAN   TOUCH CLIENTS VIA DESKTOP/APPS   MODEM STATUS ABOVE",UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue,true},{"dev","DEVICES",UI.C.purple},{"scan","SCAN",UI.C.yellow}})
end

local function devicesPage()
 UI.clear();UI.header("DEVICES","COMPONENT EXPLORER // CLICKABLE",UI.C.purple);local l=listDevices();local d=selectedDevice();local left=math.floor(UI.W*.34);UI.panel(2,6,left,UI.H-10,"CLIENTS",UI.C.purple)
 for i,x in ipairs(l)do local y=8+(i-1)*2;if y>UI.H-6 then break end;UI.button("device"..i,4,y,left-4,fit(x.name or x.address,math.max(8,left-8)),i==selected and UI.C.cyan or UI.C.purple,i==selected)end
 local x=4+left;UI.panel(x,6,UI.W-x-2,UI.H-10,"COMPONENT INVENTORY",UI.C.cyan)
 if d then UI.text(x+3,9,"PC "..fit(d.address,30),UI.C.cyan,UI.C.panel);local cs=componentList(d);for i,c in ipairs(cs)do local y=12+(i-1)*2;if y>UI.H-5 then break end;UI.button("component"..i,x+2,y,UI.W-x-6,fit(c.type.."  //  "..c.address,UI.W-x-8),UI.C.cyan,false)end else UI.text(x+3,10,"NO CLIENT SELECTED",UI.C.yellow,UI.C.panel)end
 UI.statusLine("TOUCH CLIENT/COMPONENT   ENTER REMOTE   UP/DOWN CLIENT",UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple,true},{"pc","REMOTE",UI.C.green}})
end

local function remotePage()
 UI.clear();local d=selectedDevice();UI.header("REMOTE","LIVE PC // "..fit(d and d.name or"NONE",35),UI.C.pink);if not d then UI.text(6,10,"NO CLIENT DISCOVERED - PRESS R",UI.C.yellow);return end;if not online(d)then UI.text(6,10,"CLIENT OFFLINE",UI.C.red);return end
 local f=frames[d.address];local sz=frameSize[d.address]or{};UI.panel(2,6,UI.W-4,UI.H-11,"REMOTE SCREEN",UI.C.pink)
 if not f then UI.text(7,10,"WAITING FOR SCREEN DATA...",UI.C.yellow,UI.C.panel);UI.text(7,12,"Press R or ENTER to request the desktop.",UI.C.muted,UI.C.panel)else local maxY=math.min(UI.H-13,sz.height or#f);for yy=1,maxY do local row=f[yy];if type(row)=="table"then for xx,c in pairs(row)do if xx<UI.W-7 and type(c)=="table"then gpu.setForeground(c[2]or UI.C.white);gpu.setBackground(c[3]or UI.C.black);gpu.set(4+xx,7+yy,c[1]or" ")end end end end;UI.text(5,UI.H-4,string.format("REMOTE %sx%s | %s",sz.width or"?",sz.height or"?",d.address),UI.C.muted,UI.C.bg)end
 UI.statusLine("R REFRESH   Q BACK",UI.C.muted)
end

local function reactorPage()
 UI.clear();UI.header("REACTOR","LIVE TELEMETRY",UI.C.green);local r=reactor or{};local fuel=tonumber(r.fuelPercent or r.fuel or r.fuelLevel or 0)or 0;local temp=tonumber(r.temperature or r.temp or 0)or 0;local power=tonumber(r.power or r.rf or r.energy or 0)or 0;UI.card(2,6,24,7,"power","POWER",string.format("%.0f",power),power>0 and 100 or 0,UI.C.orange);UI.card(28,6,24,7,"reactor","TEMP",string.format("%.0f C",temp),math.min(100,temp/1000*100),UI.C.yellow);UI.card(54,6,24,7,"fluid","FUEL",string.format("%.1f%%",fuel),fuel,fuel<10 and UI.C.red or UI.C.green);UI.panel(2,15,UI.W-4,UI.H-19,"POWER HISTORY",UI.C.cyan);UI.graph(5,18,UI.W-10,UI.H-25,history.power,UI.C.orange);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple},{"rx","REACTOR",UI.C.green,true}})end

local function draw()UI.resize();if page=="DESKTOP"then desktop()elseif page=="APPS"then appsPage()elseif page=="NETWORK"then networkPage()elseif page=="DEVICES"then devicesPage()elseif page=="REMOTE"then remotePage()elseif page=="REACTOR"then reactorPage()else page="DESKTOP";desktop()end;dirty=false end

local function callback(sender,p,distance)
 if not network.valid(p)then return end
 local d=devices[sender]or{address=sender};local data=p.data or{};merge(d,data);d.address=sender;d.last=now();d.distance=tonumber(distance)or 0;d.wireless=d.distance>0 or data.wireless==true;d.link=d.wireless and"WIRELESS"or"WIRED"
 if p.kind=="LINK_CONFIRM"then d.linked=true;d.result="LINKED"elseif p.kind=="PONG"then d.lastPong=now();d.result="PASS";d.latency=d.pingSent and(now()-d.pingSent)*1000 or d.latency elseif p.kind=="COMPONENT_DATA"then d.componentCount=tonumber(data.count)or(type(data.components)=="table"and#data.components or 0);d.components=data.components or d.components;d.modems=data.modems or d.modems;d.result="COMPONENT DATA OK"elseif p.kind=="SCREEN_BEGIN"then frames[sender]={};frameSize[sender]=data elseif p.kind=="SCREEN_ROW"then frames[sender]=frames[sender]or{};frames[sender][tonumber(data.y)or 1]=data.cells elseif p.kind=="SCREEN_END"then status="REMOTE FRAME RECEIVED"end
 if type(data.reactor)=="table"then reactor=data.reactor end;devices[sender]=d;dirty=true
end

local ok,mode=network.startServer(callback);status=ok and"SERVER "..tostring(mode)or"SERVER ERROR: "..tostring(mode);scan();draw();event.timer(2,function()sync();dirty=true end,math.huge)
while running do
 local e,a,x,y,b=event.pull(0.25)
 if e=="touch"then
  if UI.hit("home",x,y)then page="DESKTOP"elseif UI.hit("apps",x,y)then page="APPS"elseif UI.hit("net",x,y)then page="NETWORK"elseif UI.hit("dev",x,y)then page="DEVICES"elseif UI.hit("pc",x,y)then page="REMOTE";requestScreen(selectedDevice())elseif UI.hit("rx",x,y)then page="REACTOR"elseif UI.hit("scan",x,y)then scan()
  elseif page=="DESKTOP"then local l=listDevices();for i=1,#l do if UI.hit("client"..i,x,y)then selected=i;page="DEVICES";break end end
  elseif page=="APPS"then local l=listDevices();for i=1,#l do if UI.hit("app"..i,x,y)then selected=i;page="REMOTE";requestScreen(selectedDevice());break end end
  elseif page=="DEVICES"then local l=listDevices();for i=1,#l do if UI.hit("device"..i,x,y)then selected=i;dirty=true;break end end
  end;dirty=true
 elseif e=="key_down"then local code=tonumber(y)or 0;if code==16 or code==17 then running=false elseif code==19 then scan()elseif code==28 then if page=="APPS"or page=="DESKTOP"or page=="DEVICES"then requestScreen(selectedDevice());page="REMOTE"elseif page=="REMOTE"then requestScreen(selectedDevice())end elseif code==15 then local p={"DESKTOP","APPS","NETWORK","DEVICES","REMOTE","REACTOR"};for i,v in ipairs(p)do if v==page then page=p[i%#p+1];break end end elseif code==200 then selected=math.max(1,selected-1);dirty=true elseif code==208 then selected=math.min(math.max(1,#listDevices()),selected+1);dirty=true end elseif e=="interrupted"then running=false end
 if dirty then draw()end
end
UI.clear()