-- AE2Network_Modern.lua
-- Buldacity AE2 entry point.
-- The crafting page is implemented in AE2CraftSearch.lua and has a real clickable search window.
local shell=require("shell")
local path="/home/AE2CraftSearch.lua"
local f=io.open(path,"r")
if f then f:close() else path=shell.resolve("AE2CraftSearch.lua") end
dofile(path)
