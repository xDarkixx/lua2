-- ReactorBigReactors043A_Network.lua
-- BULDACITY/2 network bridge for the Big Reactors 0.4.3A controller.
-- One normal Tier-3 controller PC = client. BuldacityOS_Tier3.lua = central server.
-- The bridge and the Responsive controller run in the same OpenComputers process.

local component=require("component")
local event=require("event")
local filesystem=require("filesystem")
local Network=require("Network")

local CLIENT_NAME="Big Reactors // Control Center"
local CONTROLLER="ReactorBigReactors043A_Touch_Responsive.lua"

-- OpenOS installations commonly keep downloaded Lua programs in /home.
-- The old version always used /<file>, which caused:
-- "file not found:/ReactorBigReactors043A_Touch_Responsive.lua"
-- when the bridge and controller were installed in /home.
local function findController()
  local candidates={
    "/home/"..CONTROLLER,
    "/"..CONTROLLER,
    CONTROLLER
  }
  for i=1,#candidates do
    if filesystem.exists(candidates[i]) then return candidates[i] end
  end
  return nil
end

local controllerPath=findController()
if not controllerPath then
  error("Big Reactors controller not found. Install "..CONTROLLER.." in /home or /")
end

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
  return {
    available=true,address=addr,
    active=invoke(addr,"getActive")==true,
    energy=tonumber(invoke(addr,"getEnergyStored")) or 0,
    energyMax=tonumber(invoke(addr,"getEnergyStoredMax")) or 0,
    fuel=tonumber(invoke(addr,"getFuelAmount")) or 0,
    fuelMax=tonumber(invoke(addr,"getFuelAmountMax")) or 0,
    temperature=tonumber(invoke(addr,"getFuelTemperature")) or 0,
    rods=tonumber(invoke(addr,"getNumberOfControlRods")) or 0,
    controller=CONTROLLER,mod="Big Reactors",version="0.4.3A"
  }
end

local function sendTelemetry(target)
  Network.send(target,"REACTOR_TELEMETRY",reactorData())
end

event.listen("modem_message",function(_,receiver,sender,port,distance,p)
  if port~=Network.PORT or not Network.valid(p) then return end
  if p.kind=="REACTOR_REQUEST" then
    sendTelemetry(sender)
  elseif p.kind=="REACTOR_COMMAND" and type(p.data)=="table" then
    local d=p.data
    local addr=first("br_reactor")
    if addr then
      local command=d.command
      if command=="start" then
        invoke(addr,"setActive",true)
      elseif command=="stop" then
        invoke(addr,"setActive",false)
      elseif command=="rod" then
        invoke(addr,"setControlRodLevel",tonumber(d.index) or 0,tonumber(d.level) or 0)
      elseif command=="all_rods" then
        invoke(addr,"setAllControlRodLevels",tonumber(d.level) or 0)
      end
      sendTelemetry(sender)
    end
  end
end)

event.timer(2,function()
  local data=reactorData()
  Network.broadcast("REACTOR_TELEMETRY",data)
  Network.broadcast("HEARTBEAT",{
    name=CLIENT_NAME,role="CLIENT",app=CLIENT_NAME,controller=CONTROLLER,
    mod="Big Reactors",version="0.4.3A",reactor=data
  })
end,math.huge)

-- Start the controller from the location where it was actually installed.
local loaded,err=pcall(dofile,controllerPath)
if not loaded then
  error("Unable to start "..CONTROLLER.." from "..controllerPath..": "..tostring(err))
end
