-- BULDACITY Modern Network Registry
local M = {nodes={}}

function M.touch(node, address, kind)
  local n=M.nodes[node] or {id=node}
  n.address=address
  n.kind=kind or n.kind or "UNKNOWN"
  n.lastSeen=os.time()
  n.online=true
  n.missed=0
  M.nodes[node]=n
  return n
end

function M.heartbeat(node)
  local n=M.nodes[node]
  if n then n.lastSeen=os.time(); n.online=true; n.missed=0 end
end

function M.expire(timeout)
  timeout=timeout or 10
  local now=os.time()
  for _,n in pairs(M.nodes) do
    if now-n.lastSeen>timeout then n.online=false end
  end
end

function M.get(node) return M.nodes[node] end
function M.all() return M.nodes end

return M
