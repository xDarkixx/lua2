--[=[
RotaryCraft Manager - Minecraft 1.7.10 / RotaryCraft V33a
Standalone OpenComputers utility.

Target:
  RotaryCraft 1.7.10 V33a
  OpenComputers on Minecraft 1.7.10

This file is intentionally standalone and does not read or depend on
other Lua files in this repository.

OpenComputers 1.6+ includes RotaryCraft power support, but RotaryCraft
machines are not exposed as one universal component API. This program
therefore provides a safe dashboard for an OC computer and optional
redstone control through an available redstone component.
]=]

local component = require("component")
local event = require("event")
local computer = require("computer")

local gpu = component.isAvailable("gpu") and component.gpu or nil
local screen = component.isAvailable("screen") and component.screen or nil
local redstone = component.isAvailable("redstone") and component.redstone or nil

local W, H = 100, 32
local running = true
local auto = false
local redstoneState = false
local lastMessage = "Bereit"
local ticks = 0

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function safeCall(obj, method, ...)
  if not obj or type(obj[method]) ~= "function" then return nil end
  local ok, a, b, c = pcall(obj[method], obj, ...)
  if ok then return a, b, c end
  return nil
end

local function setup()
  if not gpu then return end
  if screen then pcall(gpu.bind, gpu, screen.address) end
  pcall(gpu.setResolution, gpu, W, H)
end

local function fill(x, y, w, h, bg, fg, text)
  gpu.setBackground(bg)
  gpu.setForeground(fg)
  gpu.fill(x, y, w, h, " ")
  if text then
    gpu.set(x, y, text)
  end
end

local function panel(x, y, w, h, title)
  fill(x, y, w, h, 0x101822, 0x8FA8BF)
  gpu.setForeground(0x3FA7FF)
  gpu.set(x + 2, y, "[ " .. title .. " ]")
  gpu.setForeground(0x30485E)
  gpu.set(x, y + 1, string.rep("─", w))
end

local function bar(x, y, w, value, maxValue, bg, fg)
  value = tonumber(value) or 0
  maxValue = tonumber(maxValue) or 1
  local ratio = clamp(value / math.max(maxValue, 1), 0, 1)
  gpu.setBackground(bg)
  gpu.fill(x, y, w, 1, " ")
  gpu.setBackground(fg)
  gpu.fill(x, y, math.floor(w * ratio), 1, " ")
end

local function line(x, y, text, fg)
  gpu.setForeground(fg or 0xD7E6F5)
  gpu.set(x, y, text)
end

local function drawHeader()
  fill(1, 1, W, 3, 0x102B44, 0xFFFFFF)
  gpu.setForeground(0xFFFFFF)
  gpu.set(3, 2, "ROTARYCRAFT  •  CONTROL CENTER")
  gpu.setForeground(0x78C7FF)
  gpu.set(W - 26, 2, "MC 1.7.10  |  V33a")
end

