-- ReactorBigReactors043A_Network.lua
-- BULDACITY/2 network bridge for the Big Reactors 0.4.3A controller.
-- One normal Tier-3 controller PC = client. BuldacityOS_Tier3.lua = central server.
-- The bridge and the Responsive controller run in the same OpenComputers process.

local component=require("component")
local event=require("event")
local computer=require("computer")
local Network=require("Network")

local CLIENT_NAME="Big Reactors // Control Center"
local CONTROLLER="ReactorBigReactors043A_Touch_Responsive.lua"
local ok,mode=Network.startClient(CLIENT_NAME,{controller=CONTROLLER,mod="Big Reactors",version="0.4.3A",network=true})
if not ok then
  error("BULDACITY Big Reactors network unavailable: "..tostring(mode))
end

local function invoke(addr,name,...)
  if not addr then return nil end
  local success,a,b,c,d=pcall(component.invoke,addr,name,...)
  if success then return a,b,c,d end
end

local function first(kind)
  for address in component.list(kind) do return address end
end

local function reactorData()
  local addr=first("br_reactor")
  if not addr then
    return {available=false,controller=CONTROLLER,mod="Big Reactors",version="0.4.3A"}
  end
  local active=invoke(addr,"getActive") == true
  local energy=tonumber(invoke(addr,"getEnergyStored")) or 0
  local energyMax=tonumber(invoke(addr,"getEnergyStoredMax")) or 0
  local fuel=tonumber(invoke(addr,"getFuelAmount")) or 0
  local fuelMax=tonumber(invoke(addr,"getFuelAmountMax")) or 0
  local temp=tonumber(invoke(addr,"getFuelTemperature")) or 0
  return {
    available=true,address=addr,active=active,
    energy=energy,energyMax=energyMax,
    fuel=fuel,fuelMax=fuelMax,temperature=temp,
    rods=tonumber(invoke(addr,"getNumberOfControlRods")) or 0,
    controller=CONTROLLER,mod="Big Reactors",version="0.4.3A"
  }
end

local function sendTelemetry(target)
  Network.send(target,"REACTOR_TELEMETRY",reactorData())
end

-- The wrapper is the network bridge. It also accepts explicit reactor commands
-- from the central desktop and turns them into real Big Reactors component calls.
event.listen("modem_message",function(_,receiver,sender,port,distance,p)
  if port~=Network.PORT or not Network.valid(p) then return end
  if p.kind=="REACTOR_REQUEST" then
    sendTelemetry(sender)
  elseif p.kind=="REACTOR_COMMAND" and type(p.data)=="table" then
    local d=p.data
    local addr=first("br_reactor")
    if addr then
      local command=d.command
      if command=="start" then invoke(addr,"setActive",true)
      elseif command=="stop" then invoke(addr,"setActive",false)
      elseif command=="rod" then
        invoke(addr,"setControlRodLevel",tonumber(d.index) or 0,tonumber(d.level) or 0)
      elseif command=="all_rods" then
        invoke(addr,"setAllControlRodLevels",tonumber(d.level) or 0)
      end
      sendTelemetry(sender)
    end
  end
end)

-- Regular telemetry keeps the central desktop informed even when no screen
-- remote session is open. The server can therefore build a real reactor panel.
event.timer(2,function()
  local data=reactorData()
  Network.broadcast("REACTOR_TELEMETRY",data)
end,math.huge)

-- Run the original Responsive controller. Its UI and local controls stay intact.
local loaded,err=pcall(dofile,"/"..CONTROLLER)
if not loaded then
  error("Unable to start "..CONTROLLER..": "..tostring(err))
end
