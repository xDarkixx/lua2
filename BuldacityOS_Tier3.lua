-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers main entry point
-- The complete graphical desktop lives in /home/BuldacityDesktop.lua.
-- Minecraft 1.7.10 / OpenComputers 1.8.10
-- All BULDACITY application files are installed under /home.

local filesystem=require("filesystem")

local HOME="/home/"
local desktop=HOME.."BuldacityDesktop.lua"
local componentServer=HOME.."BuldacityComponentServer.lua"
local networkSetup=HOME.."BuldacityNetworkSetup.lua"
if not filesystem.exists(desktop) or filesystem.isDirectory(desktop) then
  error("BULDACITY OS: /home/BuldacityDesktop.lua not found")
end

pcall(function()
  local shell=require("shell")
  shell.setWorkingDirectory(HOME)
end)
package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")

-- Start the component inventory service first. It returns immediately and
-- keeps listening in the background while the graphical desktop runs.
if filesystem.exists(componentServer) and not filesystem.isDirectory(componentServer) then
  local ok,err=pcall(dofile,componentServer)
  if not ok then io.stderr:write("BULDACITY COMPONENT SERVER failed: "..tostring(err).."\n") end
end

-- Automatic network setup: opens/configures modems, discovers clients,
-- checks the BULDACITY/2 link and inventories remote components before the
-- normal desktop starts. The wizard is deliberately short and non-interactive.
if filesystem.exists(networkSetup) and not filesystem.isDirectory(networkSetup) then
  local ok,err=pcall(dofile,networkSetup)
  if not ok then io.stderr:write("BULDACITY NETWORK SETUP failed: "..tostring(err).."\n") end
end

local ok,err=pcall(dofile,desktop)
if not ok then
  error("BULDACITY OS failed to start from "..desktop..": "..tostring(err))
end
