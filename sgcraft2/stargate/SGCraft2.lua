-- BULDACITY SGCraft2
-- Full Stargate controller using the original SGCraft API surface with the new BULDACITY graphics.
-- OpenComputers / Minecraft 1.7.10 / SGCraft 1.13.x
local component=require("component")
local event=require("event")
local computer=require("computer")
local serialization=require("serialization")
local gpu=assert(component.gpu,"GPU component required")
local API=dofile("/home/sgcraft2/lib/SGCraftAPI.lua")
local Visual=dofile("/home/sgcraft2/lib/SGCraftVisual.lua")
local W,H=gpu.getResolution();local page="HOME";local gates={};local selected=1;local target="";local logs={};local buttons={};local book={};local bookSelected=1;local search="";local anim=0;local notice="SYSTEM INITIALISING";local lastScan=0;local running=true;local addressCfg="/home/sgcraft2-interface.cfg";local bookCfg="/home/sgcraft2-addressbook.cfg"
local C=Visual.C
local function fill(x,y,w,h,c) Visual.fill(gpu,x,y,w,h,c) end
local function text(x,y,s,c,b) Visual.text(gpu,x,y,s,c,b) end
local function fit(s,n) return Visual.fit(s,n) end
local function panel(x,y,w,h,title,accent) fill(x,y,w,h,C.metal);Visual.line(gpu,x,y,w,accent);text(x+2,y,"[ "..fit(title,w-5).." ]",C.white,accent);if h>2 then Visual.line(gpu,x+1,y+h-1,w-2,C.edge) end end
local function button(id,x,y,w,h,label,accent,active) buttons[id]={x=x,y=y,w=w,h=h};local b=active and C.white or accent;local f=active and accent or C.white;fill(x,y,w,h,b);text(x+math.max(1,math.floor((w-#label)/2)),y+math.floor((h-1)/2),fit(label,w-2),f,b) end
local function hit(x,y) for id,b in pairs(buttons) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end end end
local function logAdd(s) logs[#logs+1]=os.date("%H:%M:%S").."  "..tostring(s);while #logs>14 do table.remove(logs,1) end;notice=tostring(s) end
local function current() return gates[selected] end
local function stateColor(s) if s=="Connected" then return C.green end;if s=="Dialling" or s=="Opening" or s=="Closing" then return C.cyan end;if s=="Idle" then return C.yellow end;if s=="API ERROR" then return C.orange end;return C.red end
local function saveInterface() local f=io.open(addressCfg,"w");if f then f:write(current() and current().address or "");f:close() end end
local function loadInterface() local f=io.open(addressCfg,"r");if not f then return nil end;local a=f:read("*l");f:close();return a end
local function scan(silent)
 local old=current() and current().address;local preferred=loadInterface();gates=API.list();selected=1
 local wanted=preferred or old;if wanted then for i,g in ipairs(gates) do if g.address==wanted then selected=i;break end end end
 if #gates==0 then if not silent then logAdd("BUS / NO STARGATE INTERFACE DETECTED") end else if not silent then logAdd("BUS / "..#gates.." STARGATE INTERFACE(S) READY") end end
 lastScan=computer.uptime()
end
local function read() return API.read(current()) end
local function loadBook() book={};local f=io.open(bookCfg,"r");if not f then return end;local raw=f:read("*a");f:close();local ok,data=pcall(serialization.unserialize,raw);if ok and type(data)=="table" then book=data end end
local function saveBook() local f=io.open(bookCfg,"w");if not f then logAdd("ADDRESS BOOK / WRITE ERROR");return end;f:write(serialization.serialize(book));f:close();logAdd("ADDRESS BOOK / SAVED") end
local function normalize(a) return tostring(a or ""):gsub("[^0-9A-Za-z]",""):upper() end
local function validAddress(a) a=normalize(a);return #a==7 or #a==9 end
local function dial(a)
 a=normalize(a or target);target=a;if not validAddress(a) then logAdd("DIAL / ADDRESS MUST HAVE 7 OR 9 SYMBOLS");return end
 local g=current();if not g then logAdd("DIAL / NO INTERFACE SELECTED");return end
 local d=API.read(g);if not d.localOK or d.localAddress=="" then logAdd("DIAL / INTERFACE NOT CONNECTED TO A GATE");return end
 local needOK,need,needErr=API.energyToDial(g,a);if needOK and tonumber(need) and tonumber(need)>d.energy then logAdd("DIAL / INSUFFICIENT ENERGY");return end
 local ok,x,e=API.dial(g,a);if ok then logAdd("DIAL / SEQUENCE STARTED / "..a) else logAdd("DIAL / ERROR / "..tostring(e or x or needErr)) end
end
local function disconnect() local g=current();if not g then return end;local ok,x,e=API.disconnect(g);logAdd(ok and "GATE / DISCONNECT COMMAND SENT" or "GATE / ERROR / "..tostring(e or x)) end
local function iris() local g=current();if not g then return end;local d=API.read(g);local open=string.lower(d.iris or "")=="closed";local ok,x,e;if open then ok,x,e=API.openIris(g) else ok,x,e=API.closeIris(g) end;logAdd(ok and (open and "IRIS / OPEN COMMAND SENT" or "IRIS / CLOSE COMMAND SENT") or "IRIS / ERROR / "..tostring(e or x)) end
local function drawHeader(d)
 fill(1,1,W,5,C.black);text(2,1,"BULDACITY // SGCraft2",C.cyan,C.black);text(2,2,"STARGATE CONTROL SYSTEM / OPEN COMPUTERS",C.muted,C.black);local s=d and d.state or "NO INTERFACE";text(math.max(2,W-20),1,fit(s,18),stateColor(s),C.black);text(2,4,fit(notice,W-4),C.muted,C.black);Visual.line(gpu,1,5,W,C.cyan)
end
local function drawBus(x,y,w,h)
 panel(x,y,w,h,"INTERFACE BUS",C.blue)
 if #gates==0 then text(x+2,y+3,"NO STARGATE COMPONENT",C.red,C.metal);text(x+2,y+5,"Check Stargate Interface -> OC cable",C.muted,C.metal) else for i,g in ipairs(gates) do local yy=y+2+(i-1)*4;if yy+2>y+h-3 then break end;local d=API.read(g);local active=i==selected;fill(x+1,yy,w-2,3,active and C.metal2 or C.metal);text(x+2,yy,active and ">" or " ",C.cyan,active and C.metal2 or C.metal);text(x+4,yy,fit(g.address,w-7),C.white,active and C.metal2 or C.metal);text(x+4,yy+1,fit(d.state,w-7),stateColor(d.state),active and C.metal2 or C.metal);text(x+4,yy+2,g.primary and "PRIMARY" or "COMPONENT",C.muted,active and C.metal2 or C.metal);buttons["gate"..i]={x=x+1,y=yy,w=w-2,h=3} end end
 button("rescan",x+2,y+h-3,w-4,2,"RESCAN BUS",C.blue)
end
local function drawTelemetry(x,y,w,h,d)
 panel(x,y,w,h,"GATE TELEMETRY",C.yellow);local function row(n,l,v,c) text(x+2,y+n,l,C.muted,C.metal);text(x+13,y+n,fit(v,w-15),c or C.white,C.metal) end
 row(2,"STATE",d.state,stateColor(d.state));row(4,"DIRECTION",d.direction=="" and "-" or d.direction,C.white);row(6,"CHEVRONS",tostring(d.engaged).." / 9",C.orange);row(8,"ENERGY",string.format("%.1f",d.energy),C.yellow);row(10,"IRIS",d.iris,d.iris=="Closed" and C.green or C.yellow);row(12,"LOCAL",d.localAddress=="" and "-" or d.localAddress,C.white);row(14,"REMOTE",d.remoteAddress=="" and "-" or d.remoteAddress,C.cyan);text(x+2,y+16,"API",C.muted,C.metal);text(x+13,y+16,d.ok and "HEALTHY" or "ERROR",d.ok and C.green or C.red,C.metal)
end
local function drawControl(y) panel(2,y,W-3,5,"COMMAND DECK",C.green);button("home",4,y+2,8,2,"HOME",C.cyan,page=="HOME");button("dial",14,y+2,9,2,"DIAL",C.purple,page=="DIAL");button("book",25,y+2,12,2,"ADDRESS",C.blue,page=="BOOK");button("iris",39,y+2,9,2,"IRIS",C.yellow);button("disconnect",50,y+2,14,2,"DISCONNECT",C.red);button("diag",66,y+2,11,2,"DIAGNOSTIC",C.cyan,page=="DIAG");button("log",79,y+2,6,2,"LOG",C.cyan,page=="LOG") end
local function drawHome(d)
 local left=math.floor(W*.60);Visual.gate(gpu,2,7,left-3,H-19,d,anim);drawBus(left,7,W-left-1,H-19);drawTelemetry(left,math.floor(H*.55),W-left-1,H-36,d)
end
local function drawDial()
 panel(2,7,W-3,H-8,"DIALING CONSOLE",C.purple);text(5,9,"DESTINATION",C.muted,C.metal);fill(17,8,math.min(31,W-42),3,C.metal2);text(19,9,target=="" and "ENTER ADDRESS" or target,C.cyan,C.metal2);button("clear",W-20,8,7,3,"CLEAR",C.red);button("dialnow",W-12,8,8,3,"DIAL",C.green)
 local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";local cols=10;local bw=math.max(5,math.floor((W-9-(cols-1))/cols));for i=1,#chars do local col=(i-1)%cols;local row=math.floor((i-1)/cols);button("key"..i,4+col*(bw+1),14+row*2,bw,1,chars:sub(i,i),C.blue) end;text(5,H-4,"7 or 9 symbols / keyboard supported",C.muted,C.metal)
end
local function filteredBook() local out={};local q=search:lower();for i,v in ipairs(book) do local s=(v.name or "").." "..(v.address or "").." "..(v.group or "");if q=="" or s:lower():find(q,1,true) then out[#out+1]={index=i,data=v} end end;return out end
local function drawBook()
 panel(2,7,W-3,H-8,"ADDRESS BOOK",C.blue);text(5,9,"FILTER",C.muted,C.metal);fill(13,8,28,3,C.metal2);text(15,9,search=="" and "type to search" or search,C.cyan,C.metal2);local list=filteredBook();local yy=13;if #list==0 then text(5,13,"NO STORED GATES",C.muted,C.metal) end
 for i,item in ipairs(list) do if yy+2>H-4 then break end;local v=item.data;local active=i==bookSelected;fill(4,yy,W-8,3,active and C.metal2 or C.metal);text(6,yy,fit(v.name,W-30),C.white,active and C.metal2 or C.metal);text(6,yy+1,fit(v.address,18),C.cyan,active and C.metal2 or C.metal);text(27,yy+1,fit(v.group or "DEFAULT",18),C.muted,active and C.metal2 or C.metal);buttons["book"..i]={x=4,y=yy,w=W-8,h=3};yy=yy+4 end
 button("bookDial",W-20,8,8,3,"DIAL",C.green);text(5,H-4,"Address records: {name,address,group}",C.muted,C.metal)
end
local function drawDiag(d)
 panel(2,7,W-3,H-8,"HARDWARE / API DIAGNOSTIC",C.cyan);local function check(y,l,ok,detail) text(6,y,ok and "[ OK ]" or "[FAIL]",ok and C.green or C.red,C.metal);text(14,y,fit(l,22),C.white,C.metal);text(38,y,fit(detail,W-42),ok and C.muted or C.red,C.metal) end
 check(10,"COMPONENT BUS",#gates>0,"stargate x"..#gates);check(12,"STATE API",d.ok,d.ok and d.state or d.error);check(14,"LOCAL ADDRESS",d.localOK,d.localOK and d.localAddress or d.localError);check(16,"REMOTE ADDRESS",d.remoteOK,d.remoteOK and d.remoteAddress or d.remoteError);check(18,"ENERGY API",d.energyOK,d.energyOK and tostring(d.energy) or d.energyError);check(20,"IRIS API",d.irisOK,d.irisOK and d.iris or d.irisError);text(6,23,"INTERFACE",C.muted,C.metal);text(18,23,current() and current().address or "-",C.cyan,C.metal);text(6,25,"METHODS",C.muted,C.metal);local names={};for n in pairs(d.methods or {}) do names[#names+1]=n end;table.sort(names);text(14,25,fit(table.concat(names,", "),W-18),C.white,C.metal)
end
local function drawLog()
 panel(2,7,W-3,H-8,"SYSTEM LOG",C.cyan);for i,s in ipairs(logs) do if 8+i>H-4 then break end;text(5,7+i,fit(s,W-9),C.muted,C.metal) end;button("clearlog",W-18,8,10,3,"CLEAR LOG",C.red)
end
local function draw()
 buttons={};local d=read();drawHeader(d);if page=="HOME" then drawHome(d) elseif page=="DIAL" then drawDial() elseif page=="BOOK" then drawBook() elseif page=="DIAG" then drawDiag(d) elseif page=="LOG" then drawLog() end;drawControl(H-6);gpu.setBackground(C.bg);gpu.setForeground(C.white)
end
local function handle(id)
 if not id then return end
 if id=="home" then page="HOME" elseif id=="dial" then page="DIAL" elseif id=="book" then page="BOOK" elseif id=="diag" then page="DIAG" elseif id=="log" then page="LOG" elseif id=="rescan" then scan(false) elseif id=="iris" then iris() elseif id=="disconnect" then disconnect() elseif id=="clear" then target="" elseif id=="dialnow" then dial() elseif id=="clearlog" then logs={};notice="LOG / CLEARED" elseif id=="bookDial" then local list=filteredBook();if list[bookSelected] then target=list[bookSelected].data.address;page="DIAL";dial(target) end elseif id:sub(1,4)=="gate" then selected=tonumber(id:sub(5)) or selected;saveInterface() elseif id:sub(1,3)=="key" then local i=tonumber(id:sub(4));local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";target=normalize(target..chars:sub(i,i)) end
end
scan(true);loadBook();logAdd("SYSTEM / SGCraft2 ONLINE");draw()
while running do
 local e={event.pull(0.25)};if e[1]=="touch" then handle(hit(e[3],e[4]));draw() elseif e[1]=="key_down" then local ch=e[3];if ch==28 then dial() elseif ch==14 then target=target:sub(1,-2) elseif ch==1 then page="HOME" elseif ch>=32 and ch<=126 then target=normalize(target..string.char(ch)) end;draw() elseif e[1]=="sgStargateStateChange" or e[1]=="sgDialIn" or e[1]=="sgDialOut" or e[1]=="sgChevronEngaged" or e[1]=="sgIrisStateChange" then notice="SGCRAFT EVENT / "..tostring(e[1]);draw() end;anim=anim+.25;if computer.uptime()-lastScan>3 then scan(true);draw() end end
