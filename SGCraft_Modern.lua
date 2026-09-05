-- BULDACITY SGCraft INTERFACE
-- Original-style Stargate control console for OpenComputers / SGCraft 1.13.3
-- Designed for Tier 3 screens, 160x50 preferred. Smaller screens are supported.
-- The controller deliberately uses the Stargate Interface component UUID like SGCX.

local component = require("component")
local event = require("event")
local computer = require("computer")
local gpu = component.gpu

local W,H = gpu.getResolution()
local running = true
local page = "HOME"
local selected = 1
local target = ""
local message = ""
local notice = "SYSTEM READY"
local focus = "ADDRESS"
local gates = {}
local buttons = {}
local logs = {}
local dirty = true
local anim = 0
local lastScan = 0

local C = {
  bg=0x05080D, black=0x000000, panel=0x0B1119, panel2=0x111A25,
  panel3=0x172432, edge=0x31475B, cyan=0x20DFFF, blue=0x3E78FF,
  green=0x35E58A, yellow=0xF2C94C, red=0xF04E5E, purple=0x9B68FF,
  white=0xE8F3FA, muted=0x788D9D, dim=0x3D5263
}

local function safeCall(fn,...)
  if type(fn) ~= "function" then return false,nil,"method unavailable" end
  local ok,a,b,c,d = pcall(fn,...)
  if ok then return true,a,b,c,d end
  return false,nil,a
end

local function call(p, name, ...)
  if not p then return false,nil,"no interface" end
  local ok,a,b,c,d = pcall(function() return p[name](...) end)
  if ok then return true,a,b,c,d end
  return false,nil,a
end

local function setfg(c) gpu.setForeground(c or C.white) end
local function setbg(c) gpu.setBackground(c or C.bg) end
local function text(x,y,s,fg,bg)
  if x<1 or y<1 or x>W or y>H then return end
  setfg(fg);setbg(bg);gpu.set(x,y,tostring(s or ""))
end
local function fill(x,y,w,h,bg)
  if w<=0 or h<=0 then return end
  setbg(bg);gpu.fill(x,y,w,h," ")
end
local function line(x,y,w,c) fill(x,y,w,1,c) end
local function fit(s,n)
  s=tostring(s or "")
  if n<1 then return "" end
  if #s<=n then return s end
  if n<=3 then return s:sub(1,n) end
  return s:sub(1,n-3).."..."
