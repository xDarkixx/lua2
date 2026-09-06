-- BULDACITY client protocol facade
-- Single source of truth remains network-modern/Protocol.lua.
local Protocol=require("network-modern.Protocol")
local M={}

M.NAME=Protocol.NAME
M.VERSION=Protocol.VERSION
M.PORT=Protocol.PORT
M.MAX_HOPS=Protocol.MAX_HOPS
M.MAX_PACKET_BYTES=Protocol.MAX_PACKET_BYTES
M.TYPES=Protocol.TYPES
M.new=Protocol.new
M.valid=Protocol.valid
M.forward=Protocol.forward

return M
