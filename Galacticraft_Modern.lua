-- Buldacity Galacticraft Modern Controller
-- MC 1.7.10 / GalacticraftCore 3.0.12.504 / Galacticraft-Planets 3.0.12.504
local component=require("component")
local event=require("event")
local term=require("term")
local function scan()
 local r={}
 for addr,typ in component.list() do
  local s=string.lower(typ)
  if s:find("galactic") or s:find("rocket") or s:find("fuel") or s:find("oxygen") or s:find("space") then r[#r+1]={addr,typ} end
 end
 return r
end
while true do
 term.clear();term.setCursor(1,1)
 print("=== BULDACITY // GALACTICRAFT ===")
 print("Core 3.0.12.504 | Planets 3.0.12.504")
 print("ExtraPlanets integration: optional")
 print("")
 local r=scan(); print("Detected OC components: "..#r)
 for i,v in ipairs(r) do print(string.format("%02d %-24s %s",i,v[2],v[1])) end
 print("")
 print("R = rescan | Q = quit")
 local _,_,c=event.pull("key_down")
 if c==16 or c==81 or c==113 then break end
end
