-- BULDACITY Modern Network self-test
local serialization=require("serialization")
local Protocol=require("network-modern.Protocol")

local function check(ok,name)
  if not ok then error("FAIL: "..name,0) end
  print("PASS: "..name)
end

local p=Protocol.new("PING","NODE_A","NODE_B","TEST-1",{value=42})
local ok,reason=Protocol.valid(p)
check(ok,"packet validation")
check(p.hops==0,"initial hop count")

local f=Protocol.forward(p)
local fok,freason=Protocol.valid(f)
check(fok,"forwarded packet validation")
check(f.hops==1,"hop increment")

local raw=serialization.serialize(f)
check(#raw<=Protocol.MAX_PACKET_BYTES,"packet size limit")

local loop=f
for i=1,Protocol.MAX_HOPS-1 do loop=Protocol.forward(loop) end
local lok=Protocol.valid(loop)
check(not lok,"TTL prevents endless relay loops")

print("BULDACITY Modern Network self-test OK")
return true
