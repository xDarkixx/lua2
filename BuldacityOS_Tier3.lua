-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers main entry point
-- The complete graphical desktop lives in /home/BuldacityDesktop.lua.
-- Minecraft 1.7.10 / OpenComputers 1.8.10
-- All BULDACITY application files are installed under /home.

local filesystem=require("filesystem")

local desktop="/home/BuldacityDesktop.lua"
if not filesystem.exists(desktop) or filesystem.isDirectory(desktop) then
  error("BULDACITY OS: /home/BuldacityDesktop.lua not found")
end

-- Make /home the working directory so relative OpenOS module lookup and
-- shell.resolve() consistently refer to the BULDACITY installation.
pcall(function()
  local shell=require("shell")
  shell.setWorkingDirectory("/home")
end)

local ok,err=pcall(dofile,desktop)
if not ok then
  error("BULDACITY OS failed to start from "..desktop..": "..tostring(err))
end
