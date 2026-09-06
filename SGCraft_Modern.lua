-- BULDACITY SGCraft bootstrap
-- OpenComputers 1.7.10 compatible.
-- Downloads the controller and its libraries before starting the UI.

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

local function internetAvailable()
  return component.isAvailable("internet")
end

local function writeStream(url, target)
  if not internetAvailable() then
    return false, "Keine Internet Card vorhanden"
  end

  local internet = component.internet
  local tmp = target .. ".download"
  if filesystem.exists(tmp) then
    filesystem.remove(tmp)
  end

  local ok, handle, err = pcall(internet.request, url)
  if not ok then
    return false, "internet.request Fehler: " .. tostring(handle)
  end
  if not handle then
    return false, "HTTP request fehlgeschlagen: " .. tostring(err or "unbekannter Fehler")
  end

  local out, openErr = filesystem.open(tmp, "wb")
  if not out then
    return false, "Temporäre Datei kann nicht geöffnet werden: " .. tostring(openErr)
  end

  local bytes = 0
  local streamOK, streamErr = pcall(function()
    for chunk in handle do
      if chunk and #chunk > 0 then
        out:write(chunk)
        bytes = bytes + #chunk
      end
    end
  end)
  out:close()

  if not streamOK then
    filesystem.remove(tmp)
    return false, "Download-Stream Fehler: " .. tostring(streamErr)
  end
  if bytes <= 0 or not filesystem.exists(tmp) then
    filesystem.remove(tmp)
    return false, "Server hat keine Daten geliefert"
  end

  if filesystem.exists(target) then
    filesystem.remove(target)
  end
  local moved, moveErr = filesystem.rename(tmp, target)
  if not moved then
    filesystem.remove(tmp)
    return false, "Datei konnte nicht installiert werden: " .. tostring(moveErr)
  end
  return true, bytes
end

local function wgetFallback(url, target)
  local tmp = target .. ".wget"
  if filesystem.exists(tmp) then filesystem.remove(tmp) end

  local command = "wget -f " .. shell.quote(url) .. " " .. shell.quote(tmp)
  local ok, result = pcall(shell.execute, command)
  if not ok then
    return false, "wget konnte nicht gestartet werden: " .. tostring(result)
  end
  if not filesystem.exists(tmp) then
    return false, "wget hat keine Datei erzeugt"
  end
  local size = filesystem.size(tmp)
  if not size or size <= 0 then
    filesystem.remove(tmp)
    return false, "wget-Datei ist leer"
  end
  if filesystem.exists(target) then filesystem.remove(target) end
  local moved, moveErr = filesystem.rename(tmp, target)
  if not moved then
    filesystem.remove(tmp)
    return false, "wget-Datei konnte nicht übernommen werden: " .. tostring(moveErr)
  end
  return true, size
end

local function download(file)
  say("Lade " .. file.name .. " ...")

  local lastError = nil
  for attempt = 1, 3 do
    local ok, info = writeStream(file.url, file.path)
    if ok then
      say(file.name .. " -> " .. tostring(info) .. " Bytes")
      return true
    end
    lastError = info
    say("Versuch " .. attempt .. "/3 fehlgeschlagen: " .. tostring(info))
    computer.pullSignal(0.5)
  end

  say("Nutze OpenComputers wget als Fallback ...")
  local ok, info = wgetFallback(file.url, file.path)
  if ok then
    say(file.name .. " -> wget OK (" .. tostring(info) .. " Bytes)")
    return true
  end

  return false, tostring(lastError) .. " | wget: " .. tostring(info)
end

local function verify(file)
  if not filesystem.exists(file.path) then
    return false, "Datei fehlt nach Download"
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

say("Starte automatischen SGCraft-Download")
if not component.isAvailable("filesystem") then
  error("BULDACITY SGCraft: Kein Filesystem/Tier-3-Laufwerk vorhanden")
end
if not component.isAvailable("internet") then
  error("BULDACITY SGCraft: Keine Internet Card. Eine Internet Card wird zum automatischen Download benötigt.")
end

for _, file in ipairs(files) do
  local ok, err = download(file)
  if not ok then
    error("BULDACITY SGCraft Download fehlgeschlagen: " .. file.name .. " -> " .. tostring(err))
  end
  local valid, info = verify(file)
  if not valid then
    error("BULDACITY SGCraft Prüfung fehlgeschlagen: " .. file.name .. " -> " .. tostring(info))
  end
end

say("Alle SGCraft-Dateien erfolgreich geladen und geprüft.")
say("Starte BULDACITY SGCraft Controller ...")
return dofile("/home/SGCraft_Buldacity_v3.lua")
