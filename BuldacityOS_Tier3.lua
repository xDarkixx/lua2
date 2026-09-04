-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers main entry point
-- The complete graphical desktop lives in BuldacityDesktop.lua.
-- Minecraft 1.7.10 / OpenComputers 1.8.10

local ok,err=pcall(dofile,"/BuldacityDesktop.lua")
if not ok then
 error("BULDACITY OS failed to start: "..tostring(err))
end
