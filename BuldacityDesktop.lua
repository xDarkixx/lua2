-- BuldacityDesktop.lua
-- BULDACITY OS v10 - central Tier-3 fleet desktop.
-- Includes DESKTOP, APPS, NETWORK, DEVICES, REMOTE and REACTOR pages.
local component=require("component")
local event=require("event")
local computer=require("computer")
local shell=require("shell")
local network=require("Network")
local UI=require("BuldacityUI")
local gpu=component.gpu
local HOME="/home/"
local PORT=4242
local VERSION="10.0"
pcall(function()shell.setWorkingDirectory(HOME)end)
package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")
local page="DESKTOP";local selected=1;local componentSelected=1;local running=true;local dirty=true;local status="STARTING";local devices={};local frames={};local frameSize={};local reactor={};local history={power={},temp={},fuel={}}
local function now()return computer.uptime()end
local function fit(s,n)return UI.fit(s,n)end
local function online(d)return d and now()-(tonumber(d.last)or 0)<12 end
local function merge(a,b)if type(b)=="table"then for k,v in pairs(b)do a[k]=v end end;return a end
local function listDevices()local r={};for _,d in pairs(devices)do r[#r+1]=d end;table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address)end);return r end
local function selectedDevice()local l=listDevices();if#l==0 then return nil end;selected=math.max(1,math.min(selected,#l));return l[selected]end
local function componentList(d)local r={};for _,c in ipairs((d and d.components)or{})do if type(c)=="table"then r[#r+1]=c end end;table.sort(r,function(a,b)return tostring(a.type)..tostring(a.address)<tostring(b.type)..tostring(b.address)end);return r end
local function sync()
 local ok,diag=pcall(network.getDiagnostics);if ok and type(diag)=="table"then for a,d in pairs(diag)do devices[a]=merge(devices[a]or{address=a},d);devices[a].address=a end end
 local inv=_G.BuldacityComponents;if type(inv)=="table"then for a,d in pairs(inv.clients or{})do devices[a]=merge(devices[a]or{address=a},d);devices[a].address=a;devices[a].componentCount=tonumber(d.count)or(type(d.components)=="table"and#d.components or 0)end end
 dirty=true
end
local function scan()
 sync();local ok,err=network.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,protocol=network.PROTOCOL,port=PORT,discover=true});status=ok and "DISCOVERY SENT" or "NETWORK ERROR: "..tostring(err)
 for _,d in ipairs(listDevices())do if online(d)then d.pingSent=now();network.send(d.address,"PING",{from="BULDACITY OS",id=tostring(d.pingSent)})end end;dirty=true
end
local function requestScreen(d)if d and online(d)then local ok,err=network.send(d.address,"SCREEN_REQUEST",{from="BULDACITY OS",version=VERSION});status=ok and "SCREEN REQUEST SENT" or "SCREEN ERROR: "..tostring(err)end end
local function appsPage()
 UI.clear();UI.header("APPS","APPLICATION CENTER // ALL CONNECTED PCs",UI.C.pink)
 local l=listDevices();UI.panel(2,6,UI.W-4,UI.H-11,"AVAILABLE CLIENT APPLICATIONS",UI.C.pink)
 if#l==0 then UI.icon(6,11,"network",UI.C.yellow,2);UI.text(15,11,"NO CLIENTS VISIBLE",UI.C.yellow,UI.C.panel);UI.text(15,13,"Press R to broadcast discovery.",UI.C.muted,UI.C.panel);UI.text(15,15,"Check Network page for modem / relay status.",UI.C.muted,UI.C.panel)
 else for i,d in ipairs(l)do local y=9+(i-1)*3;if y>UI.H-8 then break end;local active=i==selected;local c=online(d)and UI.C.green or UI.C.red;if active then UI.rect(4,y,UI.W-8,3,UI.C.panel2);UI.rect(4,y,2,3,UI.C.pink)end;UI.icon(8,y,d.wireless and"network"or"computer",active and UI.C.cyan or c);UI.text(14,y,fit(d.name or d.app or "CLIENT",30),active and UI.C.cyan or UI.C.white,UI.C.panel2);UI.text(47,y,fit(d.mod or d.controller or d.app or "NETWORK CONTROLLER",24),UI.C.muted,UI.C.panel2);UI.text(73,y,d.link or(d.wireless and"WIRELESS"or"WIRED"),d.wireless and UI.C.purple or UI.C.cyan,UI.C.panel2);UI.text(86,y,online(d)and"ONLINE"or"OFFLINE",c,UI.C.panel2);UI.text(101,y,"[ENTER] OPEN",UI.C.yellow,UI.C.panel2)end end
 UI.statusLine("UP/DOWN SELECT   ENTER OPEN REMOTE DESKTOP   R RESCAN   Q EXIT",UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink,true},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple},{"pc","REMOTE",UI.C.green}})
