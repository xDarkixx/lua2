-- BuldacityControllerLauncher.lua
-- Unified Buldacity controller launcher for OpenComputers 1.7.10.
-- Network: BULDACITY/2 / port 4242.
local shell=require("shell")
local netOk,net=pcall(require,"BuldacityNetworkClient")
local options={
 {"AE2 Network","AE2Network_Modern.lua"},{"Diesel Generator","DieselGenerator_Modern.lua"},
 {"Mekanism","Mekanism_Modern.lua"},{"Thermal","Thermal_Modern.lua"},
 {"ProjectE","ProjectE_Modern.lua"},{"RFTools","RFTools_Modern.lua"},
 {"SGCraft","SGCraft_Modern.lua"},{"Reactor","ReactorBigReactors043A_Touch_Responsive.lua"},
 {"RotaryCraft","RotaryCraftDashboard_Modern.lua"},{"Thermal Expansion","ThermalExpansion_Modern.lua"},
 {"PneumaticCraft","PneumaticCraftNetwork_Modern.lua"},{"LogisticsPipes","LogisticsPipesNetwork_Modern.lua"},
 {"Immersive Engineering","ImmersiveEngineering_Network_Modern.lua"},
 {"Immersive Integration","ImmersiveIntegration_Network_Modern.lua"},
 {"Immersive Railroading","ImmersiveRailroading_Network_Modern.lua"},
 {"IndustrialCraft 2","IndustrialCraft2_Network_Modern.lua"},
 {"Galacticraft","Galacticraft_Modern.lua"},{"Galacticraft Network","GalacticraftNetwork_Modern.lua"},
 {"ExtraPlanets","ExtraPlanets_Modern.lua"},{"ExtraPlanets Network","ExtraPlanetsNetwork_Modern.lua"},
 {"Forestry","Forestry_Modern.lua"},{"Forestry Network","ForestryNetwork_Modern.lua"},
 {"Gendustry","Gendustry_Modern.lua"},{"Gendustry Network","GendustryNetwork_Modern.lua"}}
print("BULDACITY CONTROLLER LAUNCHER // BULDACITY/2")
for i,v in ipairs(options) do print(string.format("%2d  %s",i,v[1])) end
io.write("Select controller: ")
local n=tonumber(io.read())
if not n or not options[n] then return end
local file=options[n][2]
local path=shell.resolve(file)
if not path then print("Missing controller: "..file); return end
if netOk and net then pcall(net.start,"BULDACITY // "..options[n][1],"CLIENT",{screen="ACTIVE",controller=file,protocol="BULDACITY/2"}) end
dofile(path)
