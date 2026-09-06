-- BULDACITY SGCraft CONTROLLER v2
-- Realistic Stargate control-room UI for OpenComputers / SGCraft 1.13.x.
-- The visual layer is deliberately self-contained and the hardware/API layer
-- is isolated in SGCraftAPI.lua so failures become diagnostics, not crashes.

local component=require("component")
local event=require("event")
local computer=require("computer")
local serialization=require("serialization")
local gpu=component.gpu
local API=assert(dofile("/home/SGCraftAPI.lua"))
local W,H=gpu.getResolution()

local C={bg=0x03060A,black=0x000000,steel=0x101820,steel2=0x17232D,edge=0x314451,cyan=0x35D9FF,green=0x35E58A,yellow=0xF1C75B,red=0xF04E5E,orange=0xFF8A30,purple=0x9B68FF,blue=0x3E78FF,white=0xEAF6FF,muted=0x728895,dim=0x334650}
local page="HOME";local gates={};local selected=1;local target="";local message="";local notice="SYSTEM INITIALISING";local logs={};local buttons={};local book={};local search="";local bookSelected=1;local cfg="/home/sgcraft-addressbook.cfg";local anim=0;local lastScan=0;local dirty=true

local function fg(c) gpu.setForeground(c or C.white) end
local function bg(c) gpu.setBackground(c or C.bg) end
local function fill(x,y,w,h,c) if w>0 and h>0 then bg(c);gpu.fill(x,y,w,h," ") end end
local function text(x,y,s,c,b) if x>=1 and y>=1 and x<=W and y<=H then fg(c);bg(b or C.bg);gpu.set(x,y,tostring(s or "")) end end
local function fit(s,n) s=tostring(s or "");if n<=0 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
local function line(x,y,w,c) fill(x,y,w,1,c) end
local function panel(x,y,w,h,title,accent) fill(x,y,w,h,C.steel);line(x,y,w,accent);text(x+2,y,"[ "..fit(title,w-5).." ]",C.white,accent);if h>2 then line(x+1,y+h-1,w-2,C.edge) end end
local function button(id,x,y,w,h,label,accent,active) if x<1 or y<1 or x+w-1>W or y+h-1>H then return end;buttons[id]={x=x,y=y,w=w,h=h};local b=active and C.white or accent;local f=active and accent or C.white;fill(x,y,w,h,b);local yy=y+math.floor((h-1)/2);local xx=x+math.max(1,math.floor((w-#label)/2));text(xx,yy,fit(label,w-2),f,b) end
local function hit(x,y) for id,b in pairs(buttons) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end end end
local function logAdd(s) logs[#logs+1]=os.date("%H:%M:%S").."  "..tostring(s);while #logs>11 do table.remove(logs,1) end;notice=tostring(s);dirty=true end
local function current() return gates[selected] end
local function stateColor(s) if s=="Connected" then return C.green end;if s=="Dialling" or s=="Opening" or s=="Closing" then return C.cyan end;if s=="Idle" then return C.yellow end;if s=="API ERROR" then return C.orange end;return C.red end

local function scan(silent)
 local old=current() and current().address;gates=API.list();selected=1
 if old then for i,g in ipairs(gates) do if g.address==old then selected=i break end end end
 if #gates==0 then if not silent then logAdd("SCAN / NO SGCraft INTERFACE") end else if not silent then logAdd("SCAN / "..#gates.." INTERFACE(S) ONLINE TO OC") end end
 lastScan=computer.uptime();dirty=true
end
local function read() return API.read(current()) end
local function loadBook() book={};local f=io.open(cfg,"r");if not f then return end;local raw=f:read("*a");f:close();local ok,data=pcall(serialization.unserialize,raw);if ok and type(data)=="table" then book=data end end
local function saveBook() local f=io.open(cfg,"w");if not f then logAdd("ADDRESS BOOK / WRITE ERROR");return end;f:write(serialization.serialize(book));f:close();logAdd("ADDRESS BOOK / SAVED") end
local function normalize(a) return tostring(a or ""):gsub("[^0-9A-Za-z]",""):upper() end
local function validAddress(a) a=normalize(a);return #a==7 or #a==9 end

local function dial(a)
 a=normalize(a or target);target=a;if not validAddress(a) then logAdd("DIAL / ADDRESS NEEDS 7 OR 9 SYMBOLS");return end
 local g=current();if not g then logAdd("DIAL / NO INTERFACE");return end
 local d=API.read(g);if d.state=="Offline" or d.state=="NO INTERFACE" or d.localAddress=="" then logAdd("DIAL / INTERFACE NOT CONNECTED TO A GATE");return end
 local okNeed,need,needErr=API.energyToDial(g,a);if okNeed and tonumber(need) and tonumber(need)>d.energy then logAdd("DIAL / INSUFFICIENT ENERGY");return end
 local ok,x,e=API.dial(g,a);if ok then logAdd("DIAL / SEQUENCE STARTED / "..a) else logAdd("DIAL / ERROR / "..tostring(e or x or needErr)) end
end
local function disconnect() local g=current();if not g then return end;local ok,x,e=API.disconnect(g);if ok then logAdd("GATE / DISCONNECT COMMAND") else logAdd("GATE / "..tostring(e or x)) end end
local function iris(open) local g=current();if not g then return end;local ok,x,e;if open then ok,x,e=API.openIris(g) else ok,x,e=API.closeIris(g) end;if ok then logAdd(open and "IRIS / OPEN COMMAND" or "IRIS / CLOSE COMMAND") else logAdd("IRIS / "..tostring(e or x)) end end

local function header(d)
 fill(1,1,W,5,C.black);text(2,1,"BULDACITY // STARGATE CONTROL",C.cyan,C.black);text(2,2,"SGCRAFT 1.13.x  /  OPEN COMPUTERS",C.muted,C.black)
 local status=d and d.state or "NO INTERFACE";text(math.max(2,W-20),1,fit(status,18),stateColor(status),C.black);text(2,4,fit(notice,W-4),C.muted,C.black);line(1,5,W,C.cyan)
end
local function ringPoint(cx,cy,rx,ry,deg) local a=math.rad(deg);return math.floor(cx+math.cos(a)*rx+.5),math.floor(cy+math.sin(a)*ry+.5) end
local function drawGate(x,y,w,h,d)
 panel(x,y,w,h,"STARGATE / LIVE RENDER",C.cyan);local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)-1;local rx=math.max(10,math.floor(w*.29));local ry=math.max(5,math.floor(h*.34));local active=d.state~="Offline" and d.state~="NO INTERFACE" and d.state~="API ERROR";local connected=d.state=="Connected" or d.state=="Opening"
 for deg=0,350,10 do local px,py=ringPoint(cx,cy,rx,ry,deg);text(px,py,(deg%20==0) and "O" or ".",active and C.edge or C.dim,C.steel) end
 for deg=0,350,10 do local px,py=ringPoint(cx,cy,rx-2,ry-1,deg);text(px,py,(deg%30==0) and "#" or ".",active and C.white or C.dim,C.steel) end
 if connected then
  for yy=-3,3 do local span=math.max(2,math.floor((4-math.abs(yy))*.9));local s="";for i=1,span*2+1 do s=s..((math.floor(anim*5+i+yy)%3==0) and "*" or ".") end;text(cx-span,cy+yy,s,(yy%2==0) and C.cyan or C.blue,C.steel) end
 elseif d.state=="Dialling" or d.state=="Opening" then text(cx-5,cy,"INITIALISING",C.cyan,C.steel)
 elseif active then text(cx-3,cy,"STANDBY",C.yellow,C.steel)
 else text(cx-5,cy,d.state=="NO INTERFACE" and "NO LINK" or "OFFLINE",C.red,C.steel) end
 for i=1,9 do local deg=-90+(i-1)*40;local px,py=ringPoint(cx,cy,rx+1,ry+1,deg);local engaged=i<=d.engaged;text(px-1,py,engaged and "[+]" or "[ ]",engaged and C.orange or C.dim,C.steel) end
 text(cx-math.floor(#d.state/2),y+h-3,d.state,stateColor(d.state),C.steel)
end
local function drawInterfaceList(x,y,w,h)
 panel(x,y,w,h,"INTERFACE BUS",C.blue)
 if #gates==0 then text(x+2,y+3,"NO STARGATE COMPONENT",C.red,C.steel);text(x+2,y+5,"OpenComputers cannot see an SGCraft",C.muted,C.steel);text(x+2,y+6,"Stargate Interface on the component bus.",C.muted,C.steel)
 else for i,g in ipairs(gates) do local yy=y+2+(i-1)*4;if yy+2>y+h-3 then break end;local d=API.read(g);local active=i==selected;local b=active and C.steel2 or C.steel;fill(x+1,yy,w-2,3,b);text(x+2,yy,active and ">" or " ",C.cyan,b);text(x+4,yy,fit(g.address,w-7),C.white,b);text(x+4,yy+1,fit(d.state,w-7),stateColor(d.state),b);text(x+4,yy+2,g.primary and "PRIMARY" or "COMPONENT",C.muted,b);buttons["gate"..i]={x=x+1,y=yy,w=w-2,h=3} end end
 button("rescan",x+2,y+h-3,w-4,2,"RESCAN BUS",C.blue)
end
local function drawTelemetry(x,y,w,h,d)
 panel(x,y,w,h,"GATE TELEMETRY",C.yellow)
 local function row(n,label,value,color) text(x+2,y+n,label,C.muted,C.steel);text(x+13,y+n,fit(value,w-15),color or C.white,C.steel) end
 row(2,"STATE",d.state,stateColor(d.state));row(4,"DIRECTION",d.direction=="" and "-" or d.direction,C.white);row(6,"CHEVRONS",tostring(d.engaged).." / 9",C.orange);row(8,"ENERGY",string.format("%.1f",d.energy),C.yellow);row(10,"IRIS",d.iris,d.iris=="Closed" and C.green or C.yellow);row(12,"LOCAL",d.localAddress=="" and "-" or d.localAddress,C.white);row(14,"REMOTE",d.remoteAddress=="" and "-" or d.remoteAddress,C.cyan);text(x+2,y+16,"API",C.muted,C.steel);text(x+13,y+16,d.ok and "STARGATE OK" or "STARGATE ERROR",d.ok and C.green or C.red,C.steel);text(x+2,y+17,fit(d.error=="" and "Hardware/API link healthy" or d.error,w-4),d.error=="" and C.muted or C.red,C.steel)
end
local function drawCommandBar(y)
 panel(2,y,W-3,5,"CONTROL",C.green);button("home",4,y+2,8,2,"HOME",C.cyan,page=="HOME");button("dial",14,y+2,9,2,"DIAL",C.purple,page=="DIAL");button("book",25,y+2,13,2,"ADDRESS",C.blue,page=="BOOK");button("iris",40,y+2,9,2,"IRIS",C.yellow);button("disconnect",51,y+2,14,2,"DISCONNECT",C.red);button("diag",67,y+2,11,2,"DIAGNOSTIC",C.cyan,page=="DIAG");button("log",80,y+2,5,2,"LOG",C.cyan,page=="LOG")
end
local function drawDial()
 panel(2,7,W-3,H-8,"DIALING CONSOLE",C.purple);text(5,9,"DESTINATION",C.muted,C.steel);fill(17,8,math.min(31,W-42),3,C.steel2);text(19,9,target=="" and "ENTER ADDRESS" or target,C.cyan,C.steel2);button("clear",W-20,8,7,3,"CLEAR",C.red);button("dialnow",W-12,8,8,3,"DIAL",C.green)
 local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";local cols=10;local bw=math.max(5,math.floor((W-9-(cols-1))/cols));local sy=14
 for i=1,#chars do local col=(i-1)%cols;local row=math.floor((i-1)/cols);button("key"..i,4+col*(bw+1),sy+row*2,bw,1,chars:sub(i,i),C.blue) end
 text(5,H-4,"7 or 9 symbols / separators are ignored / keyboard input also supported",C.muted,C.steel)
end
local function filteredBook() local out={};local q=search:lower();for i,v in ipairs(book) do local s=(v.name or "").." "..(v.address or "").." "..(v.group or "");if q=="" or s:lower():find(q,1,true) then out[#out+1]={index=i,data=v} end end;return out end
local function drawBook()
 panel(2,7,W-3,H-8,"ADDRESS BOOK / NAVIGATION",C.blue);text(5,9,"FILTER",C.muted,C.steel);fill(13,8,28,3,C.steel2);text(15,9,search=="" and "type to search" or search,C.cyan,C.steel2);local list=filteredBook();local yy=13
 if #list==0 then text(5,13,"NO STORED GATES",C.muted,C.steel) end
 for i,item in ipairs(list) do if yy+2>H-4 then break end;local v=item.data;local active=i==bookSelected;local b=active and C.steel2 or C.steel;fill(4,yy,W-8,3,b);text(6,yy,fit(v.name,W-30),C.white,b);text(6,yy+1,fit(v.address,18),C.cyan,b);text(27,yy+1,fit(v.group or "DEFAULT",18),C.muted,b);buttons["book"..i]={x=4,y=yy,w=W-8,h=3};yy=yy+4 end
 button("bookDial",W-20,8,8,3,"DIAL",C.green);text(5,H-4,"Use addBook(name,address,group) from OpenOS to store a gate.",C.muted,C.steel)
end
local function drawDiag(d)
 panel(2,7,W-3,H-8,"HARDWARE / API DIAGNOSTIC",C.cyan)
 local function check(y,label,ok,detail) text(6,y,ok and "[ OK ]" or "[FAIL]",ok and C.green or C.red,C.steel);text(14,y,fit(label,24),C.white,C.steel);text(39,y,fit(detail,W-43),ok and C.muted or C.red,C.steel) end
 check(10,"OPEN COMPUTERS COMPONENT",#gates>0,#gates>0 and ("stargate x"..#gates) or "no stargate component");check(12,"STARGATE STATE API",d.ok,d.ok and d.state or d.error);check(14,"LOCAL ADDRESS",d.localOK,d.localOK and (d.localAddress~="" and d.localAddress or "empty / gate offline") or d.localError);check(16,"REMOTE ADDRESS",d.remoteOK,d.remoteOK and (d.remoteAddress~="" and d.remoteAddress or "not connected") or d.remoteError);check(18,"ENERGY API",d.energyOK,d.energyOK and string.format("%.1f available",d.energy) or d.energyError);check(20,"IRIS API",d.irisOK,d.irisOK and d.iris or d.irisError)
 text(6,22,"SGCraft interface must be placed under the bottom row of the gate ring.",C.yellow,C.steel)
end
local function drawLog()
 panel(2,7,W-3,H-8,"SYSTEM LOG",C.cyan);local yy=10;for i=1,#logs do text(5,yy,fit(logs[i],W-9),C.muted,C.steel);yy=yy+1;if yy>H-3 then break end end
end
local function render()
 buttons={};local d=read();header(d)
 if page=="HOME" then local left=math.floor(W*.48);drawGate(2,7,left,H-15,d);drawInterfaceList(left+2,7,W-left-4,9);drawTelemetry(left+2,17,W-left-4,H-25,d);drawCommandBar(H-7)
 elseif page=="DIAL" then drawDial();drawCommandBar(H-7)
 elseif page=="BOOK" then drawBook();drawCommandBar(H-7)
 elseif page=="DIAG" then drawDiag(d);drawCommandBar(H-7)
 elseif page=="LOG" then drawLog();drawCommandBar(H-7) end
 gpu.setBackground(C.bg);dirty=false
end
local function process(id)
 if id=="home" then page="HOME";dirty=true;return end;if id=="dial" then page="DIAL";dirty=true;return end;if id=="book" then page="BOOK";dirty=true;return end;if id=="diag" then page="DIAG";dirty=true;return end;if id=="log" then page="LOG";dirty=true;return end;if id=="rescan" then scan(false);return end;if id=="disconnect" then disconnect();return end
 if id=="iris" then local d=read();iris(d.iris=="Closed");return end;if id=="clear" then target="";dirty=true;return end;if id=="dialnow" then dial(target);return end
 if id=="bookDial" then local list=filteredBook();if list[bookSelected] then target=list[bookSelected].data.address;dial(target) end;return end
 local k=tostring(id):match("^key(%d+)$");if k then local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";local c=chars:sub(tonumber(k),tonumber(k));if c then target=target..c;dirty=true end;return end
 local gidx=tostring(id):match("^gate(%d+)$");if gidx then selected=tonumber(gidx);dirty=true;return end
 local bidx=tostring(id):match("^book(%d+)$");if bidx then bookSelected=tonumber(bidx);dirty=true;return end
end
local function keyInput(ch)
 if page=="DIAL" then if ch==8 or ch==127 then target=target:sub(1,-2);dirty=true;return end;if ch==13 then dial(target);return end;if type(ch)=="number" and ch>=32 and ch<=126 then local c=string.char(ch):upper();if c:match("[%w]") then target=target..c;dirty=true end end
 elseif page=="BOOK" and type(ch)=="number" and ch>=32 and ch<=126 then search=search..string.char(ch);dirty=true end
end

loadBook();scan(true);logAdd(#gates>0 and "SYSTEM READY / INTERFACE BUS ACTIVE" or "SYSTEM READY / WAITING FOR STARGATE INTERFACE")
local timer=event.timer(0.15,function() anim=anim+.15;dirty=true end,math.huge)
while true do
 if computer.uptime()-lastScan>3 then scan(true) end;if dirty then render() end
 local e={event.pull(0.2)};local name=e[1]
 if name=="touch" then process(hit(e[3],e[4])) elseif name=="key_down" then keyInput(e[4]) elseif name=="sgStargateStateChange" or name=="sgChevronEngaged" or name=="sgIrisStateChange" or name=="sgDialIn" or name=="sgDialOut" then dirty=true;logAdd("EVENT / "..name) elseif name=="interrupted" then break end
end
if timer then pcall(event.cancel,timer) end
gpu.setBackground(C.black);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
