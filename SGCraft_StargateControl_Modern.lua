-- SGCraft_StargateControl_Modern.lua
-- OpenComputers / Minecraft 1.7.10
-- Graphical SGCraft Stargate controller with persistent address book.
--
-- Features:
--   * SGCraft OpenComputers interface control
--   * 7/9 symbol address entry
--   * Persistent named address book
--   * Load, save, delete and favorite addresses
--   * Recent dialing history
--   * Touch/mouse controls and keyboard fallback
--   * Gate state, chevrons, energy and iris status
--   * Safe component/method/error handling
--
-- Address book is stored locally at /home/sgcraft_addresses.cfg.

local component = require("component")
local event = require("event")
local computer = require("computer")
local serialization = require("serialization")
local term = require("term")
local unicode = require("unicode")

local gpu = component.isAvailable("gpu") and component.gpu or nil
local screen = component.isAvailable("screen") and component.getPrimary("screen") or nil
local sg = component.isAvailable("stargate") and component.getPrimary("stargate") or nil

if not gpu or not screen then
  error("Kein Bildschirm/GPU gefunden. Bitte einen OpenComputers Bildschirm anschließen.")
end

if not sg then
  error("Keine SGCraft-Stargate-Schnittstelle gefunden. Verbinde eine Stargate Interface-Komponente.")
end

local BOOK_FILE = "/home/sgcraft_addresses.cfg"
local MAX_HISTORY = 12
local MAX_BOOK = 100
local symbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local state = {
  address = "",
  selected = nil,
  page = "dial",
  status = "IDLE",
  statusDetail = "Bereit",
  engaged = 0,
  direction = "",
  iris = "UNKNOWN",
  energy = nil,
  width = 80,
  height = 25,
  scroll = 0,
  history = {},
  book = {},
  message = "",
  messageUntil = 0,
  running = true,
  dirty = false
}

local palette = {
  bg = 0x071018,
  panel = 0x0D1B26,
  panel2 = 0x102431,
  line = 0x24495A,
  text = 0xD8F3FF,
  muted = 0x7296A5,
  accent = 0x37C8FF,
  accent2 = 0x1A7899,
  good = 0x45E09A,
  warn = 0xF2C14E,
  bad = 0xF05B66,
  white = 0xFFFFFF,
  black = 0x000000
}

local function safeCall(obj, method, ...)
  if not obj or type(obj[method]) ~= "function" then
    return nil, "Methode nicht verfügbar: " .. tostring(method)
  end
  local ok, a, b, c, d = pcall(obj[method], ...)
  if not ok then
    return nil, tostring(a)
  end
  return a, b, c, d
end

local function normalizeAddress(value)
  value = tostring(value or ""):upper():gsub("%s+", ""):gsub("-", "")
  if #value ~= 7 and #value ~= 9 then
    return nil, "Adresse muss 7 oder 9 Zeichen haben."
  end
  if not value:match("^[A-Z0-9]+$") then
    return nil, "Adresse darf nur A-Z und 0-9 enthalten."
  end
  return value
end

local function displayAddress(address)
  address = address or ""
  if #address == 7 then
    return address:sub(1, 4) .. "-" .. address:sub(5, 7)
  elseif #address == 9 then
    return address:sub(1, 4) .. "-" .. address:sub(5, 7) .. "-" .. address:sub(8, 9)
  end
  return address
end

local function now()
  return computer.uptime()
end

local function notify(text, duration)
  state.message = tostring(text or "")
  state.messageUntil = now() + (duration or 3)
end

local function saveBook()
  local f, err = io.open(BOOK_FILE, "w")
  if not f then
    notify("Adressbuch konnte nicht gespeichert werden: " .. tostring(err), 5)
    return false
  end
  local ok, encoded = pcall(serialization.serialize, {
    version = 2,
    book = state.book,
    history = state.history
  })
  if not ok then
    f:close()
    notify("Adressbuch konnte nicht serialisiert werden.", 5)
    return false
  end
  f:write(encoded)
  f:close()
  state.dirty = false
  return true
end

