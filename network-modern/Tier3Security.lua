-- BULDACITY TIER-3 ACCESS POLICY
-- Network-level allow/deny policy. Internet authentication stays in RemoteGateway.py.
local M={allow={},deny={}}
function M.allowNode(nodeId) M.allow[nodeId]=true;M.deny[nodeId]=nil end
function M.denyNode(nodeId) M.deny[nodeId]=true;M.allow[nodeId]=nil end
function M.isAllowed(nodeId)
  if M.deny[nodeId] then return false,"DENIED" end
  if next(M.allow)==nil then return true end
  if M.allow[nodeId] then return true end
  return false,"NOT_WHITELISTED"
end
function M.commandAllowed(nodeId,kind)
  local ok,reason=M.isAllowed(nodeId);if not ok then return false,reason end
  if kind=="EMERGENCY_STOP" then return true end
  return kind=="COMMAND" or kind=="STATUS" or kind=="PING" or kind=="PONG" or kind=="HELLO" or kind=="HEARTBEAT", "TYPE_DENIED"
end
return M
