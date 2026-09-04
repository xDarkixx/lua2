-- BuldacityApps_Modern.lua
-- BULDACITY OS // standalone Remote PC & App Center v10
local component=require("component")
local event=require("event")
local computer=require("computer")
local shell=require("shell")
local network=require("Network")
local UI=require("BuldacityUI")
local gpu=component.gpu
local HOME="/home/";local PORT=4242
pcall(function()shell.setWorkingDirectory(HOME)end);package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")
local devices={};local frames={};local sizes={};local selected=1;local mode="APPS";local dirty=true;local running=true;local status="STARTING"
local function now()return computer.uptime()end
local function online(d)return d and now()-(tonumber(d.last)or 0)<12 end
local function fit(s,n)return UI.fit(s,n)end
local function merge(a,b)if type(b)=="table"then for k,v in pairs(b)do a[k]=v end end;return a end
local function list()local r={};for _,d in pairs(devices)do r[#r+1]=d end;table.sort(r,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address)end);return r end
local function sel()local l=list();if#l==0 then return nil end;selected=math.max(1,math.min(selected,#l));return l[selected]end
local function sync()
 local ok,diag=pcall(network.getDiagnostics);if ok and type(diag)=="table"then for a,d in pairs(diag)do devices[a]=merge(devices[a]or{address=a},d)end end
 local inv=_G.BuldacityComponents;if type(inv)=="table"then for a,d in pairs(inv.clients or{})do devices[a]=merge(devices[a]or{address=a},d);devices[a].address=a end end;dirty=true
end
local function discover()local ok,err=network.broadcast("SERVER_HELLO",{name="BULDACITY APP CENTER",role="SERVER",app="BULDACITY APP CENTER",protocol=network.PROTOCOL,port=PORT,discover=true});status=ok and"DISCOVERY SENT"or"NETWORK ERROR: "..tostring(err);sync()end
local function request(d)if d and online(d)then local ok,err=network.send(d.address,"SCREEN_REQUEST",{from="BULDACITY APP CENTER",live=true});status=ok and"SCREEN REQUEST SENT"or"SCREEN ERROR: "..tostring(err)end end
local function top()UI.clear();UI.header("APPS","APPLICATION CENTER // REMOTE PCs",UI.C.pink)end
local function apps()
 top();local l=list();UI.panel(2,6,UI.W-4,UI.H-11,"CONNECTED APPLICATION HOSTS",UI.C.pink);if#l==0 then UI.text(7,12,"NO CLIENTS VISIBLE",UI.C.yellow,UI.C.panel);UI.text(7,14,"R = discovery broadcast",UI.C.muted,UI.C.panel)else for i,d in ipairs(l)do local y=9+(i-1)*3;if y>UI.H-8 then break end;local a=i==selected;local c=online(d)and UI.C.green or UI.C.red;if a then UI.rect(4,y,UI.W-8,3,UI.C.panel2)end;UI.icon(7,y,d.wireless and"network"or"computer",a and UI.C.cyan or c);UI.text(13,y,fit(d.name or d.app or"CLIENT",28),a and UI.C.cyan or UI.C.white,UI.C.panel2);UI.text(43,y,fit(d.mod or d.controller or d.app or"CONTROLLER",25),UI.C.muted,UI.C.panel2);UI.text(70,y,d.link or"--",d.wireless and UI.C.purple or UI.C.cyan,UI.C.panel2);UI.text(82,y,online(d)and"ONLINE"or"OFFLINE",c,UI.C.panel2);UI.text(96,y,"ENTER",UI.C.yellow,UI.C.panel2)end end;UI.statusLine("UP/DOWN SELECT   ENTER OPEN   R DISCOVER   Q EXIT",UI.C.muted);UI.footer({{"apps","APPS",UI.C.pink,true},{"net","NETWORK",UI.C.blue},{"pc","REMOTE",UI.C.green}})
end
local function remote()
 top();local d=sel();if not d then UI.text(7,12,"NO CLIENT SELECTED",UI.C.yellow);return end;UI.panel(2,6,UI.W-4,UI.H-11,"LIVE DESKTOP // "..fit(d.name or d.address,35),UI.C.green);if not online(d)then UI.text(7,11,"CLIENT OFFLINE",UI.C.red,UI.C.panel);return end;local f=frames[d.address];local sz=sizes[d.address]or{};if not f then UI.text(7,11,"WAITING FOR SCREEN...",UI.C.yellow,UI.C.panel);request(d);return end;local maxY=math.min(UI.H-14,tonumber(sz.height)or #f);for y=1,maxY do local row=f[y];if type(row)=="table"then for x,c in pairs(row)do if x<UI.W-7 and type(c)=="table"then gpu.setForeground(c[2]or UI.C.white);gpu.setBackground(c[3]or UI.C.black);gpu.set(4+x,7+y,c[1]or" ")end end end end;UI.statusLine("R REFRESH   Q BACK",UI.C.muted);UI.footer({{"apps","APPS",UI.C.pink,true},{"net","NETWORK",UI.C.blue},{"pc","REMOTE",UI.C.green,true}})
end
local function draw()UI.resize();if UI.W>160 then pcall(gpu.setResolution,160,50);UI.resize()end;if mode=="APPS"then apps()else remote()end;dirty=false end
local function callback(sender,p,distance)
 if not network.valid(p)then return end;local d=devices[sender]or{address=sender};local data=p.data or{};merge(d,data);d.address=sender;d.last=now();d.distance=tonumber(distance)or 0;d.wireless=d.distance>0 or data.wireless==true;d.link=d.wireless and"WIRELESS"or"WIRED";if p.kind=="LINK_CONFIRM"then d.linked=true end;if p.kind=="SCREEN_BEGIN"then frames[sender]={};sizes[sender]=data elseif p.kind=="SCREEN_ROW"then frames[sender]=frames[sender]or{};frames[sender][tonumber(data.y)or 1]=data.cells elseif p.kind=="SCREEN_END"then status="REMOTE FRAME RECEIVED"end;dirty=true
end
local ok,why=network.startServer(callback);status=ok and"SERVER "..tostring(why)or"SERVER ERROR: "..tostring(why);discover();draw();event.timer(2,function()sync();dirty=true end,math.huge)
while running do local e,a,x,y,b=event.pull(0.25)
 if e=="touch"then if UI.hit("apps",x,y)then mode="APPS"elseif UI.hit("net",x,y)then discover()elseif UI.hit("pc",x,y)then mode="REMOTE";request(sel())end;dirty=true
 elseif e=="key_down"then local code=y;if code==16 or code==17 then running=false elseif code==19 then discover()elseif code==28 then if mode=="APPS"then if sel()then mode="REMOTE";request(sel())end else request(sel())end elseif code==200 then selected=math.max(1,selected-1)elseif code==208 then selected=math.min(math.max(1,#list()),selected+1)elseif code==15 then mode=mode=="APPS"and"REMOTE"or"APPS"end;dirty=true elseif e=="interrupted"then running=false end;if dirty then draw()end end
UI.clear()
