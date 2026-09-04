-- Buldacity ExtraPlanets Network Controller
local component=require("component")
local event=require("event")
local term=require("term")
while true do term.clear();term.setCursor(1,1);print("=== BULDACITY // EXTRAPLANETS NETWORK ===");print("Live OC discovery | Galacticraft dependency");print("");local n=0;for a,t in component.list() do local s=string.lower(t);if s:find("planet") or s:find("galactic") or s:find("rocket") or s:find("oxygen") or s:find("network") then n=n+1;print(string.format("%02d %-24s %s",n,t,a))end end;print("");print("Detected components: "..n);print("R = rescan | Q = quit");local _,_,c=event.pull("key_down");if c==16 or c==81 or c==113 then break end end
