-- BULDACITY client command helper
local Network=require("network-modern.Network")
local M={}

function M.send(destination,action,data,reliable)
  local payload={action=action,data=data or {},role="CLIENT"}
  if reliable then return Network.sendReliable("COMMAND",destination,payload) end
  return Network.send("COMMAND",destination,payload)
end

function M.result(commandId,success,result)
  return Network.send("STATUS","TIER3-CORE",{
    role="CLIENT",commandId=commandId,success=success==true,result=result
  })
end

function M.emergencyStop()
  return Network.sendReliable("EMERGENCY_STOP","TIER3-CORE",{role="CLIENT",confirmed=true})
end

return M