end
local function desktop()
 UI.clear();UI.header("DESKTOP","FLEET COMMAND // BULDACITY OS "..VERSION,UI.C.cyan);local l=listDevices();local up=0;local linked=0;local comps=0;for _,d in ipairs(l)do if online(d)then up=up+1 end;if d.linked then linked=linked+1 end;comps=comps+(tonumber(d.componentCount)or 0)end
 local cw=math.max(16,math.floor((UI.W-8)/4));UI.card(2,6,cw,6,"network","ONLINE",up.." / "..#l,#l>0 and up/#l*100 or 0,UI.C.cyan);UI.card(3+cw,6,cw,6,"computer","LINKED",linked,#l>0 and linked/#l*100 or 0,UI.C.green);UI.card(4+cw*2,6,cw,6,"gear","COMPONENTS",comps,nil,UI.C.purple);UI.card(5+cw*3,6,cw,6,"power","NETWORK",network.status().wireless and"WIRELESS"or"WIRED",100,UI.C.orange)
 UI.panel(2,14,UI.W-4,UI.H-18,"CLIENT FLEET",UI.C.green);if#l==0 then UI.text(7,19,"NO CLIENTS DISCOVERED",UI.C.yellow,UI.C.panel);UI.text(7,21,"R = broadcast discovery",UI.C.muted,UI.C.panel)end
 for i,d in ipairs(l)do local y=16+(i-1)*2;if y>UI.H-7 then break end;local a=i==selected;local c=online(d)and UI.C.green or UI.C.red;if a then UI.rect(4,y,UI.W-8,2,UI.C.panel2)end;UI.icon(7,y,d.wireless and"network"or"computer",a and UI.C.cyan or c);UI.text(12,y,fit(d.name or"CLIENT",28),a and UI.C.cyan or UI.C.white,UI.C.panel2);UI.text(42,y,fit(d.mod or d.controller or d.app or"CONTROLLER",25),UI.C.muted,UI.C.panel2);UI.text(70,y,d.link or"--",d.wireless and UI.C.purple or UI.C.cyan,UI.C.panel2);UI.text(82,y,tostring(d.componentCount or 0).." C",UI.C.purple,UI.C.panel2);UI.text(92,y,online(d)and"●"or"○",c,UI.C.panel2)end
 UI.statusLine("R SCAN   ENTER REMOTE   TAB APPS   UP/DOWN CLIENT   Q EXIT",UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan,true},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple},{"pc","REMOTE",UI.C.green}})
