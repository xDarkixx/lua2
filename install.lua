-- BULDACITY / 2 - OpenComputers installer
-- Downloads the runtime files from the public GitHub repository into /home.
-- Designed for Minecraft 1.7.10 + OpenComputers.

local component = require("component")
local computer = require("computer")
local filesystem = require("filesystem")
local internet = component.isAvailable("internet") and component.internet or nil
local fs = component.isAvailable("filesystem") and component.filesystem or nil

local REPO = "https://raw.githubusercontent.com/xDarkixx/lua2/main/"
local HOME = "/home"
local BACKUP = "/home/buldacity-backup"
local VERSION = "BULDACITY/2 installer 1.0"

local required = {
  "Network.lua",
  "BuldacityUI.lua",
  "BuldacityAutoStart.lua",
  "BuldacityOS_Tier3.lua",
  "BuldacityDesktop.lua",
  "BuldacityComponentAgent.lua",
  "BuldacityComponentServer.lua",
  "BuldacityComponentDashboard.lua",
  "BuldacityNetworkSetup.lua",
  "BuldacityNetworkTest.lua",
  "BuldacityWirelessCheck_Modern.lua",
  "BuldacityApps_Modern.lua",
  "BuldacityNetworkWizard.lua",
  "BuldacityNetworkWizardUI.lua"
}

local optional = {
  "3DPrinterNetwork_Modern.lua", "3DPrinter_Modern.lua",
  "AE2NetworkEndpoint_Modern.lua", "AE2Network_Modern.lua", "AE2Network.lua",
  "DieselGeneratorNetwork_Modern.lua", "DieselGenerator_Modern.lua", "DieselGenerator.lua",
  "ExtraPlanetsNetwork_Modern.lua", "ExtraPlanets_Modern.lua",
  "ForestryNetwork_Modern.lua", "Forestry_Modern.lua",
  "GalacticraftNetwork_Modern.lua", "Galacticraft_Modern.lua",
  "GendustryNetwork_Modern.lua", "Gendustry_Modern.lua",
  "ImmersiveEngineering_Network_Modern.lua", "ImmersiveEngineering_Modern.lua",
  "ImmersiveIntegration_Network_Modern.lua", "ImmersiveIntegration_Modern.lua",
  "ImmersiveRailroading_Network_Modern.lua", "ImmersiveRailroading_Modern.lua",
  "IndustrialCraft2_Network_Modern.lua", "IndustrialCraft2_Modern.lua",
  "LogisticsPipesNetwork_Modern.lua", "LogisticsPipes_Modern.lua",
  "MekanismNetwork_Modern.lua", "Mekanism_Modern.lua",
  "PneumaticCraftNetwork_Modern.lua", "PneumaticCraft_Modern.lua",
  "ProjectENetwork_Modern.lua", "ProjectE_Modern.lua",
  "RFToolsNetwork_Modern.lua", "RFTools_Modern.lua",
  "SGCraftNetwork_Modern.lua", "SGCraft_Modern.lua",
  "ThermalExpansionNetwork_Modern.lua", "ThermalExpansion_Modern.lua",
  "ReactorBigReactors043A_Network.lua", "ReactorBigReactors043A_Touch_Responsive.lua"
}

local function say(text)
  print("[BULDACITY] " .. tostring(text))
end

local function exists(path)
  return filesystem.exists(path)
end

local function mkdir(path)
  if not exists(path) then
    local ok, err = filesystem.makeDirectory(path)
    if not ok and not exists(path) then return false, err end
  end
  return true
end

local function backup(path)
  if not exists(path) then return true end
  mkdir(BACKUP)
  local stamp = tostring(computer.uptime()):gsub("%.", "_")
  local target = BACKUP .. "/" .. stamp .. "-" .. filesystem.name(path)
  local inFile = filesystem.open(path, "r")
  if not inFile then return false, "cannot read existing file" end
  local outFile = filesystem.open(target, "w")
  if not outFile then inFile:close(); return false, "cannot create backup" end
  while true do
    local chunk = inFile:read(4096)
    if not chunk or #chunk == 0 then break end
    outFile:write(chunk)
  end
  inFile:close()
  outFile:close()
  return true
end

local function download(path)
  if not internet then return false, "Internet Card fehlt" end
  local url = REPO .. path
  local handle, err = internet.request(url)
  if not handle then return false, tostring(err or "HTTP request failed") end
  local target = HOME .. "/" .. path
  local parent = filesystem.path(target)
  if parent and parent ~= "" then mkdir(parent) end
  local old = exists(target)
  if old then
    local ok, backupErr = backup(target)
    if not ok then return false, "Backup fehlgeschlagen: " .. tostring(backupErr) end
  end
  local out, openErr = filesystem.open(target, "w")
  if not out then return false, "Datei kann nicht geöffnet werden: " .. tostring(openErr) end
  local total = 0
  while true do
    local chunk = handle()
    if chunk == nil then break end
    if #chunk > 0 then
      out:write(chunk)
      total = total + #chunk
    end
  end
  out:close()
  if total == 0 or not exists(target) then
    return false, "leere oder fehlende Antwort"
  end
  return true, total
end

local function syntaxCheck(path)
  local fn, err = loadfile(path)
  if not fn then return false, err end
  return true
end

