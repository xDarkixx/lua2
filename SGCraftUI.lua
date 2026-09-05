-- SGCraftUI.lua
-- BULDACITY // SGCraft command center
-- UI only. No network code.

local component = require("component")
local gpu = component.gpu

local UI = {}
UI.buttons = {}

UI.C = {
  bg = 0x03060D,
  panel = 0x0A1220,
  panel2 = 0x0E1A2B,
  line = 0x1B3850,
  cyan = 0x22E6FF,
  blue = 0x3D7CFF,
  green = 0x3CFF9A,
  yellow = 0xFFD65A,
  red = 0xFF4E6E,
  purple = 0xB86CFF,
  white = 0xEAF7FF,
  muted = 0x66819A,
  off = 0x203041
}

function UI.resize()
  local w, h = gpu.getResolution()
  UI.W = w
  UI.H = h
  return w, h
end

local function text(x, y, value, fg, bg)
  if x < 1 or y < 1 or x > UI.W or y > UI.H then
    return
  end
  gpu.setForeground(fg or UI.C.white)
  gpu.setBackground(bg or UI.C.bg)
  gpu.set(x, y, tostring(value or ""))
end

local function fill(x, y, w, h, bg)
  if w < 1 or h < 1 then
    return
  end
  gpu.setBackground(bg or UI.C.panel)
  gpu.fill(x, y, w, h, " ")
end

local function fit(value, width)
  local s = tostring(value or "")
  if width < 1 then
    return ""
  end
  if #s <= width then
    return s
  end
  if width <= 3 then
    return s:sub(1, width)
  end
  return s:sub(1, width - 3) .. "..."
end

local function panel(x, y, w, h, title, accent)
  fill(x, y, w, h, UI.C.panel)
  fill(x, y, w, 1, accent)
  text(x + 2, y, "[ " .. fit(title, w - 5) .. " ]", UI.C.white, accent)
  if h > 2 then
    fill(x + 1, y + h - 1, w - 2, 1, UI.C.line)
  end
end

