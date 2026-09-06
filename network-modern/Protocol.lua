-- Modern Network Protocol
local M = {}

M.NAME = "MODERN-NET"
M.VERSION = 2
M.PORT = 31337
M.MAX_HOPS = 4
M.MAX_PACKET_BYTES = 4096

M.TYPES = {
  HELLO=true, HEARTBEAT=true, COMMAND=true, ACK=true, NACK=true,
  STATUS=true, PING=true, PONG=true, EMERGENCY_STOP=true,
  UI_FRAME=true, UI_INPUT=true,
}

function M.new(kind, source, destination, id, payload)
  assert(M.TYPES[kind], "invalid message type")
  return {
    magic=M.NAME, version=M.VERSION, type=kind,
    source=source, destination=destination or "*", id=id,
    time=os.time(), hops=0, maxHops=M.MAX_HOPS,
    payload=payload or {}
  }
end

function M.valid(m)
  if type(m) ~= "table" then return false,"NOT_TABLE" end
  if m.magic ~= M.NAME then return false,"MAGIC" end
  if m.version ~= M.VERSION then return false,"VERSION" end
  if type(m.type) ~= "string" or not M.TYPES[m.type] then return false,"TYPE" end
  if type(m.source) ~= "string" or m.source == "" then return false,"SOURCE" end
  if type(m.destination) ~= "string" or m.destination == "" then return false,"DESTINATION" end
  if type(m.id) ~= "string" or m.id == "" then return false,"ID" end
  local hops=tonumber(m.hops or 0)
  local maxHops=tonumber(m.maxHops or M.MAX_HOPS)
  if not hops or hops < 0 or hops > M.MAX_HOPS then return false,"HOPS" end
  if not maxHops or maxHops < 1 or maxHops > M.MAX_HOPS then return false,"MAX_HOPS" end
  if hops >= maxHops then return false,"TTL" end
  return true
end

function M.forward(m)
  if type(m) ~= "table" then return nil end
  local copy={}
  for k,v in pairs(m) do copy[k]=v end
  copy.hops=tonumber(m.hops or 0)+1
  return copy
end

return M
