-- BuldacityApps_Modern_Network.lua
-- Non-destructive launcher for BuldacityApps_Modern.lua.
-- The original Modern application remains unchanged.
package.preload["Network"]=function()
  return require("clients.network.ModernNetworkCompat")
end
return dofile("/home/BuldacityApps_Modern.lua")
