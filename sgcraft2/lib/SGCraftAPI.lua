-- BULDACITY SGCraft2 API adapter
-- Hardware/API layer intentionally kept independent from the UI.
-- Compatible with OpenComputers / SGCraft 1.13.x on Minecraft 1.7.10.
-- Important: one failing optional API method must never make the gate appear offline.
local component=require("component")
local API={}

local function directInvoke(address,name,...)
  if not address or address=="" then return false,nil,"no interface address" end
  if type(component.invoke)~="function" then return false,nil,"component.invoke unavailable" end
  local argc=select("#",...)
  local ok,a,b,c
  if argc==0 then ok,a,b,c=pcall(component.invoke,address,name)
  elseif argc==1 then ok,a,b,c=pcall(component.invoke,address,name,select(1,...))
  elseif argc==2 then ok,a,b,c=pcall(component.invoke,address,name,select(1,...),select(2,...))
  else local args={...};ok,a,b,c=pcall(function() return component.invoke(address,name,unpack(args)) end) end
  if not ok then return false,nil,tostring(a) end
  if a==nil then return false,nil,tostring(b or ("API call failed: "..tostring(name))) end
  return true,a,b,c
end

local function proxyInvoke(proxy,name,...)
  if not proxy or type(proxy[name])~="function" then return false,nil,"method unavailable: "..tostring(name) end
  local argc=select("#",...);local ok,a,b,c
  if argc==0 then ok,a,b,c=pcall(proxy[name])
  elseif argc==1 then ok,a,b,c=pcall(proxy[name],select(1,...))
  elseif argc==2 then ok,a,b,c=pcall(proxy[name],select(1,...),select(2,...))
  else local args={...};ok,a,b,c=pcall(function() return proxy[name](unpack(args)) end) end
  if ok and a~=nil then return true,a,b,c end
  if not ok then return false,nil,tostring(a) end
  return false,nil,tostring(b or ("API call failed: "..tostring(name)))
end

function API.invoke(gate,name,...)
  if not gate or not gate.address then return false,nil,"no interface" end
  local ok,a,b,c=directInvoke(gate.address,name,...)
  if ok then return true,a,b,c end
  local pok,pa,pb,pc=proxyInvoke(gate.proxy,name,...)
  if pok then return true,pa,pb,pc end
  return false,nil,tostring(b or a or pb or ("API call failed: "..tostring(name)))
end

local function methodMap(address)
  local result={};local ok,methods=pcall(component.methods,address)
  if ok and type(methods)=="table" then for name,value in pairs(methods) do if value then result[name]=true end end end
  return result
end

function API.list()
  local result={};local primary=nil
  local okAvailable,available=pcall(component.isAvailable,"stargate")
  if okAvailable and available then
    local ok,p=pcall(component.getPrimary,"stargate")
    if ok and p then primary=p.address or p end
  end
  local okList=pcall(function()
    for address in component.list("stargate") do
      local ok,proxy=pcall(component.proxy,address)
      result[#result+1]={address=address,proxy=ok and proxy or nil,primary=address==primary,methods=methodMap(address)}
    end
  end)
  if not okList then return {} end
  table.sort(result,function(a,b) return a.address<b.address end)
  return result
end

function API.read(gate)
  if not gate then return {present=false,state="NO INTERFACE",engaged=0,direction="",localAddress="",remoteAddress="",energy=0,iris="Unknown",ok=false,error="No SGCraft interface detected",localOK=false,remoteOK=false,energyOK=false,irisOK=false,localError="no interface",remoteError="no interface",energyError="no interface",irisError="no interface",methods={}} end
  local okState,state,engaged,direction=API.invoke(gate,"stargateState")
  local okLocal,localAddress,localErr=API.invoke(gate,"localAddress")
  local okRemote,remoteAddress,remoteErr=API.invoke(gate,"remoteAddress")
  local okEnergy,energy,energyErr=API.invoke(gate,"energyAvailable")
  local okIris,iris,irisErr=API.invoke(gate,"irisState")
  local errors={}
  if not okState then errors[#errors+1]="stargateState: "..tostring(state) end
  if not okLocal then errors[#errors+1]="localAddress: "..tostring(localErr) end
  if not okRemote then errors[#errors+1]="remoteAddress: "..tostring(remoteErr) end
  if not okEnergy then errors[#errors+1]="energyAvailable: "..tostring(energyErr) end
  if not okIris then errors[#errors+1]="irisState: "..tostring(irisErr) end
  local cleanState=okState and tostring(state) or "API ERROR"
  return {
    present=true,state=cleanState,
    engaged=okState and (tonumber(engaged) or 0) or 0,
    direction=okState and tostring(direction or "") or "",
    localAddress=okLocal and tostring(localAddress or "") or "",
    remoteAddress=okRemote and tostring(remoteAddress or "") or "",
    energy=okEnergy and (tonumber(energy) or 0) or 0,
    iris=okIris and tostring(iris or "Unknown") or "API ERROR",
    ok=okState,localOK=okLocal,remoteOK=okRemote,energyOK=okEnergy,irisOK=okIris,
    error=table.concat(errors," | "),
    localError=tostring(localErr or ""),remoteError=tostring(remoteErr or ""),energyError=tostring(energyErr or ""),irisError=tostring(irisErr or ""),methods=gate.methods or {}
  }
end

function API.dial(g,a) return API.invoke(g,"dial",a) end
function API.disconnect(g) return API.invoke(g,"disconnect") end
function API.openIris(g) return API.invoke(g,"openIris") end
function API.closeIris(g) return API.invoke(g,"closeIris") end
function API.sendMessage(g,m) return API.invoke(g,"sendMessage",m) end
function API.energyToDial(g,a) return API.invoke(g,"energyToDial",a) end
return API
