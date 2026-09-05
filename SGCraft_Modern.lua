-- BULDACITY // SGCraft INTERFACE
-- OpenComputers / SGCraft 1.13.3 / Minecraft 1.7.10
-- Touch-first Stargate control center, adaptive 80x25 .. 160x50.
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local W,H=gpu.getResolution()
local running,page,selected=true,"HOME",1
local target,message,notice="","","SYSTEM ONLINE"
local gates,log,buttons={}, {}, {}
local dirty=true
local pulse,lastAnim=0,0
local C={bg=0x050811,panel=0x0B1220,panel2=0x101A2A,panel3=0x182A40,line=0x24415C,cyan=0x20E6FF,blue=0x4D7CFF,green=0x37F59A,yellow=0xFFD35A,red=0xFF4D69,purple=0xB96CFF,white=0xEAF7FF,muted=0x71879E,dark=0x1B293A,black=0x000000}
local function safe(fn,...)
 if type(fn)~="function" then return nil,"method unavailable" end
 local ok,a,b,c,d=pcall(fn,...);if ok then return a,b,c,d end;return nil,a
end
local function text(x,y,s,fg,bg) if x<1 or y<1 or x>W or y>H then return end;gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or "")) end
local function fill(x,y,w,h,bg) if w>0 and h>0 then gpu.setBackground(bg or C.bg);gpu.fill(x,y,w,h," ") end end
local function fit(s,n) s=tostring(s or "");if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
local function logAdd(s) log[#log+1]=os.date("%H:%M:%S").."  "..tostring(s);while #log>8 do table.remove(log,1) end;notice=tostring(s);dirty=true end
local function panel(x,y,w,h,title,accent) fill(x,y,w,h,C.panel);fill(x,y,w,1,accent);if w>4 then text(x+2,y,"[ "..fit(title,w-5).." ]",C.white,accent) end;if h>2 then fill(x+1,y+h-1,w-2,1,C.line) end end
local function button(id,x,y,w,label,accent,active) if w<3 or y<1 or y+1>H then return end;buttons[id]={x=x,y=y,w=w,h=2};local bg=active and C.white or accent;local fg=active and accent or C.white;fill(x,y,w,2,bg);text(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),fg,bg) end
local function hit(x,y) for id,b in pairs(buttons) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end end end
local function scan() gates={};for address in component.list("stargate",true) do local p=component.proxy(address);if p then gates[#gates+1]={address=address,proxy=p} end end;if selected>#gates then selected=#gates end;if selected<1 then selected=1 end;logAdd("SCAN: "..#gates.." Stargate interface(s)") end
local function gate() return gates[selected] end
local function read(g)
 if not g then return nil end
 local p=g.proxy;local state,engaged,direction=safe(p.stargateState);local la=safe(p.localAddress);local ra=safe(p.remoteAddress);local energy=safe(p.energyAvailable);local iris=safe(p.irisState);local need=nil;if target~="" then need=safe(p.energyToDial,target) end
 return {component=g.address,state=state or "Offline",engaged=tonumber(engaged) or 0,direction=(direction and direction~="" and direction) or "-",localAddress=(la and la~="" and la) or "-",remoteAddress=(ra and ra~="" and ra) or "-",energy=tonumber(energy) or 0,iris=iris or "Offline",need=tonumber(need) or 0}
end
local function callGate(method,...)
 local g=gate();if not g then logAdd("NO STARGATE SELECTED");return false end
 local fn=g.proxy[method];if type(fn)~="function" then logAdd(string.upper(method)..": method unavailable");return false end
 local a,b=safe(fn,...);if a==nil and b then logAdd(string.upper(method)..": "..tostring(b));return false end;return true
end
local function dial() if target=="" then logAdd("DIAL: enter a 7/9 symbol address");return end;if #target~=7 and #target~=9 then logAdd("DIAL: address must contain 7 or 9 symbols");return end;if callGate("dial",target) then logAdd("DIAL -> "..target) end end
local function disconnect() if callGate("disconnect") then logAdd("WORMHOLE DISCONNECTED") end end
local function iris(open) if callGate(open and "openIris" or "closeIris") then logAdd(open and "IRIS OPEN" or "IRIS CLOSED") end end
local function send() if message=="" then logAdd("LINK: message empty");return end;if callGate("sendMessage",message) then logAdd("LINK TX -> "..message) end end
local function stateColor(s) if s=="Connected" then return C.green elseif s=="Dialling" or s=="Opening" then return C.cyan elseif s=="Closing" then return C.yellow elseif s=="Offline" then return C.red end;return C.muted end
local function layout()
 local compact=W<100 or H<30;local top=6;local logH=compact and 3 or 4;local bottomH=compact and 3 or (page=="DIAL" and 8 or 5);local contentH=H-top-logH-bottomH-2;if contentH<8 then contentH=8 end
 local leftW=compact and 18 or math.max(22,math.min(30,math.floor(W*.22)));local rightW=compact and 20 or math.max(25,math.min(34,math.floor(W*.25)));local centerW=W-leftW-rightW-7;if compact then centerW=W-leftW-5 end
 return {compact=compact,top=top,logH=logH,bottomH=bottomH,contentH=contentH,leftW=leftW,rightW=rightW,centerW=centerW}
end
local function drawHeader() fill(1,1,W,4,C.panel);text(2,1,"BULDACITY",C.cyan,C.panel);if W>=55 then text(14,1,"// SGCraft INTERFACE",C.white,C.panel) end;if W>=90 then text(W-20,1,"SGCRAFT / OC",C.muted,C.panel) end;text(2,2,"STARGATE CONTROL",C.green,C.panel);text(21,2,fit(notice,W-22),C.muted,C.panel);fill(1,4,W,1,C.cyan) end
local function drawFleet(L)
 local x,y,w,h=2,L.top,L.leftW,L.contentH;panel(x,y,w,h,"GATES",C.blue);if #gates==0 then text(x+2,y+3,fit("NO GATE - TOUCH SCAN",w-4),C.red,C.panel);return end
 for i,g in ipairs(gates) do local yy=y+2+(i-1)*3;if yy+1>=y+h-1 then break end;local gd=read(g);local active=i==selected;local bg=active and C.panel3 or C.panel;buttons["gate_"..i]={x=x+1,y=yy,w=w-2,h=2};fill(x+1,yy,w-2,2,bg);text(x+2,yy,active and ">" or " ",C.cyan,bg);text(x+4,yy,fit(g.address,w-7),C.white,bg);text(x+4,yy+1,fit(gd.state,w-7),stateColor(gd.state),bg) end
end
local function drawTelemetry(x,y,w,h,gd)
 panel(x,y,w,h,"POWER / TELEMETRY",C.cyan);if not gd then text(x+2,y+3,"NO GATE",C.red,C.panel);return end
 local function row(n,l,v,c) text(x+2,y+n,l,C.muted,C.panel);text(x+12,y+n,fit(v,w-14),c or C.white,C.panel) end
 row(2,"STATE",gd.state,stateColor(gd.state));row(4,"DIR",gd.direction,C.white);row(6,"CHEVRON",gd.engaged.." / 9",C.cyan);row(8,"POWER",gd.energy.." SU",C.yellow);row(9,"RF",math.floor(gd.energy*80).." RF",C.yellow);row(10,"EU",math.floor(gd.energy*20).." EU",C.yellow)
 local maxE=math.max(gd.energy,gd.need,1);local pct=math.min(100,gd.energy/maxE*100);local bw=math.max(5,w-4);fill(x+2,y+11,bw,1,C.dark);fill(x+2,y+11,math.floor(bw*pct/100),1,C.yellow)
 row(13,"COST",gd.need>0 and (gd.need.." SU") or "-",C.yellow);row(15,"IRIS",gd.iris,gd.iris=="Closed" and C.green or C.yellow);text(x+2,y+17,"LOCAL",C.muted,C.panel);text(x+2,y+18,fit(gd.localAddress,w-4),C.white,C.panel);text(x+2,y+20,"REMOTE",C.muted,C.panel);text(x+2,y+21,fit(gd.remoteAddress,w-4),C.cyan,C.panel)
end
local function drawRing(cx,cy,r,gd)
 local active=gd and gd.state~="Offline" and gd.state~="Idle";local pulseOn=math.floor(pulse*6)%2==0;local ring=active and C.cyan or C.dark
 for deg=0,359,8 do local a=math.rad(deg);text(math.floor(cx+math.cos(a)*r+.5),math.floor(cy+math.sin(a)*r*.48+.5),(deg%24==0) and "O" or ".",ring,C.panel) end
 if active then for rr=2,r-4,3 do local n=math.max(8,math.floor(2*math.pi*rr));for i=0,n-1,math.max(1,math.floor(n/16)) do local a=i/n*math.pi*2+pulse*.55;text(math.floor(cx+math.cos(a)*rr+.5),math.floor(cy+math.sin(a)*rr*.48+.5),pulseOn and "." or "o",pulseOn and C.blue or C.cyan,C.panel) end end else text(cx-3,cy,"IDLE",C.muted,C.panel) end
 local engaged=gd and gd.engaged or 0;for i=1,9 do local a=math.rad(-90+(i-1)*40);local x=math.floor(cx+math.cos(a)*(r+2)+.5);local y=math.floor(cy+math.sin(a)*(r+2)*.48+.5);local on=i<=engaged;text(x,y,on and "◆" or "◇",on and (pulseOn and C.white or C.cyan) or C.dark,C.panel);if r>=9 and y+1<=H then text(x,y+1,tostring(i),on and C.cyan or C.muted,C.panel) end end
end
local function drawCenter(L,gd)
 local x,y,w,h=4+L.leftW,L.top,L.centerW,L.contentH;panel(x,y,w,h,"STARGATE VISUAL",C.purple);local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)+1;local r=math.max(6,math.min(math.floor(w*.31),math.floor(h*.62)));drawRing(cx,cy,r,gd);if gd then text(cx-math.floor(#gd.state/2),math.min(y+h-2,cy+math.floor(r*.55)),gd.state,stateColor(gd.state),C.panel) end
end
local function drawDialPad(L,y)
 panel(2,y,W-3,L.bottomH,"DIAL ADDRESS",C.purple);text(4,y+1,"TARGET",C.muted,C.panel);text(13,y+1,fit(target=="" and "TOUCH SYMBOLS / KEYBOARD" or target,W-32),C.cyan,C.panel)
 local chars="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";local bw=math.max(5,math.floor((W-8)/12));local startY=y+3;buttons={}
 for i=1,#chars do local col=(i-1)%12;local row=math.floor((i-1)/12);button("sym_"..chars:sub(i,i),2+col*(bw+1),startY+row*2,bw,chars:sub(i,i),C.blue,false) end
 button("back",W-31,y+1,7,"<",C.yellow,false);button("clear",W-23,y+1,9,"CLR",C.red,false);button("dial",W-13,y+1,11,"DIAL",C.green,false)
end
local function drawBottom(L,gd)
 local y=H-L.bottomH-1;if page=="DIAL" and not L.compact then drawDialPad(L,y);return end
 panel(2,y,W-3,L.bottomH,page=="IRIS" and "IRIS SECURITY" or page=="LINK" and "STARGATE LINK" or "TOUCH COMMANDS",C.green)
 if L.compact then text(4,y+2,page=="DIAL" and fit(target=="" and "TYPE ADDRESS" or target,W-8) or "TOUCH NAV BELOW",C.cyan,C.panel)
 elseif page=="IRIS" then text(4,y+2,"CURRENT",C.muted,C.panel);text(14,y+2,gd and gd.iris or "-",C.yellow,C.panel);button("open",W-45,y+1,10,"OPEN",C.green,false);button("close",W-33,y+1,10,"CLOSE",C.red,false);button("backhome",W-21,y+1,10,"HOME",C.blue,false)
 elseif page=="LINK" then text(4,y+2,"MESSAGE",C.muted,C.panel);text(14,y+2,fit(message=="" and "TYPE MESSAGE" or message,W-45),C.white,C.panel);button("send",W-24,y+1,10,"SEND",C.green,false);button("backhome",W-12,y+1,10,"HOME",C.blue,false)
 else text(4,y+2,"TOUCH COMMANDS",C.muted,C.panel);button("dialnav",W-51,y+1,9,"DIAL",C.purple,false);button("irisnav",W-41,y+1,9,"IRIS",C.yellow,false);button("linknav",W-31,y+1,9,"LINK",C.green,false);button("off",W-21,y+1,10,"GATE OFF",C.red,false) end
end
local function drawLog(L)
 local y=H-L.bottomH-L.logH-1;panel(2,y,W-3,L.logH,"EVENT LOG",C.line);local maxLines=L.logH-2;local start=math.max(1,#log-maxLines+1);for i=start,#log do text(4,y+1+i-start,fit(log[i],W-6),C.muted,C.panel) end
end
local function drawNav(L)
 if page=="DIAL" and not L.compact then return end
 local labels={{"HOME",C.cyan},{"GATES",C.blue},{"DIAL",C.purple},{"IRIS",C.yellow},{"LINK",C.green},{"SCAN",C.cyan}};local y=H-3;local bw=math.max(7,math.floor((W-8)/#labels));local x=2
 for _,v in ipairs(labels) do button(v[1],x,y,bw,v[1],v[2],page==v[1]);x=x+bw+1 end
end
local function drawAll()
 W,H=gpu.getResolution();local L=layout();buttons={};fill(1,1,W,H,C.bg);drawHeader();local gd=read(gate());drawFleet(L);drawCenter(L,gd);drawTelemetry(W-L.rightW-1,L.top,L.rightW,L.contentH,gd);drawLog(L);drawBottom(L,gd);drawNav(L);dirty=false
end
local function keyAction(code)
 if code==16 then running=false;return end
 if code==15 then page=page=="HOME" and "DIAL" or "HOME";dirty=true;return end
 if code==19 then scan();return end
 if page=="DIAL" then if code==14 then target=target:sub(1,-2);dirty=true;return end;if code==46 then target="";dirty=true;return end end
end
local function click(id)
 if not id then return end
 if id:sub(1,5)=="gate_" then selected=tonumber(id:sub(6)) or selected;page="HOME";dirty=true;return end
 if id:sub(1,4)=="sym_" then if #target<9 then target=target..id:sub(5,5);dirty=true end;return end
 if id=="back" then target=target:sub(1,-2);dirty=true;return end;if id=="clear" then target="";dirty=true;return end;if id=="dial" then dial();dirty=true;return end
 if id=="open" then iris(true);dirty=true;return end;if id=="close" then iris(false);dirty=true;return end;if id=="off" then disconnect();dirty=true;return end;if id=="send" then send();dirty=true;return end
 if id=="HOME" or id=="backhome" then page="HOME";dirty=true;return end;if id=="GATES" then page="GATES";dirty=true;return end;if id=="DIAL" or id=="dialnav" then page="DIAL";dirty=true;return end;if id=="IRIS" or id=="irisnav" then page="IRIS";dirty=true;return end;if id=="LINK" or id=="linknav" then page="LINK";dirty=true;return end;if id=="SCAN" then scan();dirty=true;return end
end
scan();logAdd("TOUCH CONTROL READY")
while running do
 local now=computer.uptime();local nw,nh=gpu.getResolution();if W~=nw or H~=nh then W,H=nw,nh;dirty=true end
 if now-lastAnim>.18 then pulse=pulse+.18;lastAnim=now;dirty=true end
 if dirty then drawAll() end
 local ev,_,a,b,c=event.pull(.10)
 if ev=="key_down" then
  keyAction(c)
  if page=="DIAL" and a and a>=32 and a<=126 then local s=string.char(a):upper();if s:match("[0-9A-Z]") and #target<9 then target=target..s;dirty=true end end
 elseif ev=="touch" then click(hit(b,c))
 elseif ev=="component_added" or ev=="component_removed" then scan();dirty=true
 elseif ev=="sgStargateStateChange" or ev=="sgChevronEngaged" or ev=="sgIrisStateChange" or ev=="sgDialIn" or ev=="sgDialOut" then dirty=true end
end
fill(1,1,W,H,C.black);text(2,2,"BULDACITY // SGCraft interface stopped",C.cyan,C.black)
