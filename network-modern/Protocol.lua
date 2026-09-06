-- BULDACITY Modern Network Protocol
local M = {}

M.NAME = "BULDACITY"
M.VERSION = 1
M.TYPES = {
  HELLO=true, HEARTBEAT=true, COMMAND=true, ACK=true,
  NACK=true, STATUS=true, PING=true, PONG=true,
  EMERGENCY_STOP=true
}

function M.new(kind, source, destination, id, payload)
  assert(M.TYPES[kind], "invalid message type")
  return {
    magic=M.NAME, version=M.VERSION, type=kind,
    source=source, destination=destination or "*", id=id,
    time=os.time(), payload=payload or {}
  }
end

function M.valid(m)
  return type(m)=="table" and m.magic==M.NAME and m.version==M.VERSION
    and M.TYPES[m.type] and type(m.source)=="string"
    and type(m.id)=="string"
end

return M
