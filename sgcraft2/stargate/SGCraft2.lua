-- SGCraft2 cinematic Stargate control console
-- OpenComputers / Minecraft 1.7.10 / SGCraft 1.13.x
-- Graphical SGC / SG-1 inspired HUD: animated gate, chevrons, horizon,
-- iris, telemetry, persistent address book and event-driven feedback.
local component=require("component")
local event=require("event")
local computer=require("computer")
local serialization=require("serialization")
local gpu=assert(component.gpu,"GPU component required")
local API=dofile("/home/sgcraft2/lib/SGCraftAPI.lua")
local Visual=dofile("/home/sgcraft2/lib/SGCraftVisual.lua")

local W,H=gpu.getResolution()
local C=Visual.C
local page="HOME"
local gates={}
local selected=1
local target=""
local book={}
local bookSelected=1
local search=""
local searchMode=false
local logs={}
local buttons={}
local notice="SYSTEM INITIALISING"
local anim=0
local running=true
local nextScan=0
local nextFrame=0
local nextStateLog=0
local lastState=""
local lastEngaged=-1
local lastIris=""
local interfaceCfg="/home/sgcraft2-interface.cfg"
local bookCfg="/home/sgcraft2-addressbook.cfg"

local function fill(x,y,w,h,c) Visual.fill(gpu,x,y,w,h,c) end
local function text(x,y,s,c,b) Visual.text(gpu,x,y,s,c,b) end
local function fit(s,n) return Visual.fit(s,n) end
local function panel(x,y,w,h,title,accent)
  if w<4 or h<2 then return end
  fill(x,y,w,h,C.metal)
  Visual.line(gpu,x,y,w,accent)
  text(x+2,y,"[ "..fit(title,w-5).." ]",C.white,accent)
  if h>2 then Visual.line(gpu,x+1,y+h-1,w-2,C.edge) end
