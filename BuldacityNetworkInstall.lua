-- BuldacityNetworkInstall.lua
-- Installs/validates the shared Buldacity network files on OpenOS.
local fs=require("filesystem")
local files={"BuldacityNetworkClient.lua","BuldacityNetworkLauncher.lua","BuldacityServer_Tier3.lua"}
for _,name in ipairs(files) do print((fs.exists(name) and "OK  " or "MISS").." "..name) end
print("Protocol: BULDACITY/1  Port: 4242")
print("Run BuldacityServer_Tier3.lua on the Tier-3 desktop server.")
