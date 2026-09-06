-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers main entry point
-- Graphical desktop remains separate from network services and the original
-- setup files remain available for compatibility/fallback.
-- Minecraft 1.7.10 / OpenComputers 1.8.10

local filesystem=require("filesystem")

local HOME="/home/"
local desktop=HOME.."BuldacityDesktop.lua"
local componentServer=HOME.."BuldacityComponentServer.lua"
local networkSetupUI=HOME.."setup/BuldacityNetworkWizardUI.lua"
local networkSetupOriginal=HOME.."BuldacityNetworkSetup.lua"
if not filesystem.exists(desktop) or filesystem.isDirectory(desktop) then
  error("BULDACITY OS: /home/BuldacityDesktop.lua not found")
end

pcall(function()
  local shell=require("shell")
  shell.setWorkingDirectory(HOME)
end)
package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")

-- Component inventory stays independent from the graphical network wizard.
if filesystem.exists(componentServer) and not filesystem.isDirectory(componentServer) then
  local ok,err=pcall(dofile,componentServer)
  if not ok then io.stderr:write("BULDACITY COMPONENT SERVER failed: "..tostring(err).."\n") end
end

-- New graphical touch wizard. The original non-interactive setup remains the
-- fallback so an older installation can still boot if the UI has a problem.
local wizardOK=false
if filesystem.exists(networkSetupUI) and not filesystem.isDirectory(networkSetupUI) then
  local ok,err=pcall(dofile,networkSetupUI)
  wizardOK=ok
  if not ok then io.stderr:write("BULDACITY GRAPHICAL NETWORK WIZARD failed: "..tostring(err).."\n") end
end

if not wizardOK and filesystem.exists(networkSetupOriginal) and not filesystem.isDirectory(networkSetupOriginal) then
  local ok,err=pcall(dofile,networkSetupOriginal)
  if not ok then io.stderr:write("BULDACITY ORIGINAL NETWORK SETUP failed: "..tostring(err).."\n") end
end

local ok,err=pcall(dofile,desktop)
if not ok then
  error("BULDACITY OS failed to start from "..desktop..": "..tostring(err))
end