local function installList(list, label, optionalFiles)
  say("Installiere " .. label .. "...")
  local okCount, failCount = 0, 0
  for i, path in ipairs(list) do
    io.write("  [" .. i .. "/" .. #list .. "] " .. path .. " ... ")
    local ok, info = download(path)
    if ok then
      local valid, syntaxErr = syntaxCheck(HOME .. "/" .. path)
      if valid then
        print("OK")
        okCount = okCount + 1
      else
        print("SYNTAXFEHLER")
        print("    " .. tostring(syntaxErr))
        failCount = failCount + 1
      end
    else
      if optionalFiles then
        print("übersprungen (optional)")
      else
        print("FEHLER: " .. tostring(info))
        failCount = failCount + 1
      end
    end
  end
  return okCount, failCount
end

local function writeText(path, text)
  local out, err = filesystem.open(path, "w")
  if not out then return false, err end
  out:write(text)
  out:close()
  return true
end

local function installAutorun()
  local text = [[-- BULDACITY / 2 OpenComputers autorun
local ok, err = pcall(function()
  dofile("/home/BuldacityAutoStart.lua")
end)
if not ok then
  print("BULDACITY AUTOSTART FEHLER: " .. tostring(err))
end
]]
  return writeText("/home/autorun.lua", text)
end

local function writeState()
  local text = "BULDACITY_INSTALLER=" .. VERSION .. "\n" ..
               "REPOSITORY=xDarkixx/lua2\n" ..
               "HOME=/home\n" ..
               "PROTOCOL=BULDACITY/2\n" ..
               "PORT=4242\n"
  return writeText("/home/buldacity-install.cfg", text)
end

local function verifyCore()
  local missing, invalid = {}, {}
  for _, path in ipairs(required) do
    local target = HOME .. "/" .. path
    if not exists(target) then
      table.insert(missing, path)
    else
      local ok = syntaxCheck(target)
      if not ok then table.insert(invalid, path) end
    end
  end
  return missing, invalid
end

local function networkCheck()
  local modem = component.isAvailable("modem")
  local wireless = false
  if modem then
    local m = component.modem
    local ok = pcall(function() m.setStrength(400) end)
    wireless = ok
    pcall(function() m.open(4242) end)
  end
  return modem, wireless
end

local function runInstall(allClients)
  if not component.isAvailable("filesystem") then
    say("FEHLER: Es wurde kein Filesystem gefunden. Bitte Tier-3-Festplatte anschließen.")
    return false
  end
  if not component.isAvailable("internet") then
    say("FEHLER: Es wurde keine Internet Card gefunden.")
    say("Der Installer lädt die Dateien direkt aus dem öffentlichen GitHub-Repository.")
    return false
  end
  mkdir(HOME)
  mkdir(BACKUP)

  local ok, failed = installList(required, "BULDACITY-Kern", false)
  if allClients then
    local cOk, cFailed = installList(optional, "Mod-Clients", true)
    ok = ok + cOk
    failed = failed + cFailed
  end

  local autorunOk = installAutorun()
  local stateOk = writeState()
  local missing, invalid = verifyCore()
  local modem, wireless = networkCheck()

  print("")
  say("================ INSTALLATIONSERGEBNIS ================")
  say("Installiert/validiert: " .. tostring(ok))
  say("Fehler: " .. tostring(failed))
  say("Autorun: " .. (autorunOk and "OK" or "FEHLER"))
  say("Installationsstatus: " .. (stateOk and "OK" or "FEHLER"))
  say("Modem: " .. (modem and "ERKANNT" or "nicht erkannt"))
  say("Wireless: " .. (wireless and "unterstützt" or "nicht bestätigt"))
  say("Netzwerkport: 4242")
  say("Protokoll: BULDACITY/2")
  if #missing > 0 then say("Fehlende Kern-Dateien: " .. table.concat(missing, ", ")) end
  if #invalid > 0 then say("Ungültige Lua-Dateien: " .. table.concat(invalid, ", ")) end
  say("Backup: " .. BACKUP)
  say("========================================================")
  return #missing == 0 and #invalid == 0 and failed == 0
end

local function menu()
  while true do
    print("")
    print("========================================")
    print(" BULDACITY / 2 - INSTALLER")
    print("========================================")
    print("1) Kern installieren/reparieren")
    print("2) Alles installieren (Kern + Mod-Clients)")
    print("3) Installation prüfen")
    print("4) Netzwerk/Hardware prüfen")
    print("0) Beenden")
    io.write("> ")
    local choice = io.read()
    if choice == "1" then
      runInstall(false)
    elseif choice == "2" then
      runInstall(true)
    elseif choice == "3" then
      local missing, invalid = verifyCore()
      say("Fehlend: " .. (#missing == 0 and "keine" or table.concat(missing, ", ")))
      say("Syntaxfehler: " .. (#invalid == 0 and "keine" or table.concat(invalid, ", ")))
    elseif choice == "4" then
      local modem, wireless = networkCheck()
      say("Filesystem: " .. (component.isAvailable("filesystem") and "OK" or "FEHLT"))
      say("Internet: " .. (component.isAvailable("internet") and "OK" or "FEHLT"))
      say("Modem: " .. (modem and "OK" or "FEHLT"))
      say("Wireless: " .. (wireless and "OK" or "nicht bestätigt"))
      say("Port: 4242")
    elseif choice == "0" then
      return
    end
  end
end

say(VERSION)
say("GitHub: xDarkixx/lua2")
menu()
