-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers main entry point
-- The complete graphical desktop lives in BuldacityDesktop.lua.
-- Minecraft 1.7.10 / OpenComputers 1.8.10

local filesystem=require("filesystem")

local candidates={
  "/BuldacityDesktop.lua",
  "/home/BuldacityDesktop.lua",
  "/usr/lib/BuldacityDesktop.lua"
}

local desktop=nil
for i=1,#candidates do
  if filesystem.exists(candidates[i]) and not filesystem.isDirectory(candidates[i]) then
    desktop=candidates[i]
    break
  end
end

if not desktop then
  error("BULDACITY OS: BuldacityDesktop.lua not found. Checked /, /home and /usr/lib")
end

local ok,err=pcall(dofile,desktop)
if not ok then
  error("BULDACITY OS failed to start from "..desktop..": "..tostring(err))
end
