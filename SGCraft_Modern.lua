-- BULDACITY SGCraft compatibility entry point.
-- Downloads the current SGCraft controller and libraries automatically.
-- Existing local files are replaced with the current repository version.

local component = require("component")
local filesystem = require("filesystem")

local files = {
  {path="/home/SGCraft_Buldacity_v3.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/SGCraft_Buldacity_v3.lua"},
  {path="/home/SGCraftAPI.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftAPI.lua"},
  {path="/home/SGCraftVisual.lua", url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftVisual.lua"}
}

local function getInternet()
  if not component.isAvailable("internet") then
    return nil, "Internet Card fehlt"
  end
  local address = component.list("internet")()
  if not address then
    return nil, "Keine Internet-Komponente gefunden"
  end
  return component.proxy(address)
end

local function download(file)
  local internet, err = getInternet()
  if not internet then return false, err end

  local handle, requestError
  for attempt = 1, 3 do
    local ok, h, e = pcall(internet.request, file.url)
    if ok and h then
      handle = h
      break
    end
    requestError = e or h or "HTTP request fehlgeschlagen"
    computer and computer.pullSignal and computer.pullSignal(0.5)
  end

  if not handle then
    return false, tostring(requestError)
  end

  local temp = file.path .. ".download"
  local out, openError = filesystem.open(temp, "w")
  if not out then
    return false, tostring(openError or "Zieldatei kann nicht geöffnet werden")
  end

  local bytes = 0
  while true do
    local ok, chunk = pcall(handle)
    if not ok then
      out:close()
      filesystem.remove(temp)
      return false, "Download-Stream fehlgeschlagen: " .. tostring(chunk)
    end
    if chunk == nil then break end
    if #chunk > 0 then
      out:write(chunk)
      bytes = bytes + #chunk
    end
  end
  out:close()

  if bytes == 0 then
    filesystem.remove(temp)
    return false, "Download ist leer"
  end

  if filesystem.exists(file.path) then
    filesystem.remove(file.path)
  end
  local moved, moveError = filesystem.rename(temp, file.path)
  if not moved then
    filesystem.remove(temp)
    return false, tostring(moveError or "Download konnte nicht installiert werden")
  end
  return true
end

for _, file in ipairs(files) do
  local ok, err = download(file)
  if not ok then
    error("BULDACITY SGCraft bootstrap fehlgeschlagen: " .. tostring(err))
  end
end

return dofile("/home/SGCraft_Buldacity_v3.lua")
