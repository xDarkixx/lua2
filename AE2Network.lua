-- Applied Energistics 2 Network Manager
-- Minecraft 1.7.10
--
-- Target mod versions:
--   appliedenergistics2-rv3-beta-6
--   ae2stuff-rv3-0.5.1.9-mc1.7.10
--   ae2fc-1.7.10-g92699c9
--   ae2ee3emcaddon-1.7.10-b8-universal
--
-- OpenComputers access:
--   Adapter connected to an AE2 ME Controller/network block.
--   Component: me_controller
--
-- Controls:
--   R = refresh
--   I = show item list
--   C = show craftable list
--   Q = quit

local component = require("component")
local event = require("event")
local computer = require("computer")

local gpu = component.gpu
local me = component.me_controller

if not me then
  error("Kein me_controller gefunden. OpenComputers Adapter mit dem AE2-Netzwerk verbinden.")
end

local W, H = 132, 38
local version = "1.0.0"
local running = true
local page = "HOME"
local items = {}
local craftables = {}
local lastError = nil
local lastUpdate = 0

local C = {
  bg = 0x080B10,
  panel = 0x111722,
  panel2 = 0x182131,
  border = 0x334155,
  blue = 0x2563EB,
  cyan = 0x06B6D4,
  green = 0x16A34A,
  lime = 0x65A30D,
  yellow = 0xEAB308,
  orange = 0xEA580C,
  red = 0xDC2626,
  purple = 0x9333EA,
  white = 0xF8FAFC,
  text = 0xCBD5E1,
  muted = 0x64748B,
  dark = 0x030712,
  black = 0x000000
}

