-- BULDACITY client transport facade
-- Uses the shared modern modem transport; no second transport implementation.
local Transport=require("network-modern.Transport")
local Protocol=require("clients.network.ClientProtocol")
local M={}

function M.init(port) return Transport.init(port or Protocol.PORT) end
function M.send(address,packet) return Transport.send(address,packet) end
function M.broadcast(packet) return Transport.broadcast(packet) end
function M.receive(timeout) return Transport.receive(timeout) end
function M.status() return Transport.status() end

return M
