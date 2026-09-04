-- SGCraftNetwork_Modern.lua
-- BULDACITY // STARGATE COMMAND CENTER - NETWORK MODERN
-- Minecraft 1.7.10 / SGCraft-1.13.3-mc1.7.10.jar
-- Keeps SGCraft_Modern.lua unchanged and adds BULDACITY/2 remote access.

local Network=require("Network")
local component=require("component")
local event=require("event")
local shell=require("shell")

local CLIENT_NAME="SGCraft // Stargate Command Center"
local ok,mode=Network.startClient(CLIENT_NAME,{controller="SGCraft_Modern.lua",mod="SGCraft",network=true})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

-- Run the original Modern controller unchanged.
local path=shell.resolve("SGCraft_Modern.lua")
local loaded,err=pcall(dofile,path)
if not loaded then
  io.stderr:write("Unable to start "..path..": "..tostring(err).."\n")
end
