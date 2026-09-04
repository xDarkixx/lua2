-- RotaryCraftNetwork.lua
-- BULDACITY/2 network wrapper for the normal RotaryCraft controller.
-- Minecraft 1.7.10 / RotaryCraft V33a / OpenComputers

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("RotaryCraft // Control Center",{
  controller="RotaryCraft.lua",
  mod="RotaryCraft",
  version="V33a",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("RotaryCraft.lua"))
