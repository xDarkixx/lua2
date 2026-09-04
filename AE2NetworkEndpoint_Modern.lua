-- AE2NetworkEndpoint_Modern.lua
-- BULDACITY/2 desktop network endpoint for AE2Network_Modern.lua.
-- Keeps the existing AE2Network_Modern.lua controller unchanged.
-- OpenComputers 1.7.10 / AE2 rv3 beta 6 / port 4242

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("AE2 // ME Command Center",{
  controller="AE2Network_Modern.lua",
  mod="Applied Energistics 2",
  version="rv3 beta 6",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("AE2Network_Modern.lua"))
