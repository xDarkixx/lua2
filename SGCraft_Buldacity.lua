-- BULDACITY SGCraft CONTROLLER
-- SGCX-inspired controller in the BULDACITY design.
-- Robust OpenComputers / SGCraft 1.13.x interface detection.

local component=require("component")
local event=require("event")
local computer=require("computer")
local serialization=require("serialization")
local gpu=component.gpu
local W,H=gpu.getResolution()

local C={bg=0x05080D,black=0x000000,panel=0x0B1119,panel2=0x111A25,panel3=0x172432,edge=0x31475B,cyan=0x20DFFF,blue=0x3E78FF,green=0x35E58A,yellow=0xF2C94C,red=0xF04E5E,purple=0x9B68FF,white=0xE8F3FA,muted=0x788D9D,dim=0x3D5263}
local page="HOME";local selected=1;local gates={};local target="";local message="";local notice="SYSTEM STARTING";local logs={};local buttons={};local dirty=true;local anim=0;local lastScan=0;local book={};local search="";local bookSelected=1;local cfg="/home/sgcraft-addressbook.cfg"

local function fg(c) gpu.setForeground(c or C.white) end
local function bg(c) gpu.setBackground(c or C.bg) end
local function fill(x,y,w,h,c) if w>0 and h>0 then bg(c);gpu.fill(x,y,w,h," ") end end
local function text(x,y,s,c,b) if x>=1 and y>=1 and x<=W and y<=H then fg(c);bg(b or C.bg);gpu.set(x,y,tostring(s or "")) end end
local function fit(s,n) s=tostring(s or "");if n<1 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
local function line(x,y,w,c) fill(x,y,w,1,c) end
local function panel(x,y,w,h,title,accent) fill(x,y,w,h,C.panel);line(x,y,w,accent);if w>=12 then text(x+2,y,"[ "..fit(title,w-5).." ]",C.white,accent) end;if h>=3 then line(x+1,y+h-1,w-2,C.edge) end end
local function button(id,x,y,w,h,label,accent,active) if x<1 or y<1 or x+w-1>W or y+h-1>H then return end;buttons[id]={x=x,y=y,w=w,h=h};local b=active and C.white or accent;local f=active and accent or C.white;fill(x,y,w,h,b);local yy=y+math.floor((h-1)/2);local xx=x+math.max(1,math.floor((w-#label)/2));text(xx,yy,fit(label,w-2),f,b) end
local function hit(x,y) for id,b in pairs(buttons) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end end end
local function logAdd(s) logs[#logs+1]=os.date("%H:%M:%S").."  "..tostring(s);while #logs>10 do table.remove(logs,1) end;notice=tostring(s);dirty=true end

local function call(p,name,...)
 if not p then return false,nil,"no interface" end
 local fn=p[name]
 if type(fn)~="function" then return false,nil,"method unavailable: "..name end
 local args={...};local ok,a,b,c=pcall(function() return fn(table.unpack(args)) end)
 if ok then return true,a,b,c end
 return false,nil,a
end

local function interfaceList()
 local out={};local primary=nil
 if component.isAvailable("stargate") then
  local ok,p=pcall(component.getPrimary,"stargate")
  if ok and p and p.address then primary=p.address end
 end
 for address in component.list("stargate") do
  local p=component.proxy(address)
  if p then out[#out+1]={address=address,proxy=p,primary=address==primary} end
 end
 table.sort(out,function(a,b) return a.address<b.address end)
 return out
end

local function read(g)
 if not g then return {state="NO INTERFACE",engaged=0,direction="",localAddress="",remoteAddress="",energy=0,iris="Offline",ok=false,error="No stargate component"} end
 local p=g.proxy
 local ok,s,e,d=call(p,"stargateState")
 local okLA,la,laErr=call(p,"localAddress")
 local okRA,ra,raErr=call(p,"remoteAddress")
 local okEN,en,enErr=call(p,"energyAvailable")
 local okIR,ir,irErr=call(p,"irisState")
 local state=ok and tostring(s or "Offline") or "OFFLINE"
 local err=ok and "" or tostring(e or "stargateState failed")
 return {state=state,engaged=tonumber(e) or 0,direction=tostring(d or ""),localAddress=tostring(la or ""),remoteAddress=tostring(ra or ""),energy=tonumber(en) or 0,iris=tostring(ir or "Offline"),ok=ok,error=err,localOK=okLA,remoteOK=okRA,energyOK=okEN,irisOK=okIR,localError=tostring(laErr or ""),remoteError=tostring(raErr or ""),energyError=tostring(enErr or ""),irisError=tostring(irErr or "")}
end

local function stateColor(s) if s=="Connected" then return C.green end;if s=="Dialling" or s=="Opening" or s=="Closing" then return C.cyan end;if s=="Idle" then return C.yellow end;return C.red end
local function scan(silent)
 local old=gates[selected] and gates[selected].address;gates=interfaceList();selected=1
 if old then for i,g in ipairs(gates) do if g.address==old then selected=i end end end
 if #gates==0 then if not silent then logAdd("SCAN: NO STARGATE INTERFACE") end else if not silent then logAdd("SCAN: "..#gates.." INTERFACE(S) DETECTED") end end
 lastScan=computer.uptime();dirty=true
end
local function current() return gates[selected] end

local function loadBook() book={};local f=io.open(cfg,"r");if not f then return end;local raw=f:read("*a");f:close();local ok,data=pcall(serialization.unserialize,raw);if ok and type(data)=="table" then book=data end end
local function saveBook() local f=io.open(cfg,"w");if not f then logAdd("ADDRESS BOOK: WRITE ERROR");return end;f:write(serialization.serialize(book));f:close();logAdd("ADDRESS BOOK SAVED") end
local function normalized(a) return tostring(a or ""):gsub("[^0-9A-Za-z]",""):upper() end
local function validAddress(a) a=normalized(a);return #a==7 or #a==9 end

local function dial(a)
 a=normalized(a or target);target=a;if not validAddress(a) then logAdd("DIAL: ADDRESS MUST HAVE 7 OR 9 SYMBOLS");return end
 local g=current();if not g then logAdd("DIAL: NO INTERFACE");return end
 local d=read(g);if d.state=="OFFLINE" or d.localAddress=="" then logAdd("DIAL: STARGATE INTERFACE IS OFFLINE");return end
 local needOK,need,needErr=call(g.proxy,"energyToDial",a);if needOK and tonumber(need) and tonumber(need)>d.energy then logAdd("DIAL: NOT ENOUGH ENERGY");return end
 local ok,x,e=call(g.proxy,"dial",a);if ok then logAdd("DIAL STARTED  "..a) else logAdd("DIAL ERROR: "..tostring(e or x or needErr)) end
end
local function disconnect() local g=current();if not g then return end;local ok,x,e=call(g.proxy,"disconnect");if ok then logAdd("GATE DISCONNECTED") else logAdd("DISCONNECT: "..tostring(e or x)) end end
local function iris(open) local g=current();if not g then return end;local ok,x,e=call(g.proxy,open and "openIris" or "closeIris");if ok then logAdd(open and "IRIS OPEN COMMAND" or "IRIS CLOSE COMMAND") else logAdd("IRIS: "..tostring(e or x)) end end
local function sendMsg() local g=current();if not g or message=="" then logAdd("MESSAGE: EMPTY OR NO GATE");return end;local ok,x,e=call(g.proxy,"sendMessage",message);if ok then logAdd("MESSAGE SENT") else logAdd("MESSAGE: "..tostring(e or x)) end end

local function filteredBook() local r={};local q=search:lower();for i,v in ipairs(book) do local s=(v.name or "").." "..(v.address or "").." "..(v.group or "");if q=="" or s:lower():find(q,1,true) then r[#r+1]={index=i,data=v} end end;return r end
local function addBook(name,address,group) address=normalized(address);if not validAddress(address) then logAdd("BOOK: INVALID ADDRESS");return end;book[#book+1]={name=tostring(name or "Gate"),address=address,group=tostring(group or "DEFAULT")};saveBook() end

local function header()
 fill(1,1,W,5,C.black);text(2,1,"STARGATE CONTROL",C.cyan,C.black);text(2,2,"BULDACITY // SGCX-STYLE CONTROLLER",C.white,C.black)
 local d=read(current());text(math.max(2,W-22),1,fit(d.state,21),stateColor(d.state),C.black);text(2,4,fit(notice,W-4),C.muted,C.black);line(1,5,W,C.cyan)
end
local function drawGate(x,y,w,h,d)
 panel(x,y,w,h,"STARGATE",C.cyan);local cx=x+math.floor(w/2);local cy=y+math.floor(h/2);local r=math.max(7,math.min(math.floor(w*.27),math.floor(h*.58)));local active=d.state~="OFFLINE" and d.state~="NO INTERFACE"
 for deg=0,359,10 do local a=math.rad(deg);local px=math.floor(cx+math.cos(a)*r+.5);local py=math.floor(cy+math.sin(a)*r*.45+.5);text(px,py,(deg%30==0) and "O" or ".",active and C.cyan or C.dim,C.panel) end
 if active then for rr=2,r-3,3 do local n=math.max(12,math.floor(2*math.pi*rr));for i=0,n-1,math.max(1,math.floor(n/20)) do local a=i/n*math.pi*2+anim*.6;local px=math.floor(cx+math.cos(a)*rr+.5);local py=math.floor(cy+math.sin(a)*rr*.45+.5);text(px,py,".",(math.floor(anim*8)%2==0) and C.white or C.cyan,C.panel) end end else text(cx-4,cy,d.state=="NO INTERFACE" and "NO IFACE" or "OFFLINE",C.red,C.panel) end
 for i=1,9 do local a=math.rad(-90+(i-1)*40);local px=math.floor(cx+math.cos(a)*(r+2)+.5);local py=math.floor(cy+math.sin(a)*(r+2)*.45+.5);text(px,py,i<=d.engaged and "#" or "+",i<=d.engaged and C.yellow or C.dim,C.panel) end
 text(cx-math.floor(#d.state/2),y+h-3,d.state,stateColor(d.state),C.panel)
end
local function drawInterfaces(x,y,w,h)
 panel(x,y,w,h,"INTERFACES",C.blue)
 if #gates==0 then text(x+2,y+3,"NO SGCraft INTERFACE",C.red,C.panel);text(x+2,y+5,"Component type 'stargate' not detected",C.muted,C.panel);button("scan",x+2,y+h-3,w-4,2,"RESCAN",C.blue);return end
 for i,g in ipairs(gates) do local yy=y+2+(i-1)*4;if yy+2>y+h-3 then break end;local d=read(g);local active=i==selected;local b=active and C.panel3 or C.panel;buttons["gate"..i]={x=x+1,y=yy,w=w-2,h=3};fill(x+1,yy,w-2,3,b);text(x+2,yy,active and ">" or " ",C.cyan,b);text(x+4,yy,fit(g.address,w-7),C.white,b);text(x+4,yy+1,fit(d.state,w-7),stateColor(d.state),b);text(x+4,yy+2,g.primary and "PRIMARY" or "INTERFACE",C.muted,b) end
 button("scan",x+2,y+h-3,w-4,2,"RESCAN",C.blue)
end
local function drawTelemetry(x,y,w,h,d)
 panel(x,y,w,h,"TELEMETRY",C.yellow)
 local function row(n,l,v,c) text(x+2,y+n,l,C.muted,C.panel);text(x+13,y+n,fit(v,w-15),c or C.white,C.panel) end
 row(2,"STATE",d.state,stateColor(d.state));row(4,"DIRECTION",d.direction=="" and "-" or d.direction,C.white);row(6,"CHEVRON",d.engaged.." / 9",C.yellow);row(8,"POWER",string.format("%.1f SU",d.energy),C.yellow);row(10,"IRIS",d.iris,d.iris=="Closed" and C.green or C.yellow);row(12,"LOCAL",d.localAddress=="" and "-" or d.localAddress,C.white);row(14,"REMOTE",d.remoteAddress=="" and "-" or d.remoteAddress,C.cyan);text(x+2,y+16,"API",C.muted,C.panel);text(x+13,y+16,d.ok and "stargateState OK" or "stargateState ERROR",d.ok and C.green or C.red,C.panel);text(x+2,y+17,fit(d.error=="" and "Interface detected" or d.error,w-4),d.error=="" and C.muted or C.red,C.panel)
end
local function drawCommand(y)
 panel(2,y,W-3,5,"COMMAND",C.green);button("dialpage",4,y+2,12,2,"DIAL",C.green);button("bookpage",17,y+2,14,2,"ADDRESS BOOK",C.blue);button("iris",33,y+2,10,2,"IRIS",C.yellow);button("disconnect",45,y+2,14,2,"DISCONNECT",C.red);button("link",61,y+2,10,2,"MESSAGE",C.purple);button("logpage",73,y+2,9,2,"LOG",C.cyan)
end
local function drawDial()
 panel(2,7,W-3,H-8,"DIALING CONSOLE",C.purple);text(5,10,"TARGET ADDRESS",C.muted,C.panel);fill(20,9,math.min(25,W-25),3,C.panel3);text(22,10,target=="" and "ENTER 7/9 SYMBOL ADDRESS" or target,C.cyan,C.panel3)
 local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";local cols=12;local bw=math.max(4,math.floor((W-8-(cols-1))/cols));local sy=14
 for i=1,#chars do local c=(i-1)%cols;local r=math.floor((i-1)/cols);button("k"..i,4+c*(bw+1),sy+r*2,bw,1,chars:sub(i,i),C.blue) end
 button("back",W-27,9,6,3,"<",C.yellow);button("clear",W-20,9,7,3,"CLR",C.red);button("dialnow",W-12,9,8,3,"DIAL",C.green);text(5,H-5,"SGCraft accepts 7 or 9 symbols, with or without separators.",C.muted,C.panel)
end
local function drawBook()
 panel(2,7,W-3,H-8,"ADDRESS BOOK",C.blue);text(5,9,"SEARCH",C.muted,C.panel);fill(13,8,math.min(30,W-40),3,C.panel3);text(15,9,search=="" and "type to filter" or search,C.cyan,C.panel3);button("bookdial",W-34,8,10,3,"DIAL",C.green);button("bookadd",W-23,8,9,3,"ADD",C.purple);button("bookclear",W-13,8,9,3,"CLEAR",C.red)
 local list=filteredBook();for n=1,math.min(#list,H-14) do local v=list[n].data;local yy=13+(n-1)*3;local active=n==bookSelected;local b=active and C.panel3 or C.panel;buttons["b"..n]={x=4,y=yy,w=W-8,h=2};fill(4,yy,W-8,2,b);text(6,yy,fit(v.name or "Gate",20),C.white,b);text(28,yy,fit(v.address or "",14),C.cyan,b);text(44,yy,fit(v.group or "DEFAULT",14),C.muted,b) end;if #list==0 then text(5,14,"NO STORED ADDRESSES",C.muted,C.panel) end
end
local function drawLog()
 panel(2,7,W-3,H-8,"SYSTEM LOG",C.cyan);for i,s in ipairs(logs) do text(5,9+i*2,s,C.white,C.panel) end;button("logclear",5,H-5,12,2,"CLEAR LOG",C.red)
end
local function drawHome()
 local d=read(current());local left=math.max(38,math.floor(W*.45));drawGate(2,7,left,H-14,d);drawInterfaces(left+2,7,W-left-3,math.floor((H-14)*.58));drawTelemetry(left+2,10+math.floor((H-14)*.58),W-left-3,H-(10+math.floor((H-14)*.58))-7,d);drawCommand(H-6)
end
local function draw() buttons={};fill(1,1,W,H,C.bg);header();if page=="HOME" then drawHome() elseif page=="DIAL" then drawDial() elseif page=="BOOK" then drawBook() else drawLog() end;if page~="HOME" then button("home",2,H-5,12,2,"HOME",C.cyan) end end

local function handle(id)
 if not id then return end
 if id=="home" then page="HOME";dirty=true;return end
 if id=="scan" then scan(false);return end
 if id=="dialpage" then page="DIAL";dirty=true;return end
 if id=="bookpage" then page="BOOK";dirty=true;return end
 if id=="logpage" then page="LOG";dirty=true;return end
 if id=="disconnect" then disconnect();return end
 if id=="iris" then local d=read(current());iris(d.iris=="Closed" or d.iris=="Offline");return end
 if id=="link" then page="LOG";sendMsg();return end
 if id=="clear" then target="";dirty=true;return end
 if id=="back" then target=target:sub(1,#target-1);dirty=true;return end
 if id=="dialnow" then dial();return end
 if id=="logclear" then logs={};notice="LOG CLEARED";dirty=true;return end
 if id=="bookclear" then search="";dirty=true;return end
 if id=="bookdial" then local list=filteredBook();local v=list[bookSelected] and list[bookSelected].data;if v then target=v.address;page="DIAL";dirty=true end;return end
 if id=="bookadd" then logAdd("BOOK: addBook(name,address,group) available in this controller");return end
 if id:sub(1,1)=="k" then local i=tonumber(id:sub(2));local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";if i and chars:sub(i,i)~="" then target=(target..chars:sub(i,i)):sub(1,9);dirty=true end;return end
 if id:sub(1,4)=="gate" then selected=tonumber(id:sub(5)) or selected;dirty=true;return end
 if id:sub(1,1)=="b" then bookSelected=tonumber(id:sub(2)) or bookSelected;dirty=true;return end
end

loadBook();scan(true)
if #gates>0 then local d=read(current());if d.state=="Offline" or d.state=="OFFLINE" then logAdd("INTERFACE FOUND - GATE OFFLINE");logAdd("CHECK Stargate Interface placement / gate connection") else logAdd("STARGATE ONLINE: "..d.state) end else logAdd("NO STARGATE INTERFACE DETECTED") end

local timer=event.timer(0.25,function() anim=anim+0.25;dirty=true end,math.huge)
while true do
 if dirty then draw();dirty=false end
 local e={event.pull(0.25)};local name=e[1]
 if name=="touch" then handle(hit(e[3],e[4]))
 elseif name=="key_down" then local ch=e[3];if page=="DIAL" then if ch==8 then target=target:sub(1,#target-1);dirty=true elseif ch==13 then dial() elseif ch>=32 and ch<=126 then target=(target..string.char(ch)):upper():gsub("[^0-9A-Z]",""):sub(1,9);dirty=true end elseif page=="BOOK" then if ch==8 then search=search:sub(1,#search-1);dirty=true elseif ch>=32 and ch<=126 then search=(search..string.char(ch)):sub(1,24);dirty=true end end
 elseif name=="sgStargateStateChange" or name=="sgChevronEngaged" or name=="sgIrisStateChange" or name=="sgDialIn" or name=="sgDialOut" then logAdd(name);scan(true)
 elseif name=="sgMessageReceived" then logAdd("REMOTE MESSAGE RECEIVED");dirty=true
 elseif name=="interrupted" then break end
 if computer.uptime()-lastScan>3 then scan(true) end
end
pcall(event.cancel,timer)
