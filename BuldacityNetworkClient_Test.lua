local c=require("component")
local e=require("event")
local m=c.modem
if not m then print("NO MODEM") return end
m.open(4242)
m.broadcast(4242,{protocol="BULDACITY/1",kind="HELLO",data={name="TEST CLIENT",role="CLIENT"}})
print("HELLO broadcast on 4242")