end
local function button(id,x,y,w,h,label,accent,active)
  if x<1 or y<1 or x+w-1>W or y+h-1>H then return end
  buttons[id]={x=x,y=y,w=w,h=h}
  local bg=active and C.white or accent
  local fg=active and accent or C.white
  fill(x,y,w,h,bg)
  text(x+math.max(1,math.floor((w-#label)/2)),y+math.floor((h-1)/2),fit(label,w-2),fg,bg)
end
local function hit(x,y)
  for id,b in pairs(buttons) do
    if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end
  end
end
local function logAdd(s)
  logs[#logs+1]=os.date("%H:%M:%S").."  "..tostring(s)
  while #logs>24 do table.remove(logs,1) end
  notice=tostring(s)
end
local function current() return gates[selected] end
local function stateColor(s)
  if s=="Connected" then return C.green end
  if s=="Dialling" or s=="Opening" or s=="Closing" then return C.cyan end
  if s=="Idle" then return C.yellow end
  if s=="API ERROR" then return C.orange end
  if s=="NO INTERFACE" then return C.red end
  return C.red
end
local function normalize(a) return tostring(a or ""):gsub("[^0-9A-Za-z]",""):upper() end
local function validAddress(a) a=normalize(a);return #a==7 or #a==9 end

local function saveInterface()
  local f=io.open(interfaceCfg,"w")
  if f then f:write(current() and current().address or "");f:close() end
end
local function loadInterface()
  local f=io.open(interfaceCfg,"r")
  if not f then return nil end
  local a=f:read("*l");f:close();return a
end
local function scan(silent)
  local old=current() and current().address
  local preferred=loadInterface()
  gates=API.list();selected=1
  local wanted=preferred or old
  if wanted then for i,g in ipairs(gates) do if g.address==wanted then selected=i;break end end end
  if #gates==0 then
    if not silent then logAdd("BUS / NO STARGATE INTERFACE DETECTED") end
  elseif not silent then
    logAdd("BUS / "..#gates.." STARGATE INTERFACE(S) READY")
  end
  nextScan=computer.uptime()+5
end
local function read() return API.read(current()) end

local function loadBook()
  book={}
  local f=io.open(bookCfg,"r")
  if not f then return end
  local raw=f:read("*a");f:close()
  local ok,data=pcall(serialization.unserialize,raw)
  if ok and type(data)=="table" then book=data end
end
local function saveBook(silent)
  local f=io.open(bookCfg,"w")
  if not f then logAdd("ADDRESS BOOK / WRITE ERROR");return false end
  f:write(serialization.serialize(book));f:close()
  if not silent then logAdd("ADDRESS BOOK / SAVED / "..#book.." RECORDS") end
  return true
end
local function addAddress(a,name,group)
  a=normalize(a)
  if not validAddress(a) then logAdd("ADDRESS / INVALID SYMBOL COUNT");return false end
  for _,v in ipairs(book) do
    if normalize(v.address)==a then
      v.name=name or v.name
      v.group=group or v.group
      saveBook(true);logAdd("ADDRESS / UPDATED / "..a);return true
    end
  end
  book[#book+1]={name=name or ("GATE "..a),address=a,group=group or "RECENT"}
  bookSelected=#book
  saveBook(true);logAdd("ADDRESS / SAVED / "..a);return true
end
local function saveRemote()
  local d=read()
  if d.remoteAddress=="" then logAdd("ADDRESS / NO REMOTE GATE AVAILABLE");return end
  addAddress(d.remoteAddress,"REMOTE "..os.date("%H%M%S"),"RECENT")
end

local function dial(a)
  a=normalize(a or target);target=a
  if not validAddress(a) then logAdd("DIAL / ADDRESS MUST HAVE 7 OR 9 SYMBOLS");return end
  local g=current();if not g then logAdd("DIAL / NO INTERFACE SELECTED");return end
  local d=API.read(g)
  if not d.localOK or d.localAddress=="" then logAdd("DIAL / INTERFACE NOT CONNECTED TO A GATE");return end
  local needOK,need,needErr=API.energyToDial(g,a)
  if needOK and tonumber(need) and tonumber(need)>d.energy then logAdd("DIAL / INSUFFICIENT ENERGY");return end
  local ok,x,e=API.dial(g,a)
  if ok then logAdd("DIAL / SEQUENCE STARTED / "..a) else logAdd("DIAL / ERROR / "..tostring(e or x or needErr)) end
end
local function disconnect()
  local g=current();if not g then return end
  local ok,x,e=API.disconnect(g)
  logAdd(ok and "GATE / DISCONNECT COMMAND SENT" or "GATE / ERROR / "..tostring(e or x))
end
local function iris()
  local g=current();if not g then return end
  local d=API.read(g);local closed=string.lower(tostring(d.iris or ""))=="closed"
  local ok,x,e
  if closed then ok,x,e=API.openIris(g) else ok,x,e=API.closeIris(g) end
  logAdd(ok and (closed and "IRIS / OPEN COMMAND SENT" or "IRIS / CLOSE COMMAND SENT") or "IRIS / ERROR / "..tostring(e or x))
end

local function drawHeader(d)
  fill(1,1,W,5,C.black)
  text(2,1,"STARGATE COMMAND  //  SGCraft2",C.cyan,C.black)
  text(2,2,"TACTICAL GATE CONTROL  /  OPEN COMPUTERS",C.muted,C.black)
  local s=d and d.state or "NO INTERFACE"
  text(math.max(2,W-22),1,fit(s,20),stateColor(s),C.black)
  text(2,4,fit(notice,W-4),C.muted,C.black)
  Visual.line(gpu,1,5,W,C.cyan)
end
local function drawBus(x,y,w,h)
  panel(x,y,w,h,"STARGATE NETWORK",C.blue)
  if #gates==0 then
    text(x+2,y+3,"NO GATE INTERFACE",C.red,C.metal)
    text(x+2,y+5,"Connect the SGCraft interface",C.muted,C.metal)
  else
    for i,g in ipairs(gates) do
      local yy=y+2+(i-1)*4
      if yy+2>y+h-4 then break end
      local d=API.read(g);local active=i==selected
      fill(x+1,yy,w-2,3,active and C.metal2 or C.metal)
      text(x+2,yy,active and "◆" or "◇",active and C.cyan or C.dim,active and C.metal2 or C.metal)
      text(x+4,yy,fit(g.address,w-7),C.white,active and C.metal2 or C.metal)
      text(x+4,yy+1,fit(d.state,w-7),stateColor(d.state),active and C.metal2 or C.metal)
      text(x+4,yy+2,g.primary and "PRIMARY" or "INTERFACE",C.muted,active and C.metal2 or C.metal)
      buttons["gate"..i]={x=x+1,y=yy,w=w-2,h=3}
    end
  end
  button("rescan",x+2,y+h-3,w-4,2,"RESCAN NETWORK",C.blue)
end
local function drawGauge(x,y,w,label,value,maxv,accent)
  text(x,y,label,C.muted,C.metal)
  local n=tonumber(value) or 0;local m=tonumber(maxv) or 1;if m<=0 then m=1 end
  local bw=math.max(6,w-13);local filled=math.floor(math.max(0,math.min(1,n/m))*bw)
  fill(x+10,y,bw,1,C.dim);if filled>0 then fill(x+10,y,filled,1,accent) end
  text(x+10+bw,y,fit(string.format("%.0f",n),5),accent,C.metal)
end
local function drawTelemetry(x,y,w,h,d)
  panel(x,y,w,h,"GATE TELEMETRY",C.yellow)
  local function row(n,l,v,c)
    text(x+2,y+n,l,C.muted,C.metal);text(x+13,y+n,fit(v,w-15),c or C.white,C.metal)
  end
  row(2,"STATE",d.state,stateColor(d.state))
  row(4,"DIRECTION",d.direction=="" and "STANDBY" or d.direction,C.white)
  row(6,"CHEVRONS",tostring(d.engaged).." / 9",C.orange)
  drawGauge(x+2,y+8,math.max(18,w-4),"ENERGY",d.energy,100000,C.yellow)
  row(11,"IRIS",d.iris,string.lower(tostring(d.iris))=="closed" and C.green or C.yellow)
  row(13,"LOCAL",d.localAddress=="" and "—" or d.localAddress,C.white)
  row(15,"REMOTE",d.remoteAddress=="" and "—" or d.remoteAddress,C.cyan)
  text(x+2,y+17,"LINK",C.muted,C.metal);text(x+13,y+17,d.remoteAddress~="" and "ACTIVE" or "IDLE",d.remoteAddress~="" and C.green or C.muted,C.metal)
end
local function drawCommandDeck(y)
  panel(2,y,W-3,5,"COMMAND DECK",C.green)
  button("home",4,y+2,8,2,"HOME",C.cyan,page=="HOME")
  button("dial",14,y+2,9,2,"DIAL",C.purple,page=="DIAL")
  button("book",25,y+2,12,2,"ADDRESS",C.blue,page=="BOOK")
  button("save",39,y+2,9,2,"SAVE",C.green)
  button("iris",50,y+2,8,2,"IRIS",C.yellow)
  button("disconnect",60,y+2,14,2,"DISCONNECT",C.red)
  button("diag",76,y+2,11,2,"DIAGNOSTIC",C.cyan,page=="DIAG")
  button("log",W-12,y+2,10,2,"LOG",C.cyan,page=="LOG")
end
local function drawHome(d)
  local left=math.floor(W*.60)
  Visual.gate(gpu,2,7,left-3,H-19,d,anim)
  drawBus(left,7,W-left-1,math.floor(H*.45))
  drawTelemetry(left,math.floor(H*.45)+7,W-left-1,H-math.floor(H*.45)-15,d)
end
local function drawDial(d)
  panel(2,7,W-3,H-8,"DIALING CONSOLE",C.purple)
  text(5,9,"DESTINATION",C.muted,C.metal)
  fill(17,8,math.min(31,W-42),3,C.metal2)
  text(19,9,target=="" and "ENTER ADDRESS" or target,C.cyan,C.metal2)
  button("clear",W-20,8,7,3,"CLEAR",C.red)
  button("dialnow",W-12,8,8,3,"DIAL",C.green)
  local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local cols=10;local bw=math.max(5,math.floor((W-9-(cols-1))/cols))
  for i=1,#chars do
    local col=(i-1)%cols;local row=math.floor((i-1)/cols)
    button("key"..i,4+col*(bw+1),14+row*2,bw,1,chars:sub(i,i),C.blue)
  end
  local needOK,need=API.energyToDial(current(),target)
  text(5,H-5,"ENERGY REQUIRED",C.muted,C.metal)
  text(21,H-5,needOK and tostring(need or "—") or "—",C.yellow,C.metal)
  text(5,H-3,"ENTER = DIAL   /   BACKSPACE = DELETE   /   HOME = RETURN",C.muted,C.metal)
end
local function filteredBook()
  local out={};local q=search:lower()
  for i,v in ipairs(book) do
    local s=(v.name or "").." "..(v.address or "").." "..(v.group or "")
    if q=="" or s:lower():find(q,1,true) then out[#out+1]={index=i,data=v} end
  end
  return out
end
local function drawBook()
  panel(2,7,W-3,H-8,"STARGATE ADDRESS LIBRARY",C.blue)
  text(5,9,"SEARCH",C.muted,C.metal);fill(13,8,30,3,C.metal2);text(15,9,searchMode and (search=="" and "TYPE TO FILTER" or search) or (search=="" and "PRESS S TO SEARCH" or search),C.cyan,C.metal2)
  button("bookDial",W-20,8,8,3,"DIAL",C.green)
  button("bookSave",W-11,8,7,3,"REMOTE",C.yellow)
  local list=filteredBook();local yy=13
  if #list==0 then text(5,13,"NO STORED GATES",C.muted,C.metal) end
  if bookSelected>#list then bookSelected=math.max(1,#list) end
  for i,item in ipairs(list) do
    if yy+2>H-5 then break end
    local v=item.data;local active=i==bookSelected
    fill(4,yy,W-8,3,active and C.metal2 or C.metal)
    text(6,yy,active and "◆" or "◇",active and C.cyan or C.dim,active and C.metal2 or C.metal)
    text(8,yy,fit(v.name or "UNNAMED",W-32),C.white,active and C.metal2 or C.metal)
    text(8,yy+1,fit(v.address or "",18),C.cyan,active and C.metal2 or C.metal)
    text(29,yy+1,fit(v.group or "DEFAULT",18),C.muted,active and C.metal2 or C.metal)
    buttons["book"..i]={x=4,y=yy,w=W-8,h=3};yy=yy+4
  end
  text(5,H-4,"Persistent storage: "..#book.." address records",C.muted,C.metal)
end
local function drawDiag(d)
  panel(2,7,W-3,H-8,"HARDWARE / API DIAGNOSTIC",C.cyan)
  local function check(y,l,ok,detail)
    text(6,y,ok and "●" or "×",ok and C.green or C.red,C.metal)
    text(10,y,fit(l,23),C.white,C.metal);text(35,y,fit(detail,W-39),ok and C.muted or C.red,C.metal)
  end
  check(10,"COMPONENT BUS",#gates>0,"stargate x"..#gates)
  check(12,"STATE API",d.ok,d.ok and d.state or d.error)
  check(14,"LOCAL ADDRESS",d.localOK,d.localOK and d.localAddress or d.localError)
  check(16,"REMOTE ADDRESS",d.remoteOK,d.remoteOK and d.remoteAddress or d.remoteError)
  check(18,"ENERGY API",d.energyOK,d.energyOK and tostring(d.energy) or d.energyError)
  check(20,"IRIS API",d.irisOK,d.irisOK and d.iris or d.irisError)
  text(6,23,"INTERFACE",C.muted,C.metal);text(18,23,current() and current().address or "—",C.cyan,C.metal)
  text(6,25,"METHODS",C.muted,C.metal)
  local names={};for n in pairs(d.methods or {}) do names[#names+1]=n end;table.sort(names)
  text(14,25,fit(table.concat(names," · "),W-18),C.white,C.metal)
  text(6,27,"EVENTS",C.muted,C.metal);text(14,27,"sgStargateStateChange · sgChevronEngaged · sgIrisStateChange",C.white,C.metal)
end
local function drawLog()
  panel(2,7,W-3,H-8,"SYSTEM EVENT LOG",C.cyan)
  for i,s in ipairs(logs) do if 8+i>H-4 then break end text(5,7+i,fit(s,W-9),C.muted,C.metal) end
  button("clearlog",W-18,8,10,3,"CLEAR LOG",C.red)
end
local function draw()
  buttons={}
  local d=read()
  drawHeader(d)
  if page=="HOME" then drawHome(d)
  elseif page=="DIAL" then drawDial(d)
  elseif page=="BOOK" then drawBook()
  elseif page=="DIAG" then drawDiag(d)
  elseif page=="LOG" then drawLog() end
  drawCommandDeck(H-6)
end

local function handle(id)
  if not id then return end
  if id=="home" then page="HOME"
  elseif id=="dial" then page="DIAL"
  elseif id=="book" then page="BOOK"
  elseif id=="diag" then page="DIAG"
  elseif id=="log" then page="LOG"
  elseif id=="rescan" then scan(false)
  elseif id=="iris" then iris()
  elseif id=="save" or id=="bookSave" then saveRemote()
  elseif id=="disconnect" then disconnect()
  elseif id=="clear" then target=""
  elseif id=="dialnow" then dial()
  elseif id=="clearlog" then logs={};notice="LOG / CLEARED"
  elseif id=="bookDial" then
    local list=filteredBook()
    if list[bookSelected] then target=list[bookSelected].data.address;page="DIAL";dial(target) end
  elseif id:sub(1,4)=="gate" then selected=tonumber(id:sub(5)) or selected;saveInterface();logAdd("INTERFACE / SELECTED / "..tostring(selected))
  elseif id:sub(1,4)=="book" and id~="bookDial" and id~="bookSave" then
    bookSelected=tonumber(id:sub(5)) or bookSelected
    local list=filteredBook()
    if list[bookSelected] then target=normalize(list[bookSelected].data.address) end
  elseif id:sub(1,3)=="key" then
    local i=tonumber(id:sub(4));local chars="1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";target=normalize(target..chars:sub(i,i));searchMode=false
  end
end

local function processGateEvents(d,e)
  local eventName=e[1]
  if eventName=="sgChevronEngaged" then
    local n=tonumber(e[4] or e[3])
    if n then logAdd("CHEVRON / "..n.." / ENGAGED") else logAdd("CHEVRON / ENGAGED") end
  elseif eventName=="sgStargateStateChange" then
    logAdd("GATE STATE / "..tostring(e[4] or e[3] or d.state))
  elseif eventName=="sgIrisStateChange" then
    logAdd("IRIS STATE / "..tostring(e[4] or e[3] or d.iris))
  end
end

scan(true);loadBook();logAdd("SYSTEM / SGCraft2 CINEMATIC CONSOLE ONLINE");draw()
while running do
  local e={event.pull(0.10)}
  local now=computer.uptime()
  if now>=nextScan then scan(true) end
  if now>=nextFrame then
    anim=anim+0.10;nextFrame=now+0.10
    local d=read()
    if d.state~=lastState and now>=nextStateLog then lastState=d.state;nextStateLog=now+0.25;logAdd("STATE / "..tostring(d.state)) end
    if d.engaged~=lastEngaged then lastEngaged=d.engaged;logAdd("CHEVRONS / "..tostring(d.engaged).." / 9") end
    if d.iris~=lastIris then lastIris=d.iris;logAdd("IRIS / "..tostring(d.iris)) end
    draw()
  end
  if e[1]=="touch" then handle(hit(e[3],e[4]));draw()
  elseif e[1]=="key_down" then
    local ch=e[3]
    if searchMode then
      if ch==28 then searchMode=false
      elseif ch==14 then search=search:sub(1,-2)
      elseif ch==1 then searchMode=false
      elseif ch>=32 and ch<=126 then search=search..string.char(ch):lower() end
    else
      if ch==28 then dial()
      elseif ch==14 then target=target:sub(1,-2)
      elseif ch==1 then page="HOME"
      elseif ch==19 then page="DIAL"
      elseif ch==21 then page="BOOK"
      elseif ch==25 then saveRemote()
      elseif ch==31 and page=="BOOK" then searchMode=true
      elseif ch==200 and page=="BOOK" then bookSelected=math.max(1,bookSelected-1)
      elseif ch==208 and page=="BOOK" then bookSelected=bookSelected+1
      elseif ch==203 and page=="DIAL" then target=target:sub(1,-2)
      end
    end
    draw()
  elseif e[1]=="sgStargateStateChange" or e[1]=="sgChevronEngaged" or e[1]=="sgIrisStateChange" then
    processGateEvents(read(),e);draw()
  elseif e[1]=="interrupted" then running=false end
end
