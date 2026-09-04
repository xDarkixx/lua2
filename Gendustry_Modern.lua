-- Buldacity Gendustry Modern Controller
-- Gendustry 1.6.4.135 MC1.7.10; requires Forestry and bdlib
local component=require("component")
local event=require("event")
local term=require("term")
local function scan()
 local r={}
 for addr,typ in component.list() do
  local s=string.lower(typ)
  if s:find("gendustry") or s:find("apiary") or s:find("genetic") or s:find("bee") then r[#r+1]={addr,typ} end
 end
 return r
end
while true do
 term.clear();term.setCursor(1,1);print("=== BULDACITY // GENDUSTRY ===");print("Gendustry 1.6.4.135 | Forestry addon");print("Forestry + bdlib required by Gendustry");print("")
 local r=scan();print("Detected components: "..#r)
 for i,v in ipairs(r) do print(string.format("%02d %-24s %s",i,v[2],v[1])) end
 print("");print("R = rescan | Q = quit")
 local _,_,c=event.pull("key_down");if c==16 or c==81 or c==113 then break end
end