local function loadBook()
  local f = io.open(BOOK_FILE, "r")
  if not f then return end
  local raw = f:read("*a")
  f:close()
  if not raw or raw == "" then return end

  local ok, data = pcall(serialization.unserialize, raw)
  if not ok or type(data) ~= "table" then
    notify("Adressbuch-Datei ist beschädigt. Neues Buch gestartet.", 5)
    return
  end

  if type(data.book) == "table" then
    for _, entry in ipairs(data.book) do
      if type(entry) == "table" and type(entry.name) == "string" and type(entry.address) == "string" then
        local address = normalizeAddress(entry.address)
        if address and #state.book < MAX_BOOK then
          table.insert(state.book, {
            name = entry.name:sub(1, 32),
            address = address,
            favorite = entry.favorite == true,
            used = tonumber(entry.used) or 0
          })
        end
      end
    end
  end

  if type(data.history) == "table" then
    for _, address in ipairs(data.history) do
      local normalized = normalizeAddress(address)
      if normalized and #state.history < MAX_HISTORY then
        table.insert(state.history, normalized)
      end
    end
  end
end

local function addHistory(address)
  address = normalizeAddress(address)
  if not address then return end
  local new = {address}
  for _, old in ipairs(state.history) do
    if old ~= address and #new < MAX_HISTORY then
      table.insert(new, old)
    end
  end
  state.history = new
  state.dirty = true
end

local function findBook(name, address)
  for i, entry in ipairs(state.book) do
    if (name and entry.name == name) or (address and entry.address == address) then
      return i, entry
    end
  end
  return nil
end

local function saveAddressInteractive()
  local address, err = normalizeAddress(state.address)
  if not address then
    notify(err, 4)
    return
  end

  state.page = "name"
  state.statusDetail = "Namen eingeben und ENTER drücken"
  draw = nil
end

local function insertBookEntry(name, address)
  name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  address = normalizeAddress(address)
  if not address then return false, "Ungültige Adresse." end
  if name == "" then return false, "Name darf nicht leer sein." end

  local existing = findBook(nil, address)
  if existing then
    state.book[existing].name = name:sub(1, 32)
    state.book[existing].used = state.book[existing].used or 0
    state.dirty = true
    return true, "Adresse aktualisiert."
  end

  if #state.book >= MAX_BOOK then
    return false, "Adressbuch ist voll (100 Einträge)."
  end

  table.insert(state.book, {
    name = name:sub(1, 32),
    address = address,
    favorite = false,
    used = 0
  })
  state.dirty = true
  return true, "Adresse gespeichert."
end

local function deleteSelected()
  if not state.selected or not state.book[state.selected] then
    notify("Keine Adresse ausgewählt.", 3)
    return
  end
  table.remove(state.book, state.selected)
  state.selected = nil
  state.dirty = true
  saveBook()
  notify("Adresse gelöscht.", 3)
end

local function toggleFavorite(index)
  local entry = state.book[index]
  if not entry then return end
  entry.favorite = not entry.favorite
  state.dirty = true
  saveBook()
  notify(entry.favorite and "Favorit hinzugefügt." or "Favorit entfernt.", 3)
end

local function getGateState()
  local gateState, engaged, direction = safeCall(sg, "stargateState")
  if gateState then
    state.status = tostring(gateState):upper()
  else
    state.status = "OFFLINE"
  end
  state.engaged = tonumber(engaged) or 0
  state.direction = tostring(direction or "")

  local energy = safeCall(sg, "energyAvailable")
  if type(energy) == "number" then
    state.energy = energy
  else
    state.energy = nil
  end

  if type(sg.getIrisState) == "function" then
    local iris = safeCall(sg, "getIrisState")
    if iris ~= nil then
      state.iris = tostring(iris):upper()
    end
  end
end

local function dialAddress(address)
  local normalized, err = normalizeAddress(address)
  if not normalized then
    notify(err, 4)
    return false
  end

  getGateState()
  if state.status ~= "IDLE" and state.status ~= "CLOSING" then
    notify("Gate ist aktuell " .. state.status .. ".", 4)
    return false
  end

  local ok, callErr = safeCall(sg, "dial", normalized)
  if ok == nil and callErr then
    notify("Wählen fehlgeschlagen: " .. callErr, 5)
    return false
  end

  state.address = normalized
  addHistory(normalized)
  local _, entry = findBook(nil, normalized)
  if entry then
    entry.used = (entry.used or 0) + 1
    state.dirty = true
  end
  saveBook()
  notify("Wähle " .. displayAddress(normalized), 4)
  return true
end

local function disconnectGate()
  local ok, err = safeCall(sg, "disconnect")
  if ok == nil and err then
    notify("Trennen fehlgeschlagen: " .. err, 4)
  else
    notify("Verbindung getrennt.", 3)
  end
end