end
local function networkPage()
 UI.clear();UI.header("NETWORK","LINK MATRIX // MULTI-MODEM",UI.C.blue);local s=network.status();local l=listDevices();UI.card(2,6,24,7,"network","MODEMS",s.wireless and"WIRED+WIRELESS"or"WIRED",s.wirelessStrength and math.min(100,s.wirelessStrength/4)or 0,UI.C.cyan);UI.card(28,6,24,7,"network","RELAY",s.relayPathType,s.relayDetected and 100 or 0,UI.C.orange);UI.card(54,6,24,7,"network","CLIENTS",#l,#l>0 and 100 or 0,UI.C.green);UI.panel(2,15,UI.W-4,UI.H-19,"DIAGNOSTICS",UI.C.blue);UI.text(5,18,"PORT",UI.C.muted,UI.C.panel);UI.text(18,18,tostring(PORT),UI.C.cyan,UI.C.panel);UI.text(30,18,"PROTOCOL",UI.C.muted,UI.C.panel);UI.text(42,18,network.PROTOCOL,UI.C.cyan,UI.C.panel);UI.text(5,20,"WIRELESS",UI.C.muted,UI.C.panel);UI.text(18,20,s.wirelessReady and"READY"or"NOT READY",s.wirelessReady and UI.C.green or UI.C.red,UI.C.panel);UI.text(30,20,"STRENGTH",UI.C.muted,UI.C.panel);UI.text(42,20,tostring(s.wirelessStrength),UI.C.yellow,UI.C.panel);UI.text(5,22,"RELAYS",UI.C.muted,UI.C.panel);UI.text(18,22,tostring(s.relayCount),UI.C.orange,UI.C.panel);UI.text(30,22,"ACCESS POINTS",UI.C.muted,UI.C.panel);UI.text(48,22,tostring(s.accessPointCount),UI.C.orange,UI.C.panel);UI.text(5,25,"R = DISCOVERY BROADCAST",UI.C.yellow,UI.C.panel);UI.text(5,27,"All attached modems are now opened and used for send/broadcast.",UI.C.muted,UI.C.panel);UI.statusLine(status,UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue,true},{"dev","DEVICES",UI.C.purple},{"scan","SCAN",UI.C.yellow}})
end
local function devicesPage()
 UI.clear();UI.header("DEVICES","COMPONENT EXPLORER // HARDWARE IDs",UI.C.purple);local l=listDevices();local d=selectedDevice();local left=math.floor(UI.W*.34);UI.panel(2,6,left,UI.H-10,"CLIENTS",UI.C.purple);for i,x in ipairs(l)do local y=8+(i-1)*2;if y>UI.H-6 then break end;if i==selected then UI.rect(4,y,left-4,2,UI.C.panel2)end;UI.text(7,y,fit(x.name or x.address,24),i==selected and UI.C.cyan or UI.C.white,UI.C.panel2)end;local x=4+left;UI.panel(x,6,UI.W-x-2,UI.H-10,"COMPONENT INVENTORY",UI.C.cyan);if d then UI.text(x+3,9,"PC "..fit(d.address,30),UI.C.cyan,UI.C.panel);for i,c in ipairs(componentList(d))do local y=12+(i-1)*2;if y>UI.H-5 then break end;UI.icon(x+4,y,c.type,i==componentSelected and UI.C.cyan or UI.C.muted);UI.text(x+9,y,fit(c.type,18),UI.C.white,UI.C.panel);UI.text(x+29,y,fit(c.address,32),UI.C.cyan,UI.C.panel)end else UI.text(x+3,10,"NO CLIENT SELECTED",UI.C.yellow,UI.C.panel)end;UI.statusLine("UP/DOWN CLIENT   LEFT/RIGHT COMPONENT   ENTER REMOTE",UI.C.muted);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple,true},{"pc","REMOTE",UI.C.green}})
