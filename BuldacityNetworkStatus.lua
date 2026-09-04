-- BuldacityNetworkStatus.lua
local c=require("component")
local e=require("event")
local m=c.modem
if not m then print("NO MODEM") return end
m.open(4242)
print("BULDACITY/1 listening on port 4242")
while true do
 local _,_,from,port,dist,p=e.pull("modem_message")
 if port==4242 and type(p)=="table" and p.protocol=="BULDACITY/1" then print(os.date(),from,p.kind,p.data and p.data.name or "?") end
end
