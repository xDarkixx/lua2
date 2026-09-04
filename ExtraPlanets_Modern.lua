-- Buldacity ExtraPlanets Modern Controller
-- ExtraPlanets 1.7.10-2.1.4; Galacticraft addon
local component=require("component")
local event=require("event")
local term=require("term")
local function scan() local r={} for a,t in component.list() do local s=string.lower(t) if s:find("planet") or s:find("galactic") or s:find("rocket") or s:find("space") or s:find("oxygen") then r[#r+1]={a,t} end end return r end
while true do term.clear();term.setCursor(1,1);print("=== BULDACITY // EXTRAPLANETS ===");print("ExtraPlanets 2.1.4 | Galacticraft addon");print("");local r=scan();print("Detected OC components: "..#r);for i,v in ipairs(r) do print(string.format("%02d %-24s %s",i,v[2],v[1])) end;print("");print("R = rescan | Q = quit");local _,_,c=event.pull("key_down");if c==16 or c==81 or c==113 then break end end
