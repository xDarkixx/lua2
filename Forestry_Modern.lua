-- Buldacity Forestry Modern Controller
-- Forestry 1.7.10-4.2.16.64
local component=require("component")
local event=require("event")
local term=require("term")
local function scan()
 local r={}
 for addr,typ in component.list() do
  local s=string.lower(typ)
  if s:find("forestry") or s:find("bee") or s:find("apiary") or s:find("tree") or s:find("farm") or s:find("alveary") then r[#r+1]={addr,typ} end
 end
 return r
end
while true do
 term.clear();term.setCursor(1,1);print("=== BULDACITY // FORESTRY ===");print("Forestry 4.2.16.64 | live OC discovery");print("")
 local r=scan();print("Detected Forestry components: "..#r)
 for i,v in ipairs(r) do print(string.format("%02d %-24s %s",i,v[2],v[1])) end
 print("");print("R = rescan | Q = quit")
 local _,_,c=event.pull("key_down");if c==16 or c==81 or c==113 then break end
end
