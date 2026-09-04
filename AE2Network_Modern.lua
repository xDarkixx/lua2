-- AE2Network_Modern.lua
-- Modern responsive LED dashboard for AE2 rv3 beta 6 / OC 1.8.10 / MC 1.7.10
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local me=component.me_controller
if not me then error("Kein me_controller gefunden.") end
local W,H=80,25; local page="HOME"; local running=true; local items={}; local crafts={}; local msg="SYSTEM READY"; local last=0
local C={bg=0x05080D,panel=0x0D141D,panel2=0x111D29,line=0x26384A,blue=0x35B9FF,cyan=0x55F5FF,green=0x39FF88,red=0xFF4F68,yellow=0xFFE36E,purple=0xB47CFF,white=0xF4FAFF,grey=0x7F95A8,off=0x24313C}
local ui={}
local function resize() local mw,mh=gpu.maxResolution();local cw,ch=gpu.getResolution();W,H=mw or cw,mh or ch;if W<40 then W=40 end;if H<16 then H=16 end;pcall(gpu.setResolution,W,H);W,H=gpu.getResolution() end
local function sc(fn,...) local ok,a,b,c=pcall(fn,...);if ok then return a,b,c end end
local function txt(x,y,s,fg,bg) gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s)) end
local function box(x,y,w,h,t,c) gpu.setBackground(C.panel);gpu.fill(x,y,w,h," ");gpu.setBackground(C.line);gpu.fill(x,y,w,1," ");txt(x+2,y,"◆ "..t,c or C.cyan,C.panel) end
local function fit(s,n) s=tostring(s or "");return #s<=n and s or s:sub(1,math.max(1,n-1)).."…" end
local function led(x,y,on,c,label) local cc=on and c or C.off;gpu.setBackground(cc);gpu.fill(x,y,2,1," ");txt(x+3,y,fit(label or (on and "ONLINE" or "OFFLINE"),18),on and cc or C.grey,C.panel) end
local function bar(x,y,w,p,c) p=math.max(0,math.min(100,tonumber(p) or 0));local n=math.floor(w*p/100);gpu.setBackground(C.panel2);gpu.fill(x,y,w,1," ");if n>0 then gpu.setBackground(c);gpu.fill(x,y,n,1," ") end end
local function btn(id,x,y,w,label,c,on) ui[id]={x=x,y=y,w=w,h=2};gpu.setBackground(on and C.white or c);gpu.fill(x,y,w,2," ");txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),on and c or C.white,on and C.white or c) end
local function hit(id,x,y) local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
local function amount(e) return type(e)=="table" and tonumber(e.size or e.amount or e.count or 0) or 0 end
local function name(e) return type(e)=="table" and tostring(e.label or e.name or e.id or "unknown") or tostring(e or "--") end
local function refresh() local a=sc(me.getItemsInNetwork);items=type(a)=="table" and a or {};local b=sc(me.getCraftables);crafts=type(b)=="table" and b or {};last=computer.uptime();msg="NETWORK SCANNED" end
local function header(title) gpu.setBackground(C.panel);gpu.fill(1,1,W,4," ");txt(3,2,"◈ AE2 // ME CONTROL",C.cyan,C.panel);txt(math.max(25,math.floor(W*.34)),2,fit(title,math.max(8,W-28)),C.white,C.panel);led(math.max(5,W-24),2,true,C.green,"ONLINE");gpu.setBackground(C.cyan);gpu.fill(1,4,W,1," ") end
local function footer() local y=H-3;local gap=1;local n=5;local bw=math.max(7,math.floor((W-4-(n-1)*gap)/n));local x=2;btn("home",x,y,bw,"HOME",C.purple,page=="HOME");x=x+bw+gap;btn("items",x,y,bw,"ITEMS",C.cyan,page=="ITEMS");x=x+bw+gap;btn("craft",x,y,bw,"CRAFT",C.purple,page=="CRAFTS");x=x+bw+gap;btn("refresh",x,y,bw,"SCAN",C.yellow);x=x+bw+gap;btn("quit",x,y,bw,"EXIT",C.red);txt(3,H,fit(msg,W-6),C.grey,C.panel) end
local function drawHome() header("NETWORK OVERVIEW");local cy=6;local h=H-10;local two=W>=82;local gap=2;local pw=two and math.floor((W-6-gap)/2) or W-6;box(3,cy,pw,h,"ME NETWORK",C.cyan);led(6,cy+3,true,C.green,"ME CONTROLLER");txt(6,cy+6,"ITEM TYPES",C.grey,C.panel);txt(22,cy+6,#items,C.cyan,C.panel);txt(6,cy+8,"CRAFTABLES",C.grey,C.panel);txt(22,cy+8,#crafts,C.purple,C.panel);txt(6,cy+10,"LAST SCAN",C.grey,C.panel);txt(22,cy+10,string.format("%.1fs",computer.uptime()-last),C.white,C.panel);if two then local x=3+pw+gap;box(x,cy,pw,h,"SYSTEM LOAD",C.blue);local total=math.max(1,#items+#crafts);local ip=#items/total*100;bar(x+4,cy+5,pw-8,ip,C.cyan);txt(x+4,cy+7,"STORAGE INDEX",C.grey,C.panel);txt(x+4,cy+9,string.format("%d ITEM TYPES",#items),C.green,C.panel);txt(x+4,cy+11,string.format("%d CRAFTABLES",#crafts),C.purple,C.panel);end;footer() end
local function drawList() header(page=="ITEMS" and "STORAGE MATRIX" or "CRAFTING MATRIX");local y=6;local h=H-10;local w=W-6;box(3,y,w,h,page=="ITEMS" and "STORED ITEMS" or "CRAFTABLES",page=="ITEMS" and C.cyan or C.purple);local list=page=="ITEMS" and items or crafts;local rows=math.max(1,h-4);for i=1,math.min(rows,#list) do local yy=y+2+i;txt(6,yy,string.format("%02d",i),C.cyan,C.panel);txt(11,yy,fit(name(list[i]),math.max(10,w-35)),C.white,C.panel);txt(W-20,yy,page=="ITEMS" and tostring(amount(list[i])) or "READY",page=="ITEMS" and C.green or C.purple,C.panel) end;if #list==0 then txt(7,y+4,"NO DATA",C.red,C.panel) end;footer() end
local function draw() resize();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");if page=="HOME" then drawHome() else drawList() end end
local function click(x,y) if hit("home",x,y) then page="HOME" elseif hit("items",x,y) then page="ITEMS" elseif hit("craft",x,y) then page="CRAFTS" elseif hit("refresh",x,y) then refresh() elseif hit("quit",x,y) then running=false end end
resize();refresh();draw();while running do local e,a,x,y=event.pull(1);if e=="touch" then click(x,y);draw() elseif e=="key_down" then local c=y;if c==string.byte("q") or c==string.byte("Q") then running=false elseif c==string.byte("r") or c==string.byte("R") then refresh() elseif c==string.byte("i") or c==string.byte("I") then page="ITEMS" elseif c==string.byte("c") or c==string.byte("C") then page="CRAFTS" end;draw() end;if computer.uptime()-last>=5 then refresh();draw() end end
gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")