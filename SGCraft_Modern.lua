-- BULDACITY SGCraft bootstrap
-- OpenComputers 1.7.10 compatible.
-- Downloads with the built-in OpenComputers wget program.

local component = require("component")
local filesystem = require("filesystem")
local computer = require("computer")

local files = {
  {name="SGCraft_Buldacity_v3.lua", path="/home/SGCraft_Buldacity_v3.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/SGCraft_Buldacity_v3.lua"},
  {name="SGCraftAPI.lua", path="/home/SGCraftAPI.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftAPI.lua"},
  {name="SGCraftVisual.lua", path="/home/SGCraftVisual.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftVisual.lua"}
}

local function say(text)
  print("[BULDACITY SGCraft] " .. tostring(text))
end

local function runWget(file, tmp)
  -- No shell.quote(), no shell module and no shell.execute().
  -- This avoids the 'nil value field quote' error on older OC builds.
  local wget = loadfile("/bin/wget.lua")
  if not wget then
    wget = loadfile("/usr/bin/wget.lua")
  end
  if not wget then
    return false, "OpenComputers wget.lua wurde nicht gefunden (/bin/wget.lua oder /usr/bin/wget.lua)"
  end

  -- wget.lua is normally a command-line program. Execute it through the shell
  -- only if the OpenComputers shell API is actually available.
  local shellOk, shell = pcall(require, "shell")
  if not shellOk or not shell then
    return false, "OpenComputers shell API nicht verfügbar; wget kann nicht gestartet werden"
  end
  if type(shell.execute) ~= "function" then
    return false, "shell.execute ist in dieser OpenComputers-Version nicht verfügbar"
  end

  local command = "wget -f " .. file.url .. " " .. tmp
  local ok, result = pcall(shell.execute, command)
  if not ok then
    return false, "wget Startfehler: " .. tostring(result)
  end
  return true, result
end

local function downloadWithWget(file)
  if not component.isAvailable("internet") then
    return false, "Keine Internet Card vorhanden"
  end

  local tmp = file.path .. ".download"
  if filesystem.exists(tmp) then filesystem.remove(tmp) end

  -- Keep the original file until the new download is verified.
  local ok, result = runWget(file, tmp)
  if not ok then
    if filesystem.exists(tmp) then filesystem.remove(tmp) end
    return false, result
  end

  if not filesystem.exists(tmp) then
    return false, "wget hat keine Datei erzeugt. Prüfe Internet Card und wget-Version."
  end

  local size = filesystem.size(tmp)
  if not size or size <= 0 then
    filesystem.remove(tmp)
    return false, "wget hat eine leere Datei erzeugt"
  end

  local fn, err = loadfile(tmp)
  if not fn then
    filesystem.remove(tmp)
    return false, "Heruntergeladene Lua-Datei ist ungültig: " .. tostring(err)
  end

  if filesystem.exists(file.path) then filesystem.remove(file.path) end
  local moved, moveErr = filesystem.rename(tmp, file.path)
  if not moved then
    filesystem.remove(tmp)
    return false, "Download konnte nicht installiert werden: " .. tostring(moveErr)
  end

  return true, size
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

say("========================================")
say("BULDACITY SGCraft AUTO DOWNLOADER")
say("wget-Modus / ohne shell.quote")
say("========================================")

if not component.isAvailable("filesystem") then
  error("BULDACITY SGCraft: Kein Filesystem/Tier-3-Laufwerk vorhanden")
end
if not component.isAvailable("internet") then
  error("BULDACITY SGCraft: Keine Internet Card vorhanden")
end

for _, file in ipairs(files) do
  local installed = false
  local lastError = "unbekannter Fehler"
  for attempt = 1, 3 do
    say("Lade " .. file.name .. " (" .. attempt .. "/3)")
    local ok, info = downloadWithWget(file)
    if ok then
      local valid, verifyInfo = verify(file)
      if valid then
        say(file.name .. " -> OK (" .. tostring(verifyInfo) .. " Bytes)")
        installed = true
        break
      end
      lastError = verifyInfo
    else
      lastError = info
      say("Fehler: " .. tostring(info))
    end
    computer.pullSignal(1)
  end
  if not installed then
    error("BULDACITY SGCraft: Download fehlgeschlagen: " .. file.name .. " -> " .. tostring(lastError))
  end
end

say("Alle Dateien OK. Starte Controller ...")
return dofile("/home/SGCraft_Buldacity_v3.lua")