end
local function remotePage()
 UI.clear();local d=selectedDevice();UI.header("REMOTE","LIVE PC // "..fit(d and d.name or"NONE",35),UI.C.pink);if not d then UI.text(6,10,"No client discovered. Press R.",UI.C.yellow);return end;if not online(d)then UI.text(6,10,"CLIENT OFFLINE",UI.C.red);return end;local f=frames[d.address];local sz=frameSize[d.address]or{};UI.panel(2,6,UI.W-4,UI.H-11,"REMOTE SCREEN",UI.C.pink);if not f then UI.text(7,10,"Waiting for screen data...",UI.C.yellow,UI.C.panel);UI.text(7,12,"Press R to request the desktop.",UI.C.muted,UI.C.panel);return end;local maxY=math.min(UI.H-13,sz.height or #f);for y=1,maxY do local row=f[y];if type(row)=="table"then for x,c in pairs(row)do if x<UI.W-7 and type(c)=="table"then gpu.setForeground(c[2]or UI.C.white);gpu.setBackground(c[3]or UI.C.black);gpu.set(4+x,7+y,c[1]or" ")end end end end;UI.text(5,UI.H-4,string.format("REMOTE %sx%s | %s",sz.width or"?",sz.height or"?",d.address),UI.C.muted,UI.C.bg);UI.statusLine("R REFRESH   Q BACK",UI.C.muted)
end
local function reactorPage()UI.clear();UI.header("REACTOR","LIVE TELEMETRY",UI.C.green);local r=reactor or{};local fuel=tonumber(r.fuelPercent or r.fuel or r.fuelLevel or 0)or 0;local temp=tonumber(r.temperature or r.temp or 0)or 0;local power=tonumber(r.power or r.rf or r.energy or 0)or 0;UI.card(2,6,24,7,"power","POWER",string.format("%.0f",power),power>0 and 100 or 0,UI.C.orange);UI.card(28,6,24,7,"reactor","TEMP",string.format("%.0f C",temp),math.min(100,temp/1000*100),UI.C.yellow);UI.card(54,6,24,7,"fluid","FUEL",string.format("%.1f%%",fuel),fuel,fuel<10 and UI.C.red or UI.C.green);UI.panel(2,15,UI.W-4,UI.H-19,"POWER HISTORY",UI.C.cyan);UI.graph(5,18,UI.W-10,UI.H-25,history.power,UI.C.orange);UI.footer({{"home","HOME",UI.C.cyan},{"apps","APPS",UI.C.pink},{"net","NETWORK",UI.C.blue},{"dev","DEVICES",UI.C.purple},{"rx","REACTOR",UI.C.green,true}})end
local function draw()UI.resize();if UI.W>160 then pcall(gpu.setResolution,160,50);UI.resize()end;if page=="DESKTOP"then desktop()elseif page=="APPS"then appsPage()elseif page=="NETWORK"then networkPage()elseif page=="DEVICES"then devicesPage()elseif page=="REMOTE"then remotePage()elseif page=="REACTOR"then reactorPage()end;dirty=false end
local function callback(sender,p,distance)
 if not network.valid(p)then return end;local d=devices[sender]or{address=sender};local data=p.data or{};merge(d,data);d.address=sender;d.last=now();d.distance=tonumber(distance)or 0;d.wireless=d.distance>0 or data.wireless==true;d.link=d.wireless and"WIRELESS"or"WIRED";if p.kind=="LINK_CONFIRM"then d.linked=true end;if p.kind=="PONG"then d.lastPong=now();d.latency=d.pingSent and(now()-d.pingSent)*1000 or d.latency end;if p.kind=="COMPONENT_DATA"then d.componentCount=tonumber(data.count)or(type(data.components)=="table"and#data.components or 0)end;if p.kind=="SCREEN_BEGIN"then frames[sender]={};frameSize[sender]=data elseif p.kind=="SCREEN_ROW"then frames[sender]=frames[sender]or{};frames[sender][tonumber(data.y)or 1]=data.cells elseif p.kind=="SCREEN_END"then status="REMOTE FRAME RECEIVED"end;if type(data.reactor)=="table"then reactor=data.reactor end;dirty=true
end
local ok,mode=network.startServer(callback);status=ok and "SERVER "..tostring(mode)or"SERVER ERROR: "..tostring(mode);scan();draw()
event.timer(2,function()sync();dirty=true end,math.huge)
while running do
 local e,a,x,y,b=event.pull(0.25)
 if e=="touch"then
  if UI.hit("home",x,y)then page="DESKTOP"elseif UI.hit("apps",x,y)then page="APPS"elseif UI.hit("net",x,y)then page="NETWORK"elseif UI.hit("dev",x,y)then page="DEVICES"elseif UI.hit("pc",x,y)then page="REMOTE";requestScreen(selectedDevice())elseif UI.hit("rx",x,y)then page="REACTOR"elseif UI.hit("scan",x,y)then scan()end;dirty=true
 elseif e=="key_down"then local code=y
  if code==16 or code==17 then running=false
  elseif code==19 then scan()
  elseif code==28 then if page=="APPS"or page=="DESKTOP"or page=="DEVICES"then requestScreen(selectedDevice());page="REMOTE"elseif page=="REMOTE"then requestScreen(selectedDevice())end
  elseif code==15 then local p={"DESKTOP","APPS","NETWORK","DEVICES","REMOTE","REACTOR"};for i,v in ipairs(p)do if v==page then page=p[i%#p+1]end end
  elseif code==200 then selected=math.max(1,selected-1);dirty=true
  elseif code==208 then selected=math.min(math.max(1,#listDevices()),selected+1);dirty=true
  elseif code==203 and page=="DEVICES"then componentSelected=math.max(1,componentSelected-1);dirty=true
  elseif code==205 and page=="DEVICES"then local n=#componentList(selectedDevice());componentSelected=math.min(math.max(1,n),componentSelected+1);dirty=true
  elseif code==18 and page=="APPS"then page="APPS";scan()
  end
 elseif e=="interrupted"then running=false end
 if dirty then draw()end
end
UI.clear()
