-- BuldacityNetworkInstall.lua
-- Validates the canonical Buldacity network files on OpenOS.
local fs=require("filesystem")
local files={
  "BuldacityWireless.lua",
  "BuldacityNetworkClient.lua",
  "BuldacityNetworkLauncher.lua",
  "BuldacityDesktop_Tier3.lua"
}
for _,name in ipairs(files) do
  print((fs.exists(name) and "OK  " or "MISS").." "..name)
end
print("Protocol: BULDACITY/2  Port: 4242")
print("Run BuldacityDesktop_Tier3.lua on the Tier-3 desktop server.")