local function toggleIris()
  if type(sg.closeIris) ~= "function" or type(sg.openIris) ~= "function" then
    notify("Diese Stargate-Version unterstützt keine Irissteuerung.", 4)
    return
  end
  getGateState()
  local iris = state.iris
  if iris:find("CLOSED") or iris:find("SHUT") then
    local ok, err = safeCall(sg, "openIris")
    if ok == nil and err then notify("Iris öffnen fehlgeschlagen: " .. err, 4) end
  else
    local ok, err = safeCall(sg, "closeIris")
    if ok == nil and err then notify("Iris schließen fehlgeschlagen: " .. err, 4) end
  end
end

local function setBG(color)
  gpu.setBackground(color)
end

local function setFG(color)
  gpu.setForeground(color)
end

local function fill(x, y, w, h, color, char)
  setBG(color)
  gpu.fill(x, y, w, h, char or " ")
end

local function text(x, y, value, color, maxWidth)
  value = tostring(value or "")
  if maxWidth and unicode.len(value) > maxWidth then
    value = unicode.sub(value, 1, math.max(1, maxWidth - 1)) .. "…"
  end
  setFG(color or palette.text)
  gpu.set(x, y, value)
end

local function box(x, y, w, h, color)
  fill(x, y, w, h, color, " ")
  setFG(palette.line)
  gpu.set(x, y, string.rep("─", math.max(0, w - 1)) .. (w > 1 and "┐" or ""))
  if h > 1 then
    gpu.set(x, y + h - 1, "└" .. string.rep("─", math.max(0, w - 2)) .. (w > 1 and "┘" or ""))
  end
  for yy = y + 1, y + h - 2 do
    gpu.set(x, yy, "│")
    if w > 1 then gpu.set(x + w - 1, yy, "│") end
  end
end

local function button(x, y, w, label, action, active)
  local color = active and palette.accent2 or palette.panel2
  fill(x, y, w, 3, color, " ")
  setFG(active and palette.white or palette.text)
  local labelWidth = unicode.len(label)
  local tx = x + math.max(1, math.floor((w - labelWidth) / 2))
  gpu.set(tx, y + 2 - 1, label)
  setFG(palette.line)
  gpu.set(x, y, "┌" .. string.rep("─", math.max(0, w - 2)) .. "┐")
  gpu.set(x, y + 2, "└" .. string.rep("─", math.max(0, w - 2)) .. "┘")
  return {x = x, y = y, w = w, h = 3, action = action}
end

local hitboxes = {}

local function addButton(x, y, w, label, action, active)
  table.insert(hitboxes, button(x, y, w, label, action, active))
end

local function inside(b, x, y)
  return x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h
end

local function drawHeader()
  fill(1, 1, state.width, 4, palette.panel)
  text(3, 2, "STARGATE COMMAND", palette.accent)
  text(3, 3, "SGCraft / OpenComputers Control Interface", palette.muted)
  text(state.width - 20, 2, "LOCAL CONTROL", palette.good)
  text(state.width - 20, 3, os.date("%H:%M:%S"), palette.muted)
end

local function drawGate()
  local cx = math.floor(state.width * 0.30)
  local cy = 13
  local r = math.min(9, math.floor(state.height * 0.32))

  text(cx - 11, 6, "STARGATE", palette.accent)
  text(cx - 11, 7, state.status, state.status == "CONNECTED" and palette.good or palette.text)

  for i = 1, 18 do
    local a = (i / 18) * math.pi * 2
    local x = math.floor(cx + math.cos(a) * r)
    local y = math.floor(cy + math.sin(a) * r * 0.45)
    if x >= 2 and x <= state.width then
      text(x, y, "●", i <= state.engaged and palette.accent or palette.line)
    end
  end

  for i = 1, 9 do
    local a = ((i - 1) / 9) * math.pi * 2 - math.pi / 2
    local x = math.floor(cx + math.cos(a) * (r + 1))
    local y = math.floor(cy + math.sin(a) * (r + 1) * 0.45)
    local color = i <= state.engaged and palette.accent or palette.muted
    text(x, y, tostring(i), color)
  end

  if state.status == "CONNECTED" or state.status == "OPENING" then
    fill(cx - 8, cy - 2, 16, 5, palette.accent2, "·")
    text(cx - 6, cy, "WORMHOLE", palette.white)
  else
    text(cx - 4, cy, "OFFLINE", palette.muted)
  end
end

