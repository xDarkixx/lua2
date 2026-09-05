-- SGCraft_Modern.lua
-- BULDACITY // SGCraft Stargate Command Center
-- Minecraft 1.7.10 / SGCraft 1.13.3 / OpenComputers
-- Standalone local controller. No external UI library required.

local component = require("component")
local event = require("event")
local computer = require("computer")
local shell = require("shell")

local gpu = component.gpu
local W, H = gpu.getResolution()
local running = true
local page = "HOME"
local selected = 1
local target = ""
local message = ""
local notice = "Ready"
local gates = {}
local log = {}
local buttons = {}
local lastState = {}
local pulse = 0

local C = {
  bg = 0x050811,
  panel = 0x0B1220,
  panel2 = 0x111C2E,
  panel3 = 0x17263C,
  line = 0x24415C,
  cyan = 0x20E6FF,
  blue = 0x4D7CFF,
  green = 0x37F59A,
  yellow = 0xFFD35A,
  red = 0xFF4D69,
  purple = 0xB96CFF,
  white = 0xEAF7FF,
  muted = 0x71879E,
  dark = 0x1B293A,
  black = 0x000000
}

local function safe(fn, ...)
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then return a, b, c, d end
  return nil, a
end

local function text(x, y, s, fg, bg)
  if x < 1 or y < 1 or x > W or y > H then return end
  gpu.setForeground(fg or C.white)
  gpu.setBackground(bg or C.bg)
  gpu.set(x, y, tostring(s or ""))
end

local function fill(x, y, w, h, bg)
  if w <= 0 or h <= 0 then return end
  gpu.setBackground(bg or C.bg)
  gpu.fill(x, y, w, h, " ")
end

local function fit(s, n)
  s = tostring(s or "")
  n = math.max(0, n or 0)
  if #s <= n then return s end
  if n <= 3 then return s:sub(1, n) end
  return s:sub(1, n - 3) .. "..."
end

