-- BuldacityNetworkTest.lua
-- BULDACITY/2 end-to-end network diagnostic for the central Tier-3 PC.
-- Run this on the MAIN PC after Network.lua and the controller clients are installed.
-- It tests every discovered client with PING/PONG and reports wired/wireless,
-- distance, relay/access-point information and round-trip latency.

local component=require("component")
local computer=require("computer")
local event=require("event")
local network=require("Network")

local PORT=4242
local PROTOCOL="BULDACITY/2"
local devices={}
local pending={}
local running=true

local function now() return computer.uptime() end
local function log(s) print(os.date("%H:%M:%S").."  "..tostring(s)) end

local ok,mode=network.startServer(function(sender,p,distance)
 if type(p)~="table" then return end
 local data=p.data or {}
 if p.kind=="HELLO" or p.kind=="HEARTBEAT" then
  local d=devices[sender] or {address=sender}
  devices[sender]=d
  for k,v in pairs(data) do d[k]=v end
  d.address=sender;d.last=now();d.distance=distance or 0
 elseif p.kind=="PONG" then
  local d=devices[sender] or {address=sender}
  devices[sender]=d
  d.last=now();d.distance=distance or 0
  d.lastPong=now()
  d.pong=true
  d.wireless=(tonumber(distance) or 0)>0
  if data and data.relayPathType then d.relayPathType=data.relayPathType end
  if data and data.relayDetected~=nil then d.relayDetected=data.relayDetected end
  local sent=d.pingSent
  if sent then d.latency=(now()-sent)*1000 end
 end
end)

if not ok then error("BULDACITY Network unavailable: "..tostring(mode)) end

local function discovery()
 log("Broadcast SERVER_HELLO / discovery")
 network.broadcast("SERVER_HELLO",{
  name="BULDACITY NETWORK TEST",role="SERVER",app="NETWORK TEST",
  protocol=PROTOCOL,port=PORT
 })
 local deadline=now()+2
 while now()<deadline do event.pull(0.1) end
end

local function testAll()
 local list={}
 for address,d in pairs(devices) do
  if d.last and now()-d.last<12 then list[#list+1]=d end
 end
 table.sort(list,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address) end)
 if #list==0 then
  log("FAIL: no controller clients discovered")
  return false
 end
 print("\n============================================================")
 print(" BULDACITY/2 END-TO-END NETWORK TEST")
 print("============================================================")
 local all=true
 for i,d in ipairs(list) do
  d.pong=false;d.pingSent=now()
  local sent,err=network.send(d.address,"PING",{from="BULDACITY NETWORK TEST",id=tostring(d.pingSent)})
  if not sent then
   d.result="SEND FAIL";all=false
  else
   local deadline=now()+3
   while now()<deadline and not d.pong do event.pull(0.05) end
   d.result=d.pong and "PASS" or "FAIL"
   if not d.pong then all=false end
  end
  local link=d.wireless and "WIRELESS" or "WIRED"
  local relay=d.relayPathType or (d.relayDetected and "RELAY" or "NONE")
  print(string.format("%02d %-28s %-5s %-8s dist=%-4s latency=%-7s relay=%s",
    i,tostring(d.name or d.address):sub(1,28),d.result,link,
    tostring(d.distance or 0),d.latency and string.format("%.1fms",d.latency) or "--",relay))
 end
 print("------------------------------------------------------------")
 print(all and "RESULT: ALL DISCOVERED CLIENTS PASS" or "RESULT: ONE OR MORE CLIENTS FAILED")
 print("Relay/Access Point strength is configured automatically by Network.lua.")
 print("A Relay needs a Wireless Network Card to provide wireless service.")
 print("============================================================\n")
 return all
end

discovery()
testAll()

print("Press Q to quit, R to run the complete test again.")
while running do
 local e,_,_,_,_,_=event.pull(0.25)
 if e=="key_down" then
  local char=select(3,event.pull) -- intentionally unused; compatibility placeholder
 elseif e=="interrupted" then
  running=false
 end
end
