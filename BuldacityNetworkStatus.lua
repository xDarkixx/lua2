-- BuldacityNetworkStatus.lua
-- BULDACITY/2 network diagnostic for OpenComputers 1.7.10.
local event=require("event")
local wireless=require("BuldacityWireless")
local PORT=4242
local ok,mode=wireless.init(PORT)
if not ok then print("NO NETWORK MODEM") return end
print("BULDACITY NETWORK STATUS")
print("Protocol: BULDACITY/2")
print("Port: "..PORT)
print("Mode: "..mode)
print("Address: "..wireless.address())
print("Range: "..tostring(wireless.strength() or "N/A"))
print("Listening...")
while true do
  local _,_,from,port,distance,p=event.pull("modem_message")
  if port==PORT and wireless.valid(p) then
    local name=p.data and p.data.name or "?"
    print(os.date("%H:%M:%S"),from,p.kind,name,"distance="..tostring(distance))
  end
end