function UI.button(id, x, y, w, label, accent, active)
  local bg = accent or UI.C.cyan
  local fg = UI.C.white
  if active then
    bg = UI.C.white
    fg = accent or UI.C.cyan
  end
  UI.buttons[id] = { x = x, y = y, w = w, h = 2 }
  fill(x, y, w, 2, bg)
  local px = x + math.floor((w - #label) / 2)
  if px < x + 1 then
    px = x + 1
  end
  text(px, y, fit(label, w - 2), fg, bg)
end

function UI.hit(id, x, y)
  local b = UI.buttons[id]
  if b == nil then
    return false
  end
  return x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h
end

local function bar(x, y, w, percent, color)
  local p = tonumber(percent) or 0
  if p < 0 then p = 0 end
  if p > 100 then p = 100 end
  fill(x, y, w, 1, UI.C.panel2)
  local n = math.floor(w * p / 100)
  if n > 0 then
    fill(x, y, n, 1, color)
  end
end

local function led(x, y, active, color, label)
  if active then
    fill(x, y, 2, 1, color)
    text(x + 3, y, label, color, UI.C.panel)
  else
    fill(x, y, 2, 1, UI.C.off)
    text(x + 3, y, label, UI.C.muted, UI.C.panel)
  end
end

local function drawGate(cx, cy, state, chevrons)
  local active = false
  if state == "Connected" then active = true end
  if state == "Opening" then active = true end
  if state == "Dialling" then active = true end

  local symbol = "O"
  local phase = math.floor(os.clock() * 4) % 4
  if phase == 1 then symbol = "0" end
  if phase == 2 then symbol = "o" end
  if phase == 3 then symbol = "0" end

  text(cx, cy, symbol, active and UI.C.cyan or UI.C.muted, UI.C.panel)
  text(cx - 4, cy + 2, active and "STARGATE ONLINE" or "STARGATE IDLE", active and UI.C.cyan or UI.C.muted, UI.C.panel)

  local count = tonumber(chevrons) or 0
  local i = 1
  while i <= 9 do
    local x = cx - 13 + (i - 1) * 3
    local c = UI.C.off
    if i <= count then
      c = UI.C.cyan
    end
    fill(x, cy + 5, 2, 1, c)
    text(x, cy + 6, tostring(i), i <= count and UI.C.cyan or UI.C.muted, UI.C.panel)
    i = i + 1
  end
end

function UI.draw(data)
  data = data or {}
  UI.resize()
  UI.buttons = {}

  fill(1, 1, UI.W, UI.H, UI.C.bg)
  fill(1, 1, UI.W, 4, UI.C.panel)
  text(2, 1, "BULDACITY", UI.C.cyan, UI.C.panel)
  text(14, 1, "// SGCraft COMMAND", UI.C.white, UI.C.panel)
  text(math.max(1, UI.W - 15), 1, "MC1.7.10", UI.C.muted, UI.C.panel)
  text(2, 2, fit(data.title or "STARGATE CONTROL", UI.W - 4), UI.C.muted, UI.C.panel)
  fill(1, 4, UI.W, 1, UI.C.cyan)

  local left = 2
  local leftWidth = math.floor(UI.W * 0.25)
  if leftWidth < 25 then leftWidth = 25 end
  if leftWidth > 34 then leftWidth = 34 end

  local right = left + leftWidth + 2
  local rightWidth = UI.W - right - 1
  if rightWidth < 20 then rightWidth = 20 end

  panel(left, 6, leftWidth, UI.H - 9, "GATE FLEET", UI.C.blue)

  local gates = data.gates or {}
  if #gates == 0 then
    text(left + 2, 9, "NO INTERFACE", UI.C.red, UI.C.panel)
    text(left + 2, 11, "PRESS SCAN", UI.C.muted, UI.C.panel)
  else
    local i = 1
    while i <= #gates do
      local y = 8 + (i - 1) * 3
      if y > UI.H - 6 then
        break
      end
      local g = gates[i]
      local selected = i == (data.selected or 1)
      fill(left + 1, y, leftWidth - 2, 2, selected and UI.C.panel2 or UI.C.panel)
      text(left + 2, y, selected and ">" or " ", UI.C.cyan, selected and UI.C.panel2 or UI.C.panel)
      text(left + 4, y, fit(g.address, leftWidth - 7), UI.C.white, selected and UI.C.panel2 or UI.C.panel)
      led(left + 4, y + 1, g.state == "Connected", UI.C.green, fit(g.state or "Offline", leftWidth - 8))
      i = i + 1
    end
  end

  panel(right, 6, rightWidth, UI.H - 9, "LIVE TELEMETRY", UI.C.cyan)
  local gate = data.gate

  if gate == nil then
    text(right + 3, 9, "NO GATE SELECTED", UI.C.red, UI.C.panel)
    text(right + 3, 11, "Use SCAN or select a gate.", UI.C.muted, UI.C.panel)
  else
    text(right + 3, 8, "STATE", UI.C.muted, UI.C.panel)
    text(right + 13, 8, fit(gate.state or "Unknown", 16), UI.C.white, UI.C.panel)

    text(right + 3, 10, "DIRECTION", UI.C.muted, UI.C.panel)
    text(right + 15, 10, fit(gate.direction or "-", 14), UI.C.white, UI.C.panel)

    text(right + 3, 12, "LOCAL ADDRESS", UI.C.muted, UI.C.panel)
    text(right + 3, 13, fit(gate.localAddress or "-", 18), UI.C.white, UI.C.panel)

    text(right + 3, 15, "REMOTE ADDRESS", UI.C.muted, UI.C.panel)
    text(right + 3, 16, fit(gate.remote or "-", 18), UI.C.cyan, UI.C.panel)

    text(right + 3, 18, "CHEVRONS", UI.C.muted, UI.C.panel)
    text(right + 14, 18, tostring(gate.chevrons or 0) .. " / 9", UI.C.cyan, UI.C.panel)

    text(right + 3, 20, "ENERGY", UI.C.muted, UI.C.panel)
    text(right + 13, 20, tostring(gate.energy or 0) .. " SU", UI.C.yellow, UI.C.panel)
    bar(right + 3, 21, rightWidth - 6, gate.energyPct, UI.C.yellow)

    text(right + 3, 23, "IRIS", UI.C.muted, UI.C.panel)
    text(right + 10, 23, gate.iris or "-", gate.iris == "Closed" and UI.C.green or UI.C.yellow, UI.C.panel)

    local cx = right + math.floor(rightWidth * 0.62)
    local cy = 12
    drawGate(cx, cy, gate.state, gate.chevrons)
  end

  if data.page == "dial" then
    panel(left, UI.H - 12, UI.W - 3, 7, "DIAL TARGET", UI.C.purple)
    text(left + 3, UI.H - 10, "TARGET", UI.C.muted, UI.C.panel)
    text(left + 12, UI.H - 10, fit(data.target == "" and "TYPE ADDRESS" or data.target, UI.W - 17), UI.C.cyan, UI.C.panel)
    text(left + 3, UI.H - 8, "ENERGY", UI.C.muted, UI.C.panel)
    text(left + 12, UI.H - 8, tostring(data.energyNeed or "-") .. " / " .. tostring(gate and gate.energy or 0) .. " SU", UI.C.yellow, UI.C.panel)
    UI.button("dialNow", left + 3, UI.H - 6, 14, "DIAL", UI.C.green, false)
    UI.button("disconnect", left + 19, UI.H - 6, 18, "DISCONNECT", UI.C.red, false)
  elseif data.page == "iris" then
    panel(left, UI.H - 12, UI.W - 3, 7, "IRIS SECURITY", UI.C.yellow)
    text(left + 3, UI.H - 10, "CURRENT", UI.C.muted, UI.C.panel)
    text(left + 13, UI.H - 10, gate and gate.iris or "-", UI.C.yellow, UI.C.panel)
    UI.button("openIris", left + 3, UI.H - 6, 14, "OPEN", UI.C.green, false)
    UI.button("closeIris", left + 19, UI.H - 6, 14, "CLOSE", UI.C.red, false)
  elseif data.page == "link" then
    panel(left, UI.H - 12, UI.W - 3, 7, "SECURE LINK", UI.C.green)
    text(left + 3, UI.H - 10, "MESSAGE", UI.C.muted, UI.C.panel)
    text(left + 13, UI.H - 10, fit(data.message == "" and "TYPE MESSAGE" or data.message, UI.W - 17), UI.C.white, UI.C.panel)
    UI.button("sendMessage", left + 3, UI.H - 6, 14, "SEND", UI.C.green, false)
  end

  local labels = {
    { "status", "STATUS", UI.C.cyan },
    { "gates", "GATES", UI.C.blue },
    { "dial", "DIAL", UI.C.purple },
    { "iris", "IRIS", UI.C.yellow },
    { "link", "LINK", UI.C.green },
    { "scan", "SCAN", UI.C.cyan }
  }

  local navY = UI.H - 4
  local navWidth = math.floor((UI.W - 8) / #labels)
  if navWidth < 8 then navWidth = 8 end
  local x = 2
  local n = 1
  while n <= #labels do
    local item = labels[n]
    UI.button(item[1], x, navY, navWidth, item[2], item[3], data.page == item[1])
    x = x + navWidth + 1
    n = n + 1
  end

  text(2, UI.H - 1, "Q EXIT | TAB NEXT | D DIAL | X DISCONNECT | O/C IRIS | M SEND", UI.C.muted, UI.C.bg)
end

return UI
