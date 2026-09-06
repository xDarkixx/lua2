-- BULDACITY SGCraft bootstrap
-- OpenComputers 1.7.10 compatible.
-- Uses OpenComputers wget exclusively to download the controller and libraries.

local component = require("component")
local filesystem = require("filesystem")
local computer = require("computer")
local shell = require("shell")

local files = {
  {name="SGCraft_Buldacity_v3.lua", path="/home/SGCraft_Buldacity_v3.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/SGCraft_Buldacity_v3.lua"},
  {name="SGCraftAPI.lua", path="/home/SGCraftAPI.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftAPI.lua"},
  {name="SGCraftVisual.lua", path="/home/SGCraftVisual.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftVisual.lua"}
}

local function say(text)
  print("[BULDACITY SGCraft] " .. tostring(text))
end

local function downloadWithWget(file)
  if not component.isAvailable("internet") then
    return false, "Keine Internet Card vorhanden"
  end

  local tmp = file.path .. ".download"
  if filesystem.exists(tmp) then
    filesystem.remove(tmp)
  end

  if filesystem.exists(file.path) then
    filesystem.remove(file.path)
  end

  -- Do not use shell.quote(): it is not available in all OpenComputers 1.7.10 builds.
  -- These URLs and target paths contain no spaces, so plain arguments are safe here.
  local command = "wget -f " .. file.url .. " " .. tmp
  say("wget: " .. file.url)

  local ok, result = pcall(shell.execute, command)
  if not ok then
    if filesystem.exists(tmp) then filesystem.remove(tmp) end
    return false, "wget konnte nicht gestartet werden: " .. tostring(result)
  end

  if not filesystem.exists(tmp) then
    return false, "wget hat keine Datei erzeugt"
  end

  local size = filesystem.size(tmp)
  if not size or size <= 0 then
    filesystem.remove(tmp)
    return false, "wget hat eine leere Datei erzeugt"
  end

  local moved, moveErr = filesystem.rename(tmp, file.path)
  if not moved then
    filesystem.remove(tmp)
    return false, "wget-Datei konnte nicht installiert werden: " .. tostring(moveErr)
  end

  return true, size
end

local function verify(file)
  if not filesystem.exists(file.path) then
    return false, "Datei fehlt nach wget"
  end

  local size = filesystem.size(file.path)
  if not size or size <= 0 then
    return false, "Datei ist leer"
  end

  local fn, err = loadfile(file.path)
  if not fn then
    return false, "Lua-Syntaxfehler: " .. tostring(err)
  end

  return true, size
end

say("========================================")
say("BULDACITY SGCraft AUTO DOWNLOADER")
say("Download-Methode: OpenComputers wget")
say("========================================")

if not component.isAvailable("filesystem") then
  error("BULDACITY SGCraft: Kein Filesystem/Tier-3-Laufwerk vorhanden")
end

if not component.isAvailable("internet") then
  error("BULDACITY SGCraft: Keine Internet Card vorhanden. wget benötigt eine Internet Card.")
end

for _, file in ipairs(files) do
  local installed = false
  local lastError = "unbekannter Fehler"

  for attempt = 1, 3 do
    say("Lade " .. file.name .. " (Versuch " .. attempt .. "/3)")
    local ok, info = downloadWithWget(file)
    if ok then
      local valid, verifyInfo = verify(file)
      if valid then
        say(file.name .. " -> OK (" .. tostring(verifyInfo) .. " Bytes)")
        installed = true
        break
      else
        lastError = verifyInfo
        say("Prüfung fehlgeschlagen: " .. tostring(verifyInfo))
      end
    else
      lastError = info
      say("wget Fehler: " .. tostring(info))
    end
    computer.pullSignal(1)
  end

  if not installed then
    error("BULDACITY SGCraft: Download endgültig fehlgeschlagen: " .. file.name .. " -> " .. tostring(lastError))
  end
end

say("Alle Dateien wurden mit wget geladen und geprüft.")
say("Starte BULDACITY SGCraft Controller ...")
return dofile("/home/SGCraft_Buldacity_v3.lua")