local function componentSummary()
  local count = 0
  local names = {}
  if redstone then count = count + 1; names[#names + 1] = "redstone" end
  if gpu then count = count + 1; names[#names + 1] = "gpu" end
  if screen then count = count + 1; names[#names + 1] = "screen" end
  return count, table.concat(names, ", ")
end

local function draw()
  if not gpu then return end
  gpu.setBackground(0x071018)
  gpu.fill(1, 1, W, H, " ")
  drawHeader()

  panel(2, 5, 47, 12, "ROTARYCRAFT / OPENCOMPUTERS")
  line(4, 7, "Mod-Version:", 0x8FA8BF)
  line(20, 7, "RotaryCraft 1.7.10 V33a", 0xFFFFFF)
  line(4, 9, "Minecraft:", 0x8FA8BF)
  line(20, 9, "1.7.10", 0xFFFFFF)
  line(4, 11, "OC-Kompatibilität:", 0x8FA8BF)
  line(20, 11, "RotaryCraft Power Support", 0x6FFFA8)
  line(4, 13, "Laufzeit:", 0x8FA8BF)
  line(20, 13, string.format("%ds", math.floor(computer.uptime())), 0xFFFFFF)
  local c, n = componentSummary()
  line(4, 15, "OC-Komponenten:", 0x8FA8BF)
  line(20, 15, tostring(c) .. "  " .. n, 0xFFFFFF)

  panel(51, 5, 47, 12, "CONTROL")
  local stateText = redstoneState and "EIN" or "AUS"
  local stateColor = redstoneState and 0x55FF88 or 0xFF6677
  line(54, 7, "Redstone-Ausgang:", 0x8FA8BF)
  line(74, 7, stateText, stateColor)
  line(54, 9, "Modus:", 0x8FA8BF)
  line(74, 9, auto and "AUTO" or "MANUELL", auto and 0xFFD75A or 0x7EC8FF)
  line(54, 11, "Steuersignal:", 0x8FA8BF)
  bar(54, 12, 39, redstoneState and 1 or 0, 1, 0x202A35, redstoneState and 0x48D17A or 0x6B7785)
  line(54, 14, "Hinweis:", 0x8FA8BF)
  line(64, 14, "OC kann RC-Power verwenden;", 0xD7E6F5)
  line(64, 15, "Maschinenwerte sind blockabhängig.", 0xD7E6F5)

  panel(2, 19, 96, 8, "STATUS / INFORMATION")
  line(4, 21, "Status:", 0x8FA8BF)
  line(14, 21, redstone and "Redstone-Komponente erkannt" or "Keine Redstone-Komponente", redstone and 0x6FFFA8 or 0xFF6677)
  line(4, 23, "Meldung:", 0x8FA8BF)
  line(14, 23, lastMessage, 0xFFFFFF)
  line(4, 25, "RotaryCraft V33a wird als Zielversion verwendet.", 0x78C7FF)

  fill(2, 29, 96, 2, 0x0E1B27, 0x9CB3C7)
  gpu.set(4, 30, "[R] Refresh   [A] Auto   [O] ON   [F] OFF   [Q] Quit")
end

local function setOutput(value)
  if not redstone then
    lastMessage = "Keine Redstone-Komponente vorhanden"
    return false
  end
  local ok = pcall(redstone.setOutput, redstone, value and 15 or 0)
  if not ok then
    ok = pcall(redstone.setOutput, redstone, value and 15 or 0, 0)
  end
  if ok then
    redstoneState = value
    lastMessage = value and "Redstone AUSGANG eingeschaltet" or "Redstone AUSGANG ausgeschaltet"
  else
    lastMessage = "Redstone-Steuerung konnte nicht gesetzt werden"
  end
  return ok
end

local function refresh()
  ticks = ticks + 1
  lastMessage = "Aktualisiert #" .. ticks
  draw()
end

setup()
draw()

while running do
  local ev, a, b = event.pull(1)
  if ev == "key_down" then
    local ch = b
    if ch == string.byte("q") or ch == string.byte("Q") then
      running = false
    elseif ch == string.byte("r") or ch == string.byte("R") then
      refresh()
    elseif ch == string.byte("a") or ch == string.byte("A") then
      auto = not auto
      lastMessage = auto and "Automatik aktiviert" or "Automatik deaktiviert"
      draw()
    elseif ch == string.byte("o") or ch == string.byte("O") then
      auto = false
      setOutput(true)
      draw()
    elseif ch == string.byte("f") or ch == string.byte("F") then
      auto = false
      setOutput(false)
      draw()
    end
  elseif ev == "touch" then
    local x, y = b, a
    if y >= 29 then
      if x < 15 then refresh()
      elseif x < 30 then
        auto = not auto
        lastMessage = auto and "Automatik aktiviert" or "Automatik deaktiviert"
        draw()
      elseif x < 43 then setOutput(true); draw()
      elseif x < 56 then setOutput(false); draw()
      elseif x > 90 then running = false end
    end
  end
end

if gpu then
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, W, H, " ")
  gpu.set(2, 2, "RotaryCraft Manager beendet.")
end
