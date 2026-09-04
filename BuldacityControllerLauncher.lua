-- BuldacityControllerLauncher.lua
-- Unified entry point for the network-enabled Buldacity controllers.
-- Run this on a Tier-2 computer to choose a controller.
local shell=require("shell")
local options={
 {"AE2 Network","AE2Network_Modern.lua"},{"Diesel Generator","DieselGenerator_Modern.lua"},
 {"Mekanism","Mekanism_Modern.lua"},{"Thermal","Thermal_Modern.lua"},
 {"ProjectE","ProjectE_Modern.lua"},{"RFTools","RFTools_Modern.lua"},
 {"SGCraft","SGCraft_Modern.lua"},{"Reactor","ReactorBigReactors043A_Touch_Responsive.lua"},
 {"RotaryCraft","RotaryCraftDashboard_Modern.lua"},{"Thermal Expansion","ThermalExpansion_Modern.lua"}}
print("BULDACITY CONTROLLER LAUNCHER")
for i,v in ipairs(options) do print(string.format("%2d  %s",i,v[1])) end
io.write("Select controller: ")
local n=tonumber(io.read())
if not n or not options[n] then return end
local path=shell.resolve(options[n][2])
dofile(path)
