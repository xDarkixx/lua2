-- BULDACITY SGCraft API adapter
-- Keeps all SGCraft/OpenComputers calls protected so UI code never has to
-- guess whether an interface is missing, disconnected, or returned an error.

local component = require("component")

local API = {}

local function invoke(proxy, name, ...)
  if not proxy then return false, nil, "no interface" end
  local fn = proxy[name]
  if type(fn) ~= "function" then return false, nil, "method unavailable: " .. name end
  local args = {...}
  local ok, a, b, c = pcall(function() return fn(table.unpack(args)) end)
  if ok then return true, a, b, c end
  return false, nil, tostring(a)
end

API.invoke = invoke

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
      result[#result + 1] = {address=address, proxy=proxy, primary=(address == primary)}
    end
  end
  table.sort(result, function(a,b) return a.address < b.address end)
  return result
end

function API.read(gate)
  if not gate then
    return {present=false, state="NO INTERFACE", engaged=0, direction="", localAddress="", remoteAddress="", energy=0, iris="Unknown", error="No SGCraft interface detected"}
  end
  local p = gate.proxy
  local okState, state, engaged, direction = invoke(p, "stargateState")
  local okLocal, localAddress, localError = invoke(p, "localAddress")
  local okRemote, remoteAddress, remoteError = invoke(p, "remoteAddress")
  local okEnergy, energy, energyError = invoke(p, "energyAvailable")
  local okIris, iris, irisError = invoke(p, "irisState")
  return {
    present=true,
    state=okState and tostring(state or "Offline") or "API ERROR",
    engaged=okState and tonumber(engaged or 0) or 0,
    direction=okState and tostring(direction or "") or "",
    localAddress=okLocal and tostring(localAddress or "") or "",
    remoteAddress=okRemote and tostring(remoteAddress or "") or "",
    energy=okEnergy and tonumber(energy or 0) or 0,
    iris=okIris and tostring(iris or "Unknown") or "API ERROR",
    ok=okState,
    localOK=okLocal, remoteOK=okRemote, energyOK=okEnergy, irisOK=okIris,
    error=okState and "" or tostring(engaged or "stargateState failed"),
    localError=tostring(localError or ""), remoteError=tostring(remoteError or ""),
    energyError=tostring(energyError or ""), irisError=tostring(irisError or "")
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
