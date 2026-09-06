-- BULDACITY SGCraft API adapter
-- OpenComputers 1.7.10 / SGCraft 1.13.x compatible.
-- Important: SGCraft 1.13.x returns nil,error on API failures instead of
-- throwing Lua errors. We therefore distinguish pcall success from API success.

local component = require("component")
local API = {}

local function invoke(proxy, name, ...)
  if not proxy then return false, nil, "no interface" end

  local fn = proxy[name]
  if type(fn) ~= "function" then
    return false, nil, "method unavailable: " .. tostring(name)
  end

  local argc = select("#", ...)
  local ok, a, b, c

  -- Do not depend on table.unpack/table.pack here. Some older OC Lua builds
  -- differ in which table helpers are available.
  if argc == 0 then
    ok, a, b, c = pcall(function()
      return fn()
    end)
  elseif argc == 1 then
    local arg1 = select(1, ...)
    ok, a, b, c = pcall(function()
      return fn(arg1)
    end)
  elseif argc == 2 then
    local arg1, arg2 = select(1, ...), select(2, ...)
    ok, a, b, c = pcall(function()
      return fn(arg1, arg2)
    end)
  else
    local args = {...}
    ok, a, b, c = pcall(function()
      return fn(unpack(args))
    end)
  end

  if not ok then
    return false, nil, tostring(a)
  end

  -- SGCraft 1.13.x reports failures as nil,error_message.
  if a == nil then
    return false, nil, tostring(b or ("API call failed: " .. tostring(name)))
  end

  return true, a, b, c
end

API.invoke = invoke

local function methodMap(address)
  local result = {}
  local ok, methods = pcall(component.methods, address)
  if ok and type(methods) == "table" then
    for name, value in pairs(methods) do
      if value then result[name] = true end
    end
  end
  return result
end

function API.list()
  local result = {}
  local primary = nil

  if component.isAvailable("stargate") then
    local ok, p = pcall(component.getPrimary, "stargate")
    if ok and p and p.address then primary = p.address end
  end

  for address in component.list("stargate") do
    local ok, proxy = pcall(component.proxy, address)
    if ok and proxy then
      result[#result + 1] = {
        address = address,
        proxy = proxy,
        primary = (address == primary),
        methods = methodMap(address)
      }
    end
  end

  table.sort(result, function(a,b) return a.address < b.address end)
  return result
end

function API.read(gate)
  if not gate then
    return {
      present=false, state="NO INTERFACE", engaged=0, direction="",
      localAddress="", remoteAddress="", energy=0, iris="Unknown",
      error="No SGCraft interface detected"
    }
  end

  local p = gate.proxy
  local okState, state, stateError, stateExtra = invoke(p, "stargateState")
  local okLocal, localAddress, localError = invoke(p, "localAddress")
  local okRemote, remoteAddress, remoteError = invoke(p, "remoteAddress")
  local okEnergy, energy, energyError = invoke(p, "energyAvailable")
  local okIris, iris, irisError = invoke(p, "irisState")

  local engaged = 0
  local direction = ""
  if okState then
    engaged = tonumber(stateError or 0) or 0
    direction = tostring(stateExtra or "")
  end

  local errors = {}
  if not okState then errors[#errors+1] = "stargateState: " .. tostring(stateError) end
  if not okLocal then errors[#errors+1] = "localAddress: " .. tostring(localError) end
  if not okRemote then errors[#errors+1] = "remoteAddress: " .. tostring(remoteError) end
  if not okEnergy then errors[#errors+1] = "energyAvailable: " .. tostring(energyError) end
  if not okIris then errors[#errors+1] = "irisState: " .. tostring(irisError) end

  return {
    present=true,
    state=okState and tostring(state) or "API ERROR",
    engaged=engaged,
    direction=direction,
    localAddress=okLocal and tostring(localAddress or "") or "",
    remoteAddress=okRemote and tostring(remoteAddress or "") or "",
    energy=okEnergy and tonumber(energy or 0) or 0,
    iris=okIris and tostring(iris or "Unknown") or "API ERROR",
    ok=okState,
    localOK=okLocal,
    remoteOK=okRemote,
    energyOK=okEnergy,
    irisOK=okIris,
    error=table.concat(errors, " | "),
    localError=tostring(localError or ""),
    remoteError=tostring(remoteError or ""),
    energyError=tostring(energyError or ""),
    irisError=tostring(irisError or ""),
    methods=gate.methods or {}
  }
end

function API.dial(gate, address)
  return invoke(gate and gate.proxy, "dial", address)
end
function API.disconnect(gate)
  return invoke(gate and gate.proxy, "disconnect")
end
function API.openIris(gate)
  return invoke(gate and gate.proxy, "openIris")
end
function API.closeIris(gate)
  return invoke(gate and gate.proxy, "closeIris")
end
function API.sendMessage(gate, message)
  return invoke(gate and gate.proxy, "sendMessage", message)
end
function API.energyToDial(gate, address)
  return invoke(gate and gate.proxy, "energyToDial", address)
end

return API
