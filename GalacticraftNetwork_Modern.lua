-- Buldacity Galacticraft Network Controller
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"Galacticraft",{controller="Galacticraft_Modern.lua"}) end
local component=require("component")
local event=require("event")
local term=require("term")
local function scan() local r={};for addr,typ in component.list() do local s=string.lower(typ);if s:find("galactic") or s:find("rocket") or s:find("oxygen") or s:find("space") or s:find("network") then r[#r+1]={addr,typ} end end;return r end
while true do term.clear();term.setCursor(1,1);print("=== BULDACITY // GALACTICRAFT NETWORK ===");print("Buldacity Network / live OC component discovery");print("");local r=scan();print("Detected components: "..#r);for i,v in ipairs(r) do print(string.format("%02d %-24s %s",i,v[2],v[1])) end;print("");print("R = rescan | Q = quit");local _,_,c=event.pull("key_down");if c==16 or c==81 or c==113 then break end end