local function drawAddressPanel()
  local x = math.floor(state.width * 0.52)
  local w = state.width - x - 2
  box(x, 6, w, 7, palette.panel)
  text(x + 2, 7, "TARGET ADDRESS", palette.accent)
  text(x + 2, 9, displayAddress(state.address), palette.white, w - 4)
  text(x + 2, 11, (#state.address) .. " / 7-9 SYMBOLS", palette.muted)

  addButton(x + 2, 12, math.max(12, math.floor(w / 3) - 2), "WÄHLEN", function()
    dialAddress(state.address)
  end, false)
  addButton(x + math.floor(w / 3) + 1, 12, math.max(12, math.floor(w / 3) - 2), "ADRESSBUCH", function()
    state.page = "book"
  end, state.page == "book")
  addButton(x + 2 * math.floor(w / 3), 12, math.max(10, w - 2 * math.floor(w / 3) - 2), "LÖSCHEN", function()
    state.address = ""
  end, false)
end

local function drawSymbols()
  local x = 3
  local y = state.height - 8
  local cols = 12
  local bw = math.max(5, math.floor((state.width * 0.56) / cols))
  text(x, y - 1, "DHD SYMBOLS", palette.accent)
  for i = 1, #symbols do
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    local bx = x + col * bw
    local by = y + row * 2
    if by + 1 <= state.height - 1 then
      fill(bx, by, bw - 1, 2, palette.panel2, " ")
      text(bx + math.floor((bw - 2) / 2), by, symbols:sub(i, i), palette.text)
      table.insert(hitboxes, {x = bx, y = by, w = bw - 1, h = 2, action = function()
        if #state.address < 9 then
          state.address = state.address .. symbols:sub(i, i)
        end
      end})
    end
  end
end

local function drawFooter()
  local y = state.height - 1
  fill(1, y, state.width, 2, palette.panel)
  local energy = state.energy and string.format("ENERGY %.0f", state.energy) or "ENERGY --"
  text(2, y, energy, palette.muted)
  text(math.floor(state.width * 0.25), y, "IRIS " .. state.iris, palette.muted)
  text(math.floor(state.width * 0.48), y, "CHEVRONS " .. tostring(state.engaged), palette.muted)
  text(math.floor(state.width * 0.70), y, state.direction ~= "" and state.direction or "STANDBY", palette.muted)
end

local function drawBook()
  fill(1, 5, state.width, state.height - 6, palette.bg, " ")
  text(3, 6, "STARGATE ADDRESS BOOK", palette.accent)
  text(3, 7, "Dauerhaft gespeichert auf diesem Computer", palette.muted)

  local y = 9
  local visible = state.height - 13
  local rows = {}
  for i, entry in ipairs(state.book) do
    if entry.favorite or true then
      table.insert(rows, {index = i, entry = entry})
    end
  end

  local start = state.scroll + 1
  local finish = math.min(#rows, start + visible - 1)
  for n = start, finish do
    local item = rows[n]
    local entry = item.entry
    local idx = item.index
    local selected = state.selected == idx
    fill(3, y, state.width - 6, 2, selected and palette.accent2 or palette.panel)
    text(5, y, entry.favorite and "★" or "·", entry.favorite and palette.warn or palette.muted)
    text(8, y, entry.name, palette.white, 24)
    text(34, y, displayAddress(entry.address), palette.accent, 15)
    text(51, y, "USED " .. tostring(entry.used or 0), palette.muted)
    table.insert(hitboxes, {x = 3, y = y, w = state.width - 6, h = 2, action = function()
      state.selected = idx
      state.address = entry.address
    end})
    y = y + 2
  end

  addButton(3, state.height - 5, 14, "LADEN", function()
    if state.selected and state.book[state.selected] then
      state.address = state.book[state.selected].address
      state.page = "dial"
      notify("Adresse geladen.", 3)
    end
  end, false)
  addButton(19, state.height - 5, 14, "FAVORIT", function()
    if state.selected then toggleFavorite(state.selected) end
  end, false)
  addButton(35, state.height - 5, 14, "LÖSCHEN", deleteSelected, false)
  addButton(51, state.height - 5, 14, "ZURÜCK", function()
    state.page = "dial"
  end, false)
  addButton(67, state.height - 5, 10, "NEU", function()
    state.page = "dial"
    state.address = ""
    notify("Neue Adresse eingeben.", 3)
  end, false)
end

local function drawNameInput()
  fill(1, 5, state.width, state.height - 6, palette.bg, " ")
  local w = math.min(60, state.width - 10)
  local x = math.floor((state.width - w) / 2)
  local y = math.floor(state.height / 2) - 3
  box(x, y, w, 8, palette.panel)
  text(x + 3, y + 2, "ADRESSE SPEICHERN", palette.accent)
  text(x + 3, y + 3, displayAddress(state.address), palette.white)
  text(x + 3, y + 5, "Name eingeben:", palette.muted)
  text(x + 18, y + 5, state.statusDetail or "", palette.white, w - 21)
  text(x + 3, y + 6, "ENTER = speichern   ESC = abbrechen", palette.muted)
end

local function draw()
  if not state.running then return end
  local sw, sh = gpu.getResolution()
  state.width, state.height = sw, sh
  if sw < 60 or sh < 20 then
    fill(1, 1, sw, sh, palette.bg, " ")
    text(2, 2, "SGC Interface benötigt mindestens 60x20.", palette.warn)
    return
  end

  hitboxes = {}
  getGateState()
  fill(1, 1, sw, sh, palette.bg, " ")
  drawHeader()

  if state.page == "book" then
    drawBook()
  elseif state.page == "name" then
    drawNameInput()
  else
    drawGate()
    drawAddressPanel()
    drawSymbols()
    addButton(sw - 18, sh - 8, 15, "TRENNEN", disconnectGate, false)
    addButton(sw - 18, sh - 5, 15, "IRIS", toggleIris, false)
    addButton(sw - 18, sh - 2, 15, "SPEICHERN", saveAddressInteractive, false)
    drawFooter()
  end

  if state.message ~= "" and now() < state.messageUntil then
    local msg = state.message
    fill(3, 4, math.min(sw - 6, unicode.len(msg) + 4), 1, palette.accent2, " ")
    text(5, 4, msg, palette.white, sw - 10)
  elseif state.message ~= "" then
    state.message = ""
  end
end

local function promptName()
  local value = ""
  while true do
    drawNameInput()
    text(math.floor(state.width / 2) - 10, math.floor(state.height / 2) + 2, value, palette.white, 30)
    local ev = {event.pull(0.2)}
    if ev[1] == "key_down" then
      local char, code = ev[3], ev[4]
      if code == 28 then
        return value
      elseif code == 1 then
        return nil
      elseif code == 14 then
        value = unicode.sub(value, 1, math.max(0, unicode.len(value) - 1))
      elseif char and char >= 32 and char <= 126 and unicode.len(value) < 32 then
        value = value .. string.char(char)
      end
    elseif ev[1] == "interrupted" then
      return nil
    end
  end
end

local function handleClick(x, y)
  for i = #hitboxes, 1, -1 do
    local b = hitboxes[i]
    if inside(b, x, y) then
      local ok, err = pcall(b.action)
      if not ok then notify("UI-Fehler: " .. tostring(err), 5) end
      return true
    end
  end
  return false
end

local function handleKeyboard(char, code)
  if code == 1 then
    state.page = "dial"
    state.statusDetail = "Bereit"
    return
  end
  if state.page == "dial" then
    if code == 14 then
      state.address = state.address:sub(1, -2)
      return
    end
    if code == 28 then
      dialAddress(state.address)
      return
    end
    if char and char >= 32 and char <= 126 then
      local c = string.char(char):upper()
      if symbols:find(c, 1, true) and #state.address < 9 then
        state.address = state.address .. c
      end
    end
  elseif state.page == "book" then
    if code == 14 and state.scroll > 0 then state.scroll = state.scroll - 1 end
  end
end

loadBook()
term.clear()

while state.running do
  draw()
  local ev = {event.pull(0.25)}
  local name = ev[1]

  if name == "touch" or name == "drag" then
    handleClick(ev[3], ev[4])
  elseif name == "key_down" then
    handleKeyboard(ev[3], ev[4])
  elseif name == "sgStargateStateChange" or name == "sgChevronEngaged" or name == "sgDialIn" or name == "sgDialOut" or name == "sgIrisStateChange" then
    -- State is polled on every redraw. These events simply wake the UI faster.
  elseif name == "component_removed" or name == "component_available" then
    if not component.isAvailable("stargate") then
      state.status = "OFFLINE"
      sg = nil
    else
      sg = component.getPrimary("stargate")
    end
  elseif name == "interrupted" then
    state.running = false
  end

  if state.page == "name" then
    local nameValue = promptName()
    if nameValue == nil then
      state.page = "dial"
      notify("Speichern abgebrochen.", 3)
    else
      local ok, msg = insertBookEntry(nameValue, state.address)
      saveBook()
      state.page = "dial"
      notify(msg, 4)
    end
  end
end

if state.dirty then saveBook() end
term.clear()
print("SGCraft Controller beendet.")
