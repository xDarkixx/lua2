-- BULDACITY SGCraft API adapter
-- OpenComputers 1.7.10 / SGCraft 1.13.x compatible.
-- The visual layer is intentionally NOT handled here.
-- This file only isolates hardware/API access so the BULDACITY UI stays unchanged.

local component = require("component")
local API = {}

local function directInvoke(address, name, ...)
  if not address or address == "" then
    return false, nil, "no interface address"
  end

  local argc = select("#", ...)
  local ok, a, b, c

  -- component.invoke(address, method, ...) is the most reliable low-level
  -- OpenComputers call for old 1.7.10 environments. It avoids differences
  -- between bound component proxy functions and method wrappers.
  if argc == 0 then
    ok, a, b, c = pcall(component.invoke, address, name)
  elseif argc == 1 then
    ok, a, b, c = pcall(component.invoke, address, name, select(1, ...))
  elseif argc == 2 then
    ok, a, b, c = pcall(component.invoke, address, name, select(1, ...), select(2, ...))
  else
    local args = {...}
    ok, a, b, c = pcall(function()
      return component.invoke(address, name, unpack(args))
    end)
  end

  if not ok then
    return false, nil, tostring(a)
  end

  -- SGCraft 1.13.x returns nil,error_message for API-level failures.
  if a == nil then
    return false, nil, tostring(b or ("API call failed: " .. tostring(name)))
  end

  return true, a, b, c
end

local function proxyInvoke(proxy, address, name, ...)
  -- Keep a proxy fallback for unusual OC component implementations.
  if proxy and type(proxy[name]) == "function" then
    local argc = select("#", ...)
    local ok, a, b, c
    if argc == 0 then
      ok, a, b, c = pcall(proxy[name])
    elseif argc == 1 then
      ok, a, b, c = pcall(proxy[name], select(1, ...))
    elseif argc == 2 then
      ok, a, b, c = pcall(proxy[name], select(1, ...), select(2, ...))
    else
      local args = {...}
      ok, a, b, c = pcall(function() return proxy[name](unpack(args)) end)
    end
    if ok and a ~= nil then return true, a, b, c end
    if not ok then return false, nil, tostring(a) end
    return false, nil, tostring(b or ("API call failed: " .. tostring(name)))
  end
  return false, nil, "method unavailable: " .. tostring(name)
end

local function invoke(gate, name, ...)
  if not gate or not gate.address then
    return false, nil, "no interface"
  end

  -- Prefer component.invoke. If the environment rejects it, try the proxy.
  local ok, a, b, c = directInvoke(gate.address, name, ...)
  if ok then return true, a, b, c end

  local pok, pa, pb, pc = proxyInvoke(gate.proxy, gate.address, name, ...)
  if pok then return true, pa, pb, pc end

  -- Return the direct error first because that is normally the real hardware/API error.
  return false, nil, tostring(b or a or pb or "API call failed: " .. tostring(name))
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
    else
      -- Keep the component visible even if proxy creation is unusual.
      result[#result + 1] = {
        address = address,
        proxy = nil,
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

  local okState, state, stateError, stateExtra = invoke(gate, "stargateState")
  local okLocal, localAddress, localError = invoke(gate, "localAddress")
  local okRemote, remoteAddress, remoteError = invoke(gate, "remoteAddress")
  local okEnergy, energy, energyError = invoke(gate, "energyAvailable")
  local okIris, iris, irisError = invoke(gate, "irisState")

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
  return invoke(gate, "dial", address)
end
function API.disconnect(gate)
  return invoke(gate, "disconnect")
end
function API.openIris(gate)
  return invoke(gate, "openIris")
end
function API.closeIris(gate)
  return invoke(gate, "closeIris")
end
function API.sendMessage(gate, message)
  return invoke(gate, "sendMessage", message)
end
function API.energyToDial(gate, address)
  return invoke(gate, "energyToDial", address)
end

return API
