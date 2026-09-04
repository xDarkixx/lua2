-- ReactorBigReactors043A_Network.lua
-- BULDACITY/2 network bridge for Big Reactors 0.4.3A.
-- All BULDACITY Lua programs are loaded from /home.

local component=require("component")
local event=require("event")
local filesystem=require("filesystem")
local shell=require("shell")
local Network=require("Network")

local HOME="/home/"
local CLIENT_NAME="Big Reactors // Control Center"
local CONTROLLER="ReactorBigReactors043A_Touch_Responsive.lua"
pcall(function() shell.setWorkingDirectory("/home") end)
package.path="/home/?.lua;/home/?/init.lua;"..(package.path or "")

local controllerPath=HOME..CONTROLLER
if not filesystem.exists(controllerPath) then error("Big Reactors controller not found: /home/"..CONTROLLER) end

local ok,mode=Network.startClient(CLIENT_NAME,{controller=CONTROLLER,mod="Big Reactors",version="0.4.3A",network=true})
if not ok then error("BULDACITY Big Reactors network unavailable: "..tostring(mode)) end

local function invoke(addr,name,...)
 if not addr then return nil end
 local success,a,b,c,d=pcall(component.invoke,addr,name,...);if success then return a,b,c,d end
end
local function first(kind) for address in component.list(kind) do return address end end
local function reactorData()
 local addr=first("br_reactor")
 if not addr then return {available=false,controller=CONTROLLER,mod="Big Reactors",version="0.4.3A"} end
 return {available=true,address=addr,active=invoke(addr,"getActive")==true,energy=tonumber(invoke(addr,"getEnergyStored")) or 0,energyMax=tonumber(invoke(addr,"getEnergyStoredMax")) or 0,fuel=tonumber(invoke(addr,"getFuelAmount")) or 0,fuelMax=tonumber(invoke(addr,"getFuelAmountMax")) or 0,temperature=tonumber(invoke(addr,"getFuelTemperature")) or 0,rods=tonumber(invoke(addr,"getNumberOfControlRods")) or 0,controller=CONTROLLER,mod="Big Reactors",version="0.4.3A"}
end
local function sendTelemetry(target) if target then Network.send(target,"REACTOR_TELEMETRY",reactorData()) end end

event.listen("modem_message",function(_,receiver,sender,port,distance,p)
 if port~=Network.PORT or not Network.valid(p) then return end
 if p.kind=="REACTOR_REQUEST" then sendTelemetry(sender)
 elseif p.kind=="REACTOR_COMMAND" and type(p.data)=="table" then
  local d=p.data;local addr=first("br_reactor")
  if addr then
   local command=d.command
   if command=="start" then invoke(addr,"setActive",true)
   elseif command=="stop" then invoke(addr,"setActive",false)
   elseif command=="rod" then invoke(addr,"setControlRodLevel",tonumber(d.index) or 0,tonumber(d.level) or 0)
   elseif command=="all_rods" then invoke(addr,"setAllControlRodLevels",tonumber(d.level) or 0) end
   sendTelemetry(sender)
  end
 end
end)

event.timer(2,function()
 local data=reactorData();Network.broadcast("REACTOR_TELEMETRY",data);Network.broadcast("HEARTBEAT",{name=CLIENT_NAME,role="CLIENT",app=CLIENT_NAME,controller=CONTROLLER,mod="Big Reactors",version="0.4.3A",reactor=data,linked=Network.linked,serverAddress=Network.serverAddress})
end,math.huge)

local loaded,err=pcall(dofile,controllerPath)
if not loaded then error("Unable to start /home/"..CONTROLLER..": "..tostring(err)) end
