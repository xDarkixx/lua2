-- BuldacityControllerLauncher.lua
-- Unified network-enabled entry point for the Buldacity controllers.
local shell=require("shell")
local netOk,net=pcall(require,"BuldacityNetworkClient")
local options={
 {"AE2 Network","AE2Network_Modern.lua"},{"Diesel Generator","DieselGenerator_Modern.lua"},
 {"Mekanism","Mekanism_Modern.lua"},{"Thermal","Thermal_Modern.lua"},
 {"ProjectE","ProjectE_Modern.lua"},{"RFTools","RFTools_Modern.lua"},
 {"SGCraft","SGCraft_Modern.lua"},{"Reactor","ReactorBigReactors043A_Touch_Responsive.lua"},
 {"RotaryCraft","RotaryCraftDashboard_Modern.lua"},{"Thermal Expansion","ThermalExpansion_Modern.lua"},
 {"PneumaticCraft","PneumaticCraftNetwork_Modern.lua"},
 {"LogisticsPipes","LogisticsPipesNetwork_Modern.lua"}}
print("BULDACITY CONTROLLER LAUNCHER // NETWORK")
for i,v in ipairs(options) do print(string.format("%2d  %s",i,v[1])) end
io.write("Select controller: ")
local n=tonumber(io.read())
if not n or not options[n] then return end
if netOk and net then pcall(net.start,"BULDACITY // "..options[n][1],"CLIENT",{screen="ACTIVE",controller=options[n][2]}) end
local path=shell.resolve(options[n][2])
dofile(path)