local function logAdd(s)
  log[#log + 1] = os.date("%H:%M:%S") .. "  " .. tostring(s)
  while #log > 7 do table.remove(log, 1) end
  notice = tostring(s)
end

local function panel(x, y, w, h, title, accent)
  fill(x, y, w, h, C.panel)
  fill(x, y, w, 1, accent)
  text(x + 2, y, "[ " .. fit(title, math.max(0, w - 5)) .. " ]", C.white, accent)
  if h > 2 then fill(x + 1, y + h - 1, w - 2, 1, C.line) end
end

local function button(id, x, y, w, label, accent, active)
  buttons[id] = {x=x, y=y, w=w, h=2}
  local bg = active and C.white or (accent or C.cyan)
  local fg = active and (accent or C.cyan) or C.white
  fill(x, y, w, 2, bg)
  text(x + math.max(1, math.floor((w - #label) / 2)), y, fit(label, w - 2), fg, bg)
end

local function hit(x, y)
  for id, b in pairs(buttons) do
    if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then
      return id
    end
  end
  return nil
end

local function scan()
  gates = {}
  for address in component.list("stargate", true) do
    local proxy = component.proxy(address)
    gates[#gates + 1] = {address=address, proxy=proxy}
  end
  if selected > #gates then selected = #gates end
  if selected < 1 then selected = 1 end
  logAdd("SCAN complete: " .. tostring(#gates) .. " interface(s)")
end

local function gate()
  return gates[selected]
end

local function read(g)
  if not g then return nil end
  local p = g.proxy
  local state, engaged, direction = safe(p.stargateState)
  local localAddress = safe(p.localAddress)
  local remoteAddress = safe(p.remoteAddress)
  local energy = safe(p.energyAvailable)
  local iris = safe(p.irisState)
  local need = nil
  if target ~= "" then need = safe(p.energyToDial, target) end
  return {
    component=g.address,
    state=state or "Offline",
    engaged=tonumber(engaged) or 0,
    direction=(direction ~= "" and direction) or "-",
    localAddress=(localAddress ~= "" and localAddress) or "-",
    remoteAddress=(remoteAddress ~= "" and remoteAddress) or "-",
    energy=tonumber(energy) or 0,
    iris=iris or "Offline",
    need=tonumber(need) or 0
  }
end

local function callGate(method, ...)
  local g = gate()
  if not g then
    logAdd("No Stargate interface selected")
    return false
  end
  local a, b = safe(g.proxy[method], g.proxy, ...)
  if a == nil and b then
    logAdd(string.upper(method) .. ": " .. tostring(b))
    return false
  end
  return true
end

local function dial()
  if target == "" then logAdd("DIAL: enter a 7/9 symbol address") return end
  if callGate("dial", target) then logAdd("DIAL -> " .. target) end
end

local function disconnect()
  if callGate("disconnect") then logAdd("WORMHOLE DISCONNECTED") end
end

local function iris(open)
  if callGate(open and "openIris" or "closeIris") then
    logAdd(open and "IRIS OPEN" or "IRIS CLOSED")
  end
end

local function send()
  if message == "" then logAdd("LINK: message is empty") return end
  if callGate("sendMessage", message) then logAdd("LINK TX -> " .. message) end
end

local function colorForState(s)
  if s == "Connected" then return C.green end
  if s == "Dialling" or s == "Opening" then return C.cyan end
  if s == "Closing" then return C.yellow end
  if s == "Offline" then return C.red end
  return C.muted
end

local function drawRing(cx, cy, radius, gd)
  local active = gd and gd.state ~= "Offline" and gd.state ~= "Idle"
  local pulseOn = (math.floor(pulse * 3) % 2) == 0
  local ringColor = active and C.cyan or C.dark

  -- Character-based high resolution Stargate ring.
  for deg = 0, 359, 5 do
    local a = math.rad(deg)
    local x = math.floor(cx + math.cos(a) * radius + 0.5)
    local y = math.floor(cy + math.sin(a) * radius * 0.48 + 0.5)
    local ch = (deg % 15 == 0) and "●" or "•"
    text(x, y, ch, ringColor, C.panel)
  end

  -- Inner event horizon / wormhole animation.
  if active then
    local phase = math.floor(pulse * 6) % 4
    local chars = {"·", "•", "●", "•"}
    local ch = chars[phase + 1]
    for r = 1, radius - 4, 2 do
      local n = math.max(8, math.floor(2 * math.pi * r))
      for i = 0, n - 1, math.max(1, math.floor(n / 18)) do
        local a = (i / n) * math.pi * 2 + pulse * 0.8
        local x = math.floor(cx + math.cos(a) * r + 0.5)
        local y = math.floor(cy + math.sin(a) * r * 0.48 + 0.5)
        text(x, y, ch, pulseOn and C.blue or C.cyan, C.panel)
      end
    end
  else
    text(cx - 5, cy, "STANDBY", C.muted, C.panel)
  end

  -- Nine SGCraft chevrons around the gate.
  local engaged = gd and gd.engaged or 0
  for i = 1, 9 do
    local a = math.rad(-90 + (i - 1) * 40)
    local x = math.floor(cx + math.cos(a) * (radius + 2) + 0.5)
    local y = math.floor(cy + math.sin(a) * (radius + 2) * 0.48 + 0.5)
    local on = i <= engaged
    local col = on and (pulseOn and C.white or C.cyan) or C.dark
    text(x - 1, y, "◆", col, C.panel)
    text(x - 1, y + 1, tostring(i), on and C.cyan or C.muted, C.panel)
  end
end

local function drawHeader()
  fill(1, 1, W, 4, C.panel)
  text(2, 1, "BULDACITY", C.cyan, C.panel)
  text(14, 1, "// STARGATE COMMAND CENTER", C.white, C.panel)
  text(math.max(1, W - 22), 1, "SGCRAFT / OC 1.7.10", C.muted, C.panel)
  text(2, 2, "LOCAL CONTROL", C.green, C.panel)
  text(18, 2, fit(notice, math.max(1, W - 20)), C.muted, C.panel)
  fill(1, 4, W, 1, C.cyan)
end

local function drawFleet(x, y, w, h)
  panel(x, y, w, h, "GATE FLEET", C.blue)
  if #gates == 0 then
    text(x + 2, y + 3, "NO STARGATE INTERFACE", C.red, C.panel)
    text(x + 2, y + 5, "Check OpenComputers cable", C.muted, C.panel)
    text(x + 2, y + 6, "and SGCraft interface block.", C.muted, C.panel)
    return
  end
  for i, g in ipairs(gates) do
    local yy = y + 2 + (i - 1) * 3
    if yy + 1 >= y + h - 1 then break end
    local gd = read(g)
    local active = i == selected
    fill(x + 1, yy, w - 2, 2, active and C.panel3 or C.panel)
    text(x + 2, yy, active and "▶" or " ", C.cyan, active and C.panel3 or C.panel)
    text(x + 4, yy, fit(g.address, w - 7), C.white, active and C.panel3 or C.panel)
    text(x + 4, yy + 1, fit(gd.state, w - 7), colorForState(gd.state), active and C.panel3 or C.panel)
  end
end

local function drawTelemetry(x, y, w, h, gd)
  panel(x, y, w, h, "LIVE TELEMETRY", C.cyan)
  if not gd then
    text(x + 3, y + 3, "NO GATE SELECTED", C.red, C.panel)
    return
  end
  local stateCol = colorForState(gd.state)
  text(x + 2, y + 2, "STATE", C.muted, C.panel)
  text(x + 13, y + 2, fit(gd.state, w - 15), stateCol, C.panel)
  text(x + 2, y + 4, "DIRECTION", C.muted, C.panel)
  text(x + 13, y + 4, fit(gd.direction, w - 15), C.white, C.panel)
  text(x + 2, y + 6, "CHEVRONS", C.muted, C.panel)
  text(x + 13, y + 6, tostring(gd.engaged) .. " / 9", C.cyan, C.panel)
  text(x + 2, y + 8, "ENERGY", C.muted, C.panel)
  text(x + 13, y + 8, tostring(gd.energy) .. " SU", C.yellow, C.panel)
  local barW = math.max(8, w - 4)
  local maxEnergy = math.max(gd.energy, gd.need, 1)
  local pct = math.min(100, gd.energy / maxEnergy * 100)
  fill(x + 2, y + 9, barW, 1, C.dark)
  fill(x + 2, y + 9, math.floor(barW * pct / 100), 1, C.yellow)
  text(x + 2, y + 11, "IRIS", C.muted, C.panel)
  text(x + 13, y + 11, gd.iris, gd.iris == "Closed" and C.green or C.yellow, C.panel)
  text(x + 2, y + 13, "LOCAL", C.muted, C.panel)
  text(x + 2, y + 14, fit(gd.localAddress, w - 4), C.white, C.panel)
  text(x + 2, y + 16, "REMOTE", C.muted, C.panel)
  text(x + 2, y + 17, fit(gd.remoteAddress, w - 4), C.cyan, C.panel)
  if page == "DIAL" and target ~= "" then
    text(x + 2, y + 19, "DIAL COST", C.muted, C.panel)
    text(x + 13, y + 19, tostring(gd.need) .. " SU", C.yellow, C.panel)
  end
end

local function drawCenter(x, y, w, h, gd)
  panel(x, y, w, h, "STARGATE VISUAL", C.purple)
  local cx = x + math.floor(w / 2)
  local cy = y + math.floor(h / 2) + 1
  local radius = math.min(math.floor(w * 0.32), math.floor(h * 0.70))
  radius = math.max(7, radius)
  drawRing(cx, cy, radius, gd)
  if gd then
    text(cx - math.floor(#gd.state / 2), cy + radius * 0.55, gd.state, colorForState(gd.state), C.panel)
  end
end

local function drawBottom(x, y, w, h, gd)
  panel(x, y, w, h, page == "DIAL" and "DIAL CONSOLE" or page == "IRIS" and "IRIS SECURITY" or page == "LINK" and "STARGATE LINK" or "SYSTEM", C.green)
  if page == "DIAL" then
    text(x + 2, y + 2, "TARGET", C.muted, C.panel)
    text(x + 10, y + 2, fit(target == "" and "TYPE ADDRESS" or target, w - 30), C.cyan, C.panel)
    button("dial", x + w - 25, y + 1, 10, "DIAL", C.green, false)
    button("disconnect", x + w - 14, y + 1, 12, "CLOSE", C.red, false)
  elseif page == "IRIS" then
    text(x + 2, y + 2, "CURRENT", C.muted, C.panel)
    text(x + 11, y + 2, gd and gd.iris or "-", C.yellow, C.panel)
    button("open", x + w - 27, y + 1, 10, "OPEN", C.green, false)
    button("close", x + w - 16, y + 1, 10, "CLOSE", C.red, false)
  elseif page == "LINK" then
    text(x + 2, y + 2, "MESSAGE", C.muted, C.panel)
    text(x + 11, y + 2, fit(message == "" and "TYPE MESSAGE" or message, w - 28), C.white, C.panel)
    button("send", x + w - 13, y + 1, 11, "SEND", C.green, false)
  else
    text(x + 2, y + 2, "Q", C.cyan, C.panel)
    text(x + 4, y + 2, "EXIT", C.muted, C.panel)
    text(x + 12, y + 2, "TAB", C.cyan, C.panel)
    text(x + 16, y + 2, "NEXT GATE", C.muted, C.panel)
    text(x + 29, y + 2, "R", C.cyan, C.panel)
    text(x + 31, y + 2, "RESCAN", C.muted, C.panel)
  end
end

local function drawNav()
  local labels = {{"HOME","HOME",C.cyan},{"GATES","GATES",C.blue},{"DIAL","DIAL",C.purple},{"IRIS","IRIS",C.yellow},{"LINK","LINK",C.green},{"SCAN","SCAN",C.cyan}}
  local y = H - 3
  local bw = math.max(8, math.floor((W - 8) / #labels))
  local x = 2
  for _, v in ipairs(labels) do
    button(v[1], x, y, bw, v[2], v[3], page == v[1])
    x = x + bw + 1
  end
end

local function drawLog()
  local h = 4
  local y = H - h - 4
  if y < 6 then return end
  panel(2, y, W - 3, h, "EVENT LOG", C.line)
  local start = math.max(1, #log - 1)
  for i = start, #log do
    text(4, y + 1 + i - start, fit(log[i], W - 6), C.muted, C.panel)
  end
end

local function draw()
  W, H = gpu.getResolution()
  buttons = {}
  fill(1, 1, W, H, C.bg)
  drawHeader()

  local top = 6
  local bottomH = 4
  local logH = 4
  local contentH = H - top - bottomH - logH - 2
  if contentH < 12 then contentH = 12 end
  local leftW = math.max(22, math.min(30, math.floor(W * 0.22)))
  local rightW = math.max(25, math.min(33, math.floor(W * 0.25)))
  local centerW = W - leftW - rightW - 7
  if centerW < 30 then centerW = 30 end

  drawFleet(2, top, leftW, contentH)
  local gd = read(gate())
  drawCenter(4 + leftW, top, centerW, contentH, gd)
  drawTelemetry(6 + leftW + centerW, top, rightW, contentH, gd)

  drawLog()
  drawBottom(2, H - bottomH - 1, W - 3, bottomH, gd)
  drawNav()
end

local function processText(ch)
  if not ch then return false end
  if page == "DIAL" then
    if ch >= 32 and ch <= 126 then target = target .. string.char(ch):upper() return true end
  elseif page == "LINK" then
    if ch >= 32 and ch <= 126 then message = message .. string.char(ch) return true end
  end
  return false
end

local function keyAction(ch)
  if ch == 113 then running = false; return end -- q
  if ch == 114 then scan(); return end -- r
  if ch == 9 then selected = (#gates > 0 and (selected % #gates) + 1 or 1); return end
  if ch == 8 then
    if page == "DIAL" then target = target:sub(1, -2) end
    if page == "LINK" then message = message:sub(1, -2) end
    return
  end
  if ch == 100 then page = "DIAL"; return end -- d
  if ch == 105 then page = "IRIS"; return end -- i
  if ch == 108 then page = "LINK"; return end -- l
  if ch == 99 then disconnect(); return end -- c
  if ch == 111 then iris(true); return end -- o
  if ch == 112 then iris(false); return end -- p
  if ch == 13 and page == "DIAL" then dial(); return end
  if ch == 13 and page == "LINK" then send(); return end
  processText(ch)
end

local function touchAction(id, x, y)
  if id == "HOME" then page = "HOME"
  elseif id == "GATES" then page = "GATES"
  elseif id == "DIAL" then page = "DIAL"
  elseif id == "IRIS" then page = "IRIS"
  elseif id == "LINK" then page = "LINK"
  elseif id == "SCAN" then scan()
  elseif id == "dial" then dial()
  elseif id == "disconnect" then disconnect()
  elseif id == "open" then iris(true)
  elseif id == "close" then iris(false)
  elseif id == "send" then send()
  elseif page == "GATES" then
    local fleetTop = 8
    local index = math.floor((y - fleetTop) / 3) + 1
    if index >= 1 and index <= #gates then selected = index end
  end
end

scan()
logAdd("SGCraft controller online")

while running do
  pulse = computer.uptime()
  local g = gate()
  if g then
    local gd = read(g)
    local old = lastState[g.address]
    if old and gd.state ~= old then logAdd("STATE: " .. old .. " -> " .. gd.state) end
    lastState[g.address] = gd.state
  end

  draw()
  local ev, _, a, b, c = event.pull(0.12)
  if ev == "key_down" then
    keyAction(c)
  elseif ev == "touch" then
    local id = hit(a, b)
    if id then touchAction(id, a, b) end
  elseif ev == "sgStargateStateChange" then
    logAdd("SG STATE EVENT")
  elseif ev == "sgChevronEngaged" then
    logAdd("CHEVRON " .. tostring(b) .. " ENGAGED")
  elseif ev == "sgIrisStateChange" then
    logAdd("IRIS: " .. tostring(b))
  elseif ev == "sgDialIn" then
    logAdd("INCOMING: " .. tostring(b))
  elseif ev == "sgDialOut" then
    logAdd("OUTGOING: " .. tostring(b))
  elseif ev == "sgMessageReceived" then
    logAdd("REMOTE: " .. tostring(b))
  end
end

fill(1, 1, W, H, C.black)
gpu.setForeground(C.white)
gpu.setBackground(C.black)
text(2, 2, "SGCraft controller stopped.", C.white, C.black)