local function safeCall(fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if ok then return true, a, b, c end
  return false, nil, nil, a
end

local function fill(x, y, w, h, bg)
  gpu.setBackground(bg)
  gpu.fill(x, y, w, h, " ")
end

local function text(x, y, s, fg, bg)
  gpu.setForeground(fg or C.text)
  if bg then gpu.setBackground(bg) end
  gpu.set(x, y, tostring(s))
end

local function centered(y, s, fg, bg)
  s = tostring(s)
  local x = math.max(1, math.floor((W - #s) / 2) + 1)
  text(x, y, s, fg, bg)
end

local function box(x, y, w, h, title, accent)
  fill(x, y, w, h, C.panel)
  gpu.setForeground(C.border)
  gpu.setBackground(C.panel)
  gpu.fill(x, y, w, 1, "─")
  gpu.fill(x, y + h - 1, w, 1, "─")
  gpu.fill(x, y, 1, h, "│")
  gpu.fill(x + w - 1, y, 1, h, "│")
  gpu.setBackground(accent or C.blue)
  gpu.fill(x, y, 1, h, " ")
  text(x + 3, y, " " .. title .. " ", accent or C.cyan, C.panel)
end

local function shorten(s, n)
  s = tostring(s or "--")
  if #s <= n then return s end
  return string.sub(s, 1, n - 3) .. "..."
end

local function amountOf(entry)
  if type(entry) ~= "table" then return 0 end
  return tonumber(entry.size or entry.amount or entry.count or 0) or 0
end

local function nameOf(entry)
  if type(entry) ~= "table" then return tostring(entry or "--") end
  return tostring(entry.label or entry.name or entry.id or "unknown")
end

local function refresh()
  lastError = nil

  local ok, result, _, err = safeCall(me.getItemsInNetwork)
  if ok and type(result) == "table" then
    items = result
  elseif not ok then
    items = {}
    lastError = tostring(err)
  else
    items = {}
  end

  local ok2, result2, _, err2 = safeCall(me.getCraftables)
  if ok2 and type(result2) == "table" then
    craftables = result2
  elseif not ok2 then
    craftables = {}
    if not lastError then lastError = tostring(err2) end
  else
    craftables = {}
  end

  lastUpdate = computer.uptime()
end

local function drawHeader()
  gpu.setBackground(C.blue)
  gpu.fill(1, 1, W, 4, " ")
  centered(2, "APPLIED ENERGISTICS 2  •  ME NETWORK", C.white, C.blue)
  centered(3, "OPENCOMPUTERS NETWORK MANAGER  v" .. version, 0xBFDBFE, C.blue)
  centered(4, "MC 1.7.10  •  AE2 rv3 beta 6", 0xDBEAFE, C.blue)
end

local function drawHome()
  box(2, 6, 62, 13, "ME NETWORK", C.cyan)
  text(6, 8, "CONNECTION", C.muted)
  text(20, 8, "● ONLINE", C.green)
  text(6, 11, "ITEM TYPES", C.muted)
  text(20, 11, #items, C.cyan)
  text(6, 13, "CRAFTABLE TYPES", C.muted)
  text(20, 13, #craftables, C.purple)
  text(6, 16, "COMPONENT", C.muted)
  text(20, 16, "me_controller", C.white)
  text(6, 18, "STATUS", C.muted)
  text(20, 18, lastError and "ERROR" or "READY", lastError and C.red or C.green)

  box(66, 6, 64, 13, "NETWORK OVERVIEW", C.blue)
  text(70, 8, "STORAGE", C.muted)
  text(84, 8, #items .. " item types", C.white)
  text(70, 11, "CRAFTING", C.muted)
  text(84, 11, #craftables .. " craftables", C.white)
  text(70, 14, "TARGET", C.muted)
  text(84, 14, "AE2 rv3 beta 6", C.yellow)
  text(70, 17, "UPDATED", C.muted)
  text(84, 17, string.format("%.1fs ago", computer.uptime() - lastUpdate), C.text)

  box(2, 21, 128, 9, "QUICK VIEW", C.purple)
  text(6, 23, "TOP STORED ITEMS", C.muted)
  local shown = math.min(#items, 5)
  for i = 1, shown do
    local e = items[i]
    local y = 25 + i - 1
    text(7, y, string.format("%d.", i), C.cyan)
    text(11, y, shorten(nameOf(e), 42), C.white)
    text(58, y, string.format("%d", amountOf(e)), C.green)
  end
  if shown == 0 then text(7, 25, "Keine Einträge oder Netzwerk noch nicht geladen.", C.muted) end

  box(2, 32, 128, 5, "CONTROLS", C.blue)
  text(6, 34, "[R]", C.yellow);  text(11, 34, "REFRESH", C.text)
  text(27, 34, "[I]", C.cyan);   text(32, 34, "ITEMS", C.text)
  text(49, 34, "[C]", C.purple); text(54, 34, "CRAFTABLES", C.text)
  text(80, 34, "[Q]", C.red);    text(85, 34, "QUIT", C.text)
end

local function drawList(title, list, accent, kind)
  box(2, 6, 128, 30, title, accent)
  text(6, 8, "#", C.muted)
  text(11, 8, kind == "ITEM" and "STORED ITEM" or "CRAFTABLE", C.muted)
  text(82, 8, kind == "ITEM" and "AMOUNT" or "ENTRY", C.muted)

  local maxRows = 25
  local shown = math.min(#list, maxRows)
  for i = 1, shown do
    local e = list[i]
    local y = 9 + i
    local n = nameOf(e)
    text(6, y, string.format("%02d", i), C.cyan)
    text(11, y, shorten(n, 68), C.white)
    if kind == "ITEM" then
      text(82, y, string.format("%d", amountOf(e)), C.green)
    else
      text(82, y, "AVAILABLE", C.green)
    end
    if i < shown then
      text(11, y + 1, string.rep("─", 98), C.border)
    end
  end

  if #list == 0 then
    text(11, 12, kind == "ITEM" and "Keine Items gefunden." or "Keine Craftables gefunden.", C.muted)
  elseif #list > maxRows then
    text(11, 35, "+ " .. (#list - maxRows) .. " weitere Einträge", C.yellow)
  end

  text(6, 37, "[R] REFRESH   [I] ITEMS   [C] CRAFTABLES   [Q] QUIT", C.text)
end

local function draw()
  gpu.setResolution(W, H)
  gpu.setBackground(C.bg)
  gpu.setForeground(C.white)
  gpu.fill(1, 1, W, H, " ")
  drawHeader()

  if page == "HOME" then
    drawHome()
  elseif page == "ITEMS" then
    drawList("ME STORAGE / ITEMS", items, C.cyan, "ITEM")
  elseif page == "CRAFTABLES" then
    drawList("ME CRAFTING / CRAFTABLES", craftables, C.purple, "CRAFT")
  end

  if lastError then
    text(6, 38, "ERROR: " .. shorten(lastError, 118), C.red)
  end
end

refresh()
draw()

while running do
  local e = {event.pull(0.5)}
  if e[1] == "key_down" then
    local char = e[3]
    if char == string.byte("r") or char == string.byte("R") then
      refresh()
    elseif char == string.byte("i") or char == string.byte("I") then
      page = "ITEMS"
    elseif char == string.byte("c") or char == string.byte("C") then
      page = "CRAFTABLES"
    elseif char == string.byte("q") or char == string.byte("Q") then
      running = false
    end
  end

  if computer.uptime() - lastUpdate >= 3 then
    refresh()
  end
  draw()
end

gpu.setBackground(C.black)
gpu.setForeground(C.white)
gpu.fill(1, 1, W, H, " ")
centered(math.floor(H / 2), "AE2 ME Network Manager beendet.", C.text, C.black)
