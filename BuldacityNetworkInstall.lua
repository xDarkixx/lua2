-- BuldacityNetworkInstall.lua
-- Validate the current Buldacity/2 Tier-3 network stack and Big Reactors controller.
local fs=require("filesystem")
local files={
  "BuldacityWireless.lua",
  "BuldacityNetworkClient.lua",
  "BuldacityNetworkLauncher.lua",
  "BuldacityControllerLauncher.lua",
  "BuldacityNetworkStatus.lua",
  "BuldacityOS_Tier3.lua",
  "ReactorBigReactors043A_Touch_Responsive.lua"
}

print("BULDACITY NETWORK INSTALL // BULDACITY/2")
local missing=0
for _,name in ipairs(files) do
  if fs.exists(name) then
    print("OK   "..name)
  else
    print("MISS "..name)
    missing=missing+1
  end
end

print("Protocol: BULDACITY/2")
print("Port: 4242")
print("Server: BuldacityOS_Tier3.lua")
print("Client: BuldacityNetworkClient.lua")
print("Controllers: BuldacityControllerLauncher.lua")
print("Big Reactors: ReactorBigReactors043A_Touch_Responsive.lua")
print("Status: "..(missing==0 and "READY" or (missing.." FILE(S) MISSING")))