end
local function logAdd(s)
  logs[#logs+1]=os.date("%H:%M:%S").."  "..tostring(s)
  while #logs>6 do table.remove(logs,1) end
  notice=tostring(s);dirty=true
end
local function panel(x,y,w,h,title,accent)
  fill(x,y,w,h,C.panel);line(x,y,w,accent)
  if w>=10 then text(x+2,y,"[ "..fit(title,w-5).." ]",C.white,accent) end
  if h>=3 then line(x+1,y+h-1,w-2,C.edge) end
end
local function button(id,x,y,w,h,label,accent,active)
  if w<3 or h<1 or x<1 or y<1 or x+w-1>W or y+h-1>H then return end
  buttons[id]={x=x,y=y,w=w,h=h}
  local bg=active and C.white or accent
  local fg=active and accent or C.white
  fill(x,y,w,h,bg)
  local yy=y+math.floor((h-1)/2)
  local xx=x+math.max(1,math.floor((w-#label)/2))
  text(xx,yy,fit(label,w-2),fg,bg)
end
local function hit(x,y)
  for id,b in pairs(buttons) do
    if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end
  end
end

local function interfaceList()
  local found={}
  local primary=component.getPrimary("stargate")
  if primary then
    local a=primary.address
    if a then found[a]={address=a,proxy=primary,primary=true} end
  end
  for a in component.list("stargate",true) do
    if not found[a] then
      local p=component.proxy(a)
      if p then found[a]={address=a,proxy=p,primary=false} end
    end
  end
  local out={}
  for _,g in pairs(found) do out[#out+1]=g end
  table.sort(out,function(a,b) return a.address<b.address end)
  return out
end

local function scan(silent)
  local oldAddress=gates[selected] and gates[selected].address
  gates=interfaceList()
  selected=1
  if oldAddress then
    for i,g in ipairs(gates) do if g.address==oldAddress then selected=i end end
  end
  if #gates==0 then
    if not silent then logAdd("SCAN: NO STARGATE INTERFACE") end
  else
    if not silent then logAdd("SCAN: "..#gates.." INTERFACE(S) / SGCX MODE") end
  end
  lastScan=computer.uptime();dirty=true
end

local function current() return gates[selected] end
local function stateName(s) return s and tostring(s) or "Offline" end
local function stateColor(s)
  s=stateName(s)
  if s=="Connected" then return C.green end
  if s=="Dialling" or s=="Opening" or s=="Closing" then return C.cyan end
  if s=="Idle" then return C.yellow end
  if s=="Offline" then return C.red end
  return C.muted
end

local function telemetry(g)
  if not g then return nil end
  local p=g.proxy
  local ok,s,e,d=call(p,"stargateState")
  local okLA,la=call(p,"localAddress")
  local okRA,ra=call(p,"remoteAddress")
  local okPW,pw=call(p,"energyAvailable")
  local okIR,ir=call(p,"irisState")
  local state=ok and stateName(s) or "Offline"
  return {
    component=g.address,state=state,engaged=tonumber(e) or 0,direction=(d and tostring(d)~="" and tostring(d) or "-"),
    localAddress=okLA and tostring(la or "-") or "-",remoteAddress=okRA and tostring(ra or "-") or "-",
    power=tonumber(pw) or 0,iris=okIR and tostring(ir or "Offline") or "Offline",
    stateOK=ok,stateError=ok and nil or tostring(e or "unknown error")
  }
end

local function gateAction(method,...)
  local g=current()
  if not g then logAdd("COMMAND: NO INTERFACE SELECTED");return false end
  local ok,a,b=call(g.proxy,method,...)
  if not ok then logAdd(string.upper(method)..": "..tostring(b));return false end
  if a==nil and type(b)=="string" then logAdd(string.upper(method)..": "..b);return false end
  return true
end

local function dial()
  target=target:gsub("[^0-9A-Za-z]",""):upper()
  if #target~=7 and #target~=9 then logAdd("DIAL: ENTER 7 OR 9 SYMBOLS");dirty=true;return end
  if gateAction("dial",target) then logAdd("DIAL STARTED  "..target) end
end
local function disconnect()
  if gateAction("disconnect") then logAdd("GATE DISCONNECTED") end
end
local function iris(open)
  if gateAction(open and "openIris" or "closeIris") then logAdd(open and "IRIS OPEN" or "IRIS CLOSED") end
end
local function sendMessage()
  if message=="" then logAdd("LINK: MESSAGE EMPTY");return end
  if gateAction("sendMessage",message) then logAdd("MESSAGE SENT") end
end

local function clearTarget() target="";focus="ADDRESS";dirty=true end
local function backspaceTarget() target=target:sub(1,#target-1);dirty=true end
local function addSymbol(s)
  if #target<9 then target=(target..s):upper();dirty=true end
end

local function header()
  fill(1,1,W,5,C.black)
  text(2,1,"STARGATE CONTROL",C.cyan,C.black)
  if W>=40 then text(2,2,"BULDACITY // SGCraft INTERFACE",C.white,C.black) end
  local g=current();local gd=telemetry(g)
  local status=gd and gd.state or "NO INTERFACE"
  text(math.max(2,W-22),1,fit(status,21),stateColor(status),C.black)
  text(2,4,fit(notice,W-4),C.muted,C.black)
  line(1,5,W,C.cyan)
end

local function drawGateVisual(x,y,w,h,gd)
  panel(x,y,w,h,"STARGATE",C.cyan)
  local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)
  local r=math.max(6,math.min(math.floor(w*.30),math.floor(h*.62)))
  local active=gd and gd.state~="Offline"
  local ring=active and C.cyan or C.dim
  for deg=0,359,10 do
    local a=math.rad(deg);local px=math.floor(cx+math.cos(a)*r+.5);local py=math.floor(cy+math.sin(a)*r*.46+.5)
    text(px,py,(deg%30==0) and "O" or ".",ring,C.panel)
  end
  if active then
    local pulseOn=(math.floor(anim*8)%2)==0
    for rr=2,r-3,3 do
      local n=math.max(12,math.floor(2*math.pi*rr))
      for i=0,n-1,math.max(1,math.floor(n/20)) do
        local a=i/n*math.pi*2+anim*.7
        local px=math.floor(cx+math.cos(a)*rr+.5);local py=math.floor(cy+math.sin(a)*rr*.46+.5)
        text(px,py,pulseOn and "." or "o",pulseOn and C.white or C.cyan,C.panel)
      end
    end
  else
    text(cx-4,cy,"OFFLINE",C.red,C.panel)
  end
  for i=1,9 do
    local a=math.rad(-90+(i-1)*40)
    local px=math.floor(cx+math.cos(a)*(r+2)+.5);local py=math.floor(cy+math.sin(a)*(r+2)*.46+.5)
    local on=gd and i<=gd.engaged
    text(px,py,on and "#" or "+",on and C.yellow or C.dim,C.panel)
  end
  if gd then text(cx-math.floor(#gd.state/2),y+h-3,gd.state,stateColor(gd.state),C.panel) end
end

local function drawFleet(x,y,w,h)
  panel(x,y,w,h,"INTERFACES",C.blue)
  if #gates==0 then
    text(x+2,y+3,"NO SGCraft INTERFACE",C.red,C.panel)
    text(x+2,y+5,"PRESS SCAN",C.muted,C.panel)
    button("scan",x+2,y+7,w-4,2,"SCAN",C.cyan,false)
    return
  end
  for i,g in ipairs(gates) do
    local yy=y+2+(i-1)*4
    if yy+2>y+h-2 then break end
    local gd=telemetry(g);local active=i==selected;local bg=active and C.panel3 or C.panel
    buttons["gate_"..i]={x=x+1,y=yy,w=w-2,h=3};fill(x+1,yy,w-2,3,bg)
    text(x+2,yy,active and ">" or " ",C.cyan,bg)
    text(x+4,yy,fit(g.address,w-7),C.white,bg)
    text(x+4,yy+1,fit(gd and gd.state or "Offline",w-7),stateColor(gd and gd.state),bg)
    text(x+4,yy+2,g.primary and "PRIMARY / SGCX" or "STARGATE",C.muted,bg)
  end
  button("scan",x+2,y+h-3,w-4,2,"RESCAN",C.blue,false)
end

local function drawTelemetry(x,y,w,h,gd)
  panel(x,y,w,h,"TELEMETRY",C.yellow)
  if not gd then text(x+2,y+3,"NO INTERFACE",C.red,C.panel);return end
  local function row(n,l,v,c)
    text(x+2,y+n,l,C.muted,C.panel);text(x+12,y+n,fit(v,w-14),c or C.white,C.panel)
  end
  row(2,"STATE",gd.state,stateColor(gd.state))
  row(4,"DIRECTION",gd.direction,C.white)
  row(6,"CHEVRON",gd.engaged.." / 9",C.yellow)
  row(8,"POWER",string.format("%.1f SU",gd.power),C.yellow)
  row(10,"IRIS",gd.iris,gd.iris=="Closed" and C.green or C.yellow)
  row(12,"LOCAL",gd.localAddress,C.white)
  row(14,"REMOTE",gd.remoteAddress,C.cyan)
  text(x+2,y+16,"INTERFACE UUID",C.muted,C.panel)
  text(x+2,y+17,fit(gd.component,w-4),C.white,C.panel)
  text(x+2,y+h-3,gd.stateOK and "INTERFACE OK" or "INTERFACE ERROR",gd.stateOK and C.green or C.red,C.panel)
end

local function drawDial(x,y,w,h)
  panel(x,y,w,h,"DIAL ADDRESS",C.purple)
  text(x+2,y+2,"TARGET",C.muted,C.panel)
  fill(x+10,y+1,w-12,3,focus=="ADDRESS" and C.panel3 or C.panel2)
  text(x+12,y+2,fit(target=="" and "ENTER ADDRESS" or target,w-16),C.cyan,C.panel3)
  local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local cols=12;local bw=math.max(4,math.floor((w-4-(cols-1))/cols));local startY=y+5
  for i=1,#chars do
    local c=(i-1)%cols;local r=math.floor((i-1)/cols)
    button("key_"..chars:sub(i,i),x+2+c*(bw+1),startY+r*2,bw,1,chars:sub(i,i),C.blue,false)
  end
  button("back",x+w-22,y+1,6,3,"<",C.yellow,false)
  button("clear",x+w-15,y+1,7,3,"CLR",C.red,false)
  button("dial",x+w-7,y+1,7,3,"DIAL",C.green,false)
end

local function drawHome(x,y,w,h,gd)
  drawGateVisual(x,y,w,h,gd)
end

local function drawBottom(y)
  local compact=W<100 or H<30
  if page=="DIAL" and not compact then drawDial(2,y,W-3,12);return end
  panel(2,y,W-3,compact and 4 or 5,"COMMAND",C.green)
  if page=="IRIS" then
    button("open",4,y+2,12,2,"OPEN IRIS",C.green,false);button("close",17,y+2,12,2,"CLOSE IRIS",C.red,false)
  elseif page=="LINK" then
    text(4,y+2,"MSG",C.muted,C.panel);text(10,y+2,fit(message=="" and "TYPE MESSAGE" or message,W-32),C.white,C.panel);button("send",W-20,y+1,9,3,"SEND",C.green,false)
  else
    button("dialNav",4,y+1,10,2,"DIAL",C.purple,false)
    button("irisNav",15,y+1,10,2,"IRIS",C.yellow,false)
    button("linkNav",26,y+1,10,2,"LINK",C.green,false)
    button("disconnect",37,y+1,14,2,"DISCONNECT",C.red,false)
    button("interfaces",52,y+1,12,2,"INTERFACE",C.blue,false)
    button("scan",65,y+1,9,2,"SCAN",C.cyan,false)
  end
end

local function drawNav()
  local y=H-2;local labels={{"HOME",C.cyan},{"DIAL",C.purple},{"IRIS",C.yellow},{"LINK",C.green},{"SCAN",C.blue}}
  local bw=math.max(8,math.floor((W-7)/#labels));local x=2
  for _,v in ipairs(labels) do button("nav_"..v[1],x,y,bw,2,v[1],v[2],page==v[1]);x=x+bw+1 end
end

local function drawLog(y,h)
  panel(2,y,W-3,h,"EVENT LOG",C.edge)
  local max=math.max(1,h-2);local s=math.max(1,#logs-max+1)
  for i=s,#logs do text(4,y+1+i-s,fit(logs[i],W-6),C.muted,C.panel) end
end

local function draw()
  W,H=gpu.getResolution();buttons={};fill(1,1,W,H,C.bg);header()
  local compact=W<100 or H<30
  local top=7;local navH=2;local bottomH=(page=="DIAL" and not compact) and 12 or (compact and 5 or 6)
  local logH=compact and 3 or 5
  local contentH=H-top-bottomH-logH-navH-1
  if contentH<8 then contentH=8 end
  local left=compact and 20 or math.max(24,math.min(31,math.floor(W*.20)))
  local right=compact and 23 or math.max(27,math.min(35,math.floor(W*.23)))
  local center=W-left-right-7
  if compact then center=W-left-5 end
  local gd=telemetry(current())
  if page=="DIAL" and not compact then
    drawFleet(2,top,left,contentH);drawGateVisual(4+left,top,center,contentH,gd);drawTelemetry(W-right-1,top,right,contentH,gd)
  else
    drawFleet(2,top,left,contentH);drawHome(4+left,top,center,contentH,gd);drawTelemetry(W-right-1,top,right,contentH,gd)
  end
  drawLog(H-navH-logH-bottomH,logH)
  drawBottom(H-navH-bottomH)
  drawNav()
  dirty=false
end

local function keyboard(char,code)
  if code==28 or code==156 then
    if page=="DIAL" then dial() end
    return
  end
  if code==14 then
    if focus=="ADDRESS" then backspaceTarget() else message=message:sub(1,#message-1);dirty=true end
    return
  end
  if char and char>0 and char<256 then
    local s=string.char(char)
    if focus=="ADDRESS" and s:match("[0-9A-Za-z]") then addSymbol(s)
    elseif focus=="MESSAGE" and #message<80 then message=message..s;dirty=true end
  end
end

local function click(id)
  if id=="scan" then scan(false);return end
  if id=="disconnect" then disconnect();return end
  if id=="open" then iris(true);return end
  if id=="close" then iris(false);return end
  if id=="send" then sendMessage();return end
  if id=="dial" then dial();return end
  if id=="back" then backspaceTarget();return end
  if id=="clear" then clearTarget();return end
  if id=="dialNav" or id=="nav_DIAL" then page="DIAL";focus="ADDRESS";dirty=true;return end
  if id=="irisNav" or id=="nav_IRIS" then page="IRIS";dirty=true;return end
  if id=="linkNav" or id=="nav_LINK" then page="LINK";focus="MESSAGE";dirty=true;return end
  if id=="nav_HOME" then page="HOME";dirty=true;return end
  if id=="nav_SCAN" then scan(false);return end
  if id=="interfaces" then page="HOME";if #gates>0 then selected=selected%#gates+1;logAdd("INTERFACE "..selected.." SELECTED") else scan(false) end;dirty=true;return end
  local gi=id:match("^gate_(%d+)$")
  if gi then selected=tonumber(gi) or selected;logAdd("INTERFACE "..selected.." SELECTED");dirty=true;return end
  local key=id:match("^key_(.)$")
  if key then focus="ADDRESS";addSymbol(key);return end
end

scan(true)
logAdd(#gates>0 and "SGCX-COMPATIBLE INTERFACE READY" or "NO INTERFACE - PRESS SCAN")

while running do
  if dirty or computer.uptime()-lastScan>2 then draw() end
  if computer.uptime()-lastScan>2 then lastScan=computer.uptime() end
  anim=computer.uptime()
  local ev,a,b,c,d=event.pull(0.10)
  if ev=="touch" then
    local id=hit(b,c)
    if id then click(id) else notice="TOUCH "..tostring(b)..","..tostring(c);dirty=true end
  elseif ev=="key_down" then
    -- OpenComputers: address, character, keycode, player
    keyboard(b,c)
  elseif ev=="component_added" or ev=="component_removed" then
    if a then scan(false) end
  elseif ev=="sgStargateStateChange" or ev=="sgChevronEngaged" or ev=="sgDialIn" or ev=="sgDialOut" or ev=="sgIrisStateChange" then
    dirty=true
  elseif ev=="interrupted" then
    running=false
  end
end

fill(1,1,W,H,C.black)
text(2,2,"BULDACITY SGCraft Interface stopped.",C.cyan,C.black)
