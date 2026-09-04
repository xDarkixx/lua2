-- BuldacityAutoStart.lua
-- Automatic startup for BULDACITY/2 after an OpenComputers reboot.
-- Install this file as /home/autorun.lua on the computer.
-- Role is selected by /home/buldacity-role.cfg:
--   SERVER  -> starts BuldacityOS_Tier3.lua
--   CLIENT  -> starts the configured Network client controller
--
-- Default role is CLIENT so a copied client setup cannot accidentally create
-- another central BULDACITY server.

local computer=require("computer")
local filesystem=require("filesystem")

local ROLE_FILE="/home/buldacity-role.cfg"
local DEFAULT_ROLE="CLIENT"

local CLIENTS={
  ["3DPrinter"]="3DPrinterNetwork_Modern.lua",
  ["AE2"]="AE2NetworkEndpoint_Modern.lua",
  ["DieselGenerator"]="DieselGeneratorNetwork_Modern.lua",
  ["ExtraPlanets"]="ExtraPlanetsNetwork_Modern.lua",
  ["Forestry"]="ForestryNetwork_Modern.lua",
  ["Galacticraft"]="GalacticraftNetwork_Modern.lua",
  ["Gendustry"]="GendustryNetwork_Modern.lua",
  ["ImmersiveEngineering"]="ImmersiveEngineering_Network_Modern.lua",
  ["ImmersiveIntegration"]="ImmersiveIntegration_Network_Modern.lua",
  ["ImmersiveRailroading"]="ImmersiveRailroading_Network_Modern.lua",
  ["IndustrialCraft2"]="IndustrialCraft2_Network_Modern.lua",
  ["LogisticsPipes"]="LogisticsPipesNetwork_Modern.lua",
  ["Mekanism"]="MekanismNetwork_Modern.lua",
  ["PneumaticCraft"]="PneumaticCraftNetwork_Modern.lua",
  ["ProjectE"]="ProjectENetwork_Modern.lua",
  ["RFTools"]="RFToolsNetwork_Modern.lua",
  ["RotaryCraft"]="RotaryCraftNetwork_Modern.lua",
  ["SGCraft"]="SGCraftNetwork_Modern.lua",
  ["ThermalExpansion"]="ThermalExpansionNetwork_Modern.lua",
  ["BigReactors"]="ReactorBigReactors043A_Network.lua"
}

local function trim(s)
  return tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function readConfig()
  local role=DEFAULT_ROLE
  local client=nil
  if filesystem.exists(ROLE_FILE) then
    local f=io.open(ROLE_FILE,"r")
    if f then
      for line in f:lines() do
        line=trim(line)
        if line~="" and not line:match("^#") then
          local k,v=line:match("^([^=]+)=(.*)$")
          if k then
            k=trim(k):upper();v=trim(v)
            if k=="ROLE" then role=v:upper()
            elseif k=="CLIENT" then client=v end
          end
        end
      end
      f:close()
    end
  end
  return role,client
end

local function start(path)
  if not filesystem.exists("/"..path) then
    io.stderr:write("BULDACITY AUTOSTART: missing /"..path.."\n")
    return false
  end
  local ok,err=xpcall(function() dofile("/"..path) end,debug.traceback)
  if not ok then
    io.stderr:write("BULDACITY AUTOSTART FAILED: "..tostring(err).."\n")
    return false
  end
  return true
end

-- Small delay gives OpenComputers components/network time to initialize.
computer.beep(880,0.05)
computer.pullSignal(1)

local role,client=readConfig()
if role=="SERVER" then
  start("BuldacityOS_Tier3.lua")
elseif role=="CLIENT" then
  local file=CLIENTS[client or ""]
  if not file then
    io.stderr:write("BULDACITY AUTOSTART: CLIENT is not configured.\n")
    io.stderr:write("Edit "..ROLE_FILE.." and set CLIENT=<name>.\n")
    io.stderr:write("Example: CLIENT=BigReactors\n")
    return
  end
  start(file)
else
  io.stderr:write("BULDACITY AUTOSTART: invalid ROLE="..tostring(role).."\n")
  io.stderr:write("Use ROLE=SERVER or ROLE=CLIENT in "..ROLE_FILE.."\n")
end
