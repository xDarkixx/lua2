-- BULDACITY Modern Client device helper
-- Safe helpers for controller scripts. Hardware-specific control remains in the controller.
local component=require("component")
local M={}

function M.has(typeName) return component.isAvailable(typeName) end
function M.proxy(address)
  if address then
    local ok,p=pcall(component.proxy,address)
    if ok then return p end
  end
  return nil
end
function M.list(typeName)
  local out={}
  for address,kind in component.list(typeName,true) do out[#out+1]={address=address,type=kind} end
  return out
end
function M.safeCall(proxy,method,...)
  if not proxy or type(proxy[method])~="function" then return false,"MISSING_METHOD" end
  local ok,a,b,c=pcall(proxy[method],...)
  if not ok then return false,a end
  return true,a,b,c
end

return M
