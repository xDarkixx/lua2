-- SGCraft_Modern.lua
-- BULDACITY // STARGATE COMMAND CENTER v3
-- Minecraft 1.7.10 / SGCraft-1.13.3-mc1.7.10.jar
-- Presentation/controller only. Network stays separate in SGCraftNetwork_Modern.lua.
local component=require("component")
local event=require("event")
local computer=require("computer")
local UI=require("SGCraftUI")
local gpu=component.gpu
local gates={};local selected=1;local page="status";local running=true;local target="";local message="";local log={}
-- OC compatibility: no Lua vararg syntax is used here.
local function safe(o,n,a,b,c,d)
 if not o or type(o[n])~="function" then return nil,"METHOD_UNAVAILABLE" end
 local ok,r1,r2,r3,r4=pcall(o[n],a,b,c,d)
 if ok then return r1,r2,r3,r4 end
 return nil,tostring(r1)
end
local function addLog(s)
 log[#log+1]=os.date("%H:%M:%S").." "..tostring(s)
 while #log>8 do table.remove(log,1) end
end
local function scan()
 gates={}
 for a in component.list("stargate",true) do gates[#gates+1]={address=a,proxy=component.proxy(a)} end
 selected=math.max(1,math.min(selected,math.max(1,#gates)))
 addLog("SCAN: "..#gates.." Stargate Interface(s)")
end
local function selectedGate() return gates[selected] end
local function readGate(g)
 if not g then return nil end
 local s,ch,dir=safe(g.proxy,"stargateState")
 local localAddr=safe(g.proxy,"localAddress")
 local remote=safe(g.proxy,"remoteAddress")
 local energy=safe(g.proxy,"energyAvailable") or 0
 local irisState=safe(g.proxy,"irisState") or "Offline"
 local maxEnergy=100000
 local pct=math.max(0,math.min(100,(tonumber(energy) or 0)/maxEnergy*100))
 return {address=g.address,state=s or "Unknown",chevrons=tonumber(ch) or 0,direction=dir or "-",localAddress=localAddr or "-",remote=remote or "-",energy=energy,iris=irisState,energyPct=pct}
end
local function dial()
 local g=selectedGate();if not g or target=="" then addLog("DIAL: gate/target missing");return end
 local r,e=safe(g.proxy,"dial",target)
 if r==nil then addLog("DIAL ERROR: "..tostring(e)) else addLog("DIAL START: "..target) end
end
local function disconnect()
 local g=selectedGate();if not g then return end
 local r,e=safe(g.proxy,"disconnect")
 if r==nil and e then addLog("DISCONNECT ERROR: "..tostring(e)) else addLog("DISCONNECTED") end
end
local function iris(open)
 local g=selectedGate();if not g then return end
 local method=open and "openIris" or "closeIris"
 local r,e=safe(g.proxy,method)
 if r==nil and e then addLog("IRIS ERROR: "..tostring(e)) else addLog(open and "IRIS OPEN" or "IRIS CLOSED") end
end
local function sendMessage()
 local g=selectedGate();if not g or message=="" then return end
 local r,e=safe(g.proxy,"sendMessage",message)
 if r==nil and e then addLog("MSG ERROR: "..tostring(e)) else addLog("MSG SENT: "..message) end
end
local function draw()
 local g=selectedGate();local gd=readGate(g)
 local data={page=page,gates={},selected=selected,gate=gd,title="STARGATE COMMAND / "..string.upper(page),target=target,message=message,log=log,energyNeed=nil}
 for i,v in ipairs(gates) do data.gates[i]={address=v.address,state=safe(v.proxy,"stargateState") or "Offline"} end
 if g and page=="dial" and target~="" then data.energyNeed=safe(g.proxy,"energyToDial",target) end
 if page=="dial" then data.title="DIALING CONSOLE // TARGET "..(target=="" and "EMPTY" or target)
 elseif page=="iris" then data.title="IRIS SECURITY // ACCESS CONTROL"
 elseif page=="link" then data.title="LINK // MESSAGE CHANNEL" end
 UI.draw(data)
end
scan();draw()
local lastDraw=computer.uptime()
while running do
 local ev,_,a,b,key,ch=event.pull(0.2)
 if ev=="key_down" then
  if key==17 then running=false
  elseif key==2 then page="status"
  elseif key==3 then page="gates"
  elseif key==4 then page="dial"
  elseif key==5 then page="iris"
  elseif key==6 then page="link"
  elseif key==31 then scan()
  elseif key==15 and #gates>0 then selected=(selected%#gates)+1
  elseif key==32 and page=="dial" then dial()
  elseif key==45 then disconnect()
  elseif key==24 and page=="iris" then iris(true)
  elseif key==46 and page=="iris" then iris(false)
  elseif key==50 and page=="link" then sendMessage()
  elseif key==14 then if page=="dial" then target=target:sub(1,-2) elseif page=="link" then message=message:sub(1,-2) end
  elseif ch and ch>=32 and ch<=126 then if page=="dial" then target=target..string.char(ch):upper() elseif page=="link" then message=message..string.char(ch) end end
  draw()
 elseif ev=="touch" then
  local x,y=a,b;local handled=false
  for id in pairs(UI.buttons) do
   if UI.hit(id,x,y) then
    handled=true
    if id=="status" or id=="gates" or id=="dial" or id=="iris" or id=="link" then page=id
    elseif id=="scan" then scan()
    elseif id=="dialNow" then dial()
    elseif id=="disconnect" then disconnect()
    elseif id=="openIris" then iris(true)
    elseif id=="closeIris" then iris(false)
    elseif id=="sendMessage" then sendMessage()
    end
    draw();break
   end
  end
  if not handled and page=="gates" and y>=8 and y<=UI.H-5 then local i=math.floor((y-8)/3)+1;if gates[i] then selected=i;draw() end end
 elseif ev=="sgStargateStateChange" or ev=="sgChevronEngaged" or ev=="sgIrisStateChange" or ev=="sgDialIn" or ev=="sgDialOut" then
  addLog(ev);draw()
 elseif ev=="sgMessageReceived" then addLog("REMOTE MSG: "..tostring(a));draw()
 end
 if computer.uptime()-lastDraw>0.5 then lastDraw=computer.uptime();draw() end
end
gpu.setBackground(0);gpu.setForeground(UI.C.white);gpu.fill(1,1,UI.W,UI.H," ")
