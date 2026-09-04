--[=[
ROTARYCRAFT ADVANCED DASHBOARD
Minecraft 1.7.10
RotaryCraft V33a
OpenComputers-MC1.7.10-1.8.10+667626d-universal

Standalone file.
This program does NOT read, require, or modify any other Lua file
in this repository.

The dashboard discovers RotaryCraft/OpenComputers components at runtime
and safely probes common RotaryCraft computer methods when available.
It is deliberately defensive because RotaryCraft machines expose different
computer methods depending on the machine type and integration available.
]=]

local component = require("component")
local event = require("event")
local computer = require("computer")
local unicode = require("unicode")

local gpu = component.isAvailable("gpu") and component.gpu or nil
local screen = component.isAvailable("screen") and component.screen or nil
local redstone = component.isAvailable("redstone") and component.redstone or nil

local W, H = 120, 40
local running = true
local selected = 1
local components = {}
local lastUpdate = 0
local message = "System bereit"
local page = 1
local autoRefresh = true

local C = {
  bg = 0x071019,
  panel = 0x0E1A25,
  panel2 = 0x102331,
  header = 0x123B59,
  line = 0x24445A,
  white = 0xF2F7FB,
  muted = 0x8FA7B8,
  blue = 0x4CB8FF,
  cyan = 0x59E6FF,
  green = 0x55E58A,
  yellow = 0xFFD45C,
  orange = 0xFF9B55,
  red = 0xFF5F6D,
  purple = 0xC28CFF
}

local function clamp(v, lo, hi)
  v = tonumber(v) or 0
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function num(v)
  return tonumber(v)
end

local function fmt(v, decimals)
  v = num(v)
  if not v then return "N/A" end
  decimals = decimals or 0
  return string.format("%." .. decimals .. "f", v)
end

local function compact(v)
  v = num(v)
  if not v then return "N/A" end
  local a = math.abs(v)
  if a >= 1000000000 then return string.format("%.2f G", v / 1000000000) end
  if a >= 1000000 then return string.format("%.2f M", v / 1000000) end
  if a >= 1000 then return string.format("%.2f k", v / 1000) end
  return string.format("%.1f", v)
end

local function safe(obj, method, ...)
  if not obj then return nil end
  local f = obj[method]
  if type(f) ~= "function" then return nil end
  local ok, a, b, c, d = pcall(f, obj, ...)
  if ok then return a, b, c, d end
  return nil
end

local function clear(bg)
  gpu.setBackground(bg or C.bg)
  gpu.fill(1, 1, W, H, " ")
end

local function text(x, y, s, fg)
  if not gpu then return end
  s = tostring(s or "")
  gpu.setForeground(fg or C.white)
  gpu.set(x, y, s)
end

local function fill(x, y, w, h, bg, fg, s)
  gpu.setBackground(bg)
  gpu.setForeground(fg or C.white)
  gpu.fill(x, y, w, h, " ")
  if s then gpu.set(x, y, s) end
end

local function hline(x, y, w, color)
  gpu.setBackground(color or C.line)
  gpu.fill(x, y, w, 1, " ")
end

local function panel(x, y, w, h, title)
  fill(x, y, w, h, C.panel, C.white)
  gpu.setBackground(C.header)
  gpu.fill(x, y, w, 2, " ")
  text(x + 2, y, "▣ " .. title, C.white)
  hline(x, y + 2, w, C.line)
end

local function bar(x, y, w, value, maximum, fg, bg)
  value = num(value) or 0
  maximum = math.max(num(maximum) or 1, 1)
  local n = math.floor(w * clamp(value / maximum, 0, 1))
  gpu.setBackground(bg or 0x1C2A35)
  gpu.fill(x, y, w, 1, " ")
  if n > 0 then
    gpu.setBackground(fg or C.blue)
    gpu.fill(x, y, n, 1, " ")
  end
end

local function button(x, y, w, label, active)
  fill(x, y, w, 2, active and C.header or 0x0B151E, active and C.cyan or C.muted)
  local p = math.max(1, math.floor((w - unicode.len(label)) / 2))
  gpu.set(x + p, y, label)
end

local function discover()
  components = {}
  for address, ctype in component.list() do
    local p = component.proxy(address)
    local methods = {}
    local ok, list = pcall(component.methods, address)
    if ok and type(list) == "table" then
      for name in pairs(list) do methods[name] = true end
    else
      for _, name in ipairs({"getOmega","getTorque","getPower","getTemperature","getFuel","getFuelLevel","getFuelAmount","setECU","getECU","getSlot","getTankInfo"}) do
        if type(p[name]) == "function" then methods[name] = true end
      end
    end

    local rotaryScore = 0
    for _, name in ipairs({"getOmega","getTorque","getPower","setECU","getECU","getTemperature","getFuel","getFuelLevel","getFuelAmount"}) do
      if methods[name] then rotaryScore = rotaryScore + 1 end
    end

    components[#components + 1] = {
      address = address,
      type = ctype,
      proxy = p,
      methods = methods,
      rotary = rotaryScore > 0,
      score = rotaryScore
    }
  end
  table.sort(components, function(a, b)
    if a.rotary ~= b.rotary then return a.rotary end
    return a.type < b.type
  end)
  if selected > #components then selected = math.max(1, #components) end
end

local function selectedComponent()
  return components[selected]
end

local function firstValue(p, names)
  for _, name in ipairs(names) do
    local v = safe(p, name)
    if num(v) ~= nil then return num(v), name end
  end
  return nil, nil
end

local function readData(c)
  if not c then return {} end
  local p = c.proxy
  local omega, omegaMethod = firstValue(p, {"getOmega","getSpeed","getRPM","getRpm"})
  local torque, torqueMethod = firstValue(p, {"getTorque"})
  local power, powerMethod = firstValue(p, {"getPower"})
  local temp, tempMethod = firstValue(p, {"getTemperature","getTemp"})
  local ecu, ecuMethod = firstValue(p, {"getECU","getECUPower"})
  local fuel, fuelMethod = firstValue(p, {"getFuel","getFuelLevel","getFuelAmount"})

  if not power and omega and torque then
    power = omega * torque
    powerMethod = "omega × torque"
  end

  local active = safe(p, "isActive")
  if active == nil then active = safe(p, "isRunning") end

  return {
    omega = omega,
    omegaMethod = omegaMethod,
    torque = torque,
    torqueMethod = torqueMethod,
    power = power,
    powerMethod = powerMethod,
    temp = temp,
    tempMethod = tempMethod,
    ecu = ecu,
    ecuMethod = ecuMethod,
    fuel = fuel,
    fuelMethod = fuelMethod,
    active = active,
  }
end

local function statusColor(data)
  if data.active == true then return C.green end
  if data.active == false then return C.red end
  return C.yellow
end

local function drawHeader()
  fill(1, 1, W, 4, C.header, C.white)
  text(3, 2, "ROTARYCRAFT  //  INDUSTRIAL CONTROL CENTER", C.white)
  text(3, 3, "OpenComputers 1.8.10  •  Minecraft 1.7.10  •  RotaryCraft V33a", C.cyan)
  text(W - 25, 2, autoRefresh and "● LIVE" or "○ PAUSE", autoRefresh and C.green or C.yellow)
end

local function drawMetric(x, y, w, title, value, unit, color, ratio, maxValue)
  panel(x, y, w, 5, title)
  text(x + 2, y + 3, value, color)
  text(x + w - unicode.len(unit) - 2, y + 3, unit, C.muted)
  if ratio then bar(x + 2, y + 4, w - 4, ratio, maxValue or 1, color, 0x17232D) end
end

local function drawOverview(data)
  local c = selectedComponent()
  panel(2, 6, 36, 10, "DEVICE")
  text(4, 8, "Type", C.muted)
  text(13, 8, c and c.type or "Keine Komponente", C.white)
  text(4, 10, "Address", C.muted)
  text(13, 10, c and c.address:sub(1, 22) or "-", C.blue)
  text(4, 12, "Rotary score", C.muted)
  text(18, 12, c and tostring(c.score) or "0", c and c.rotary and C.green or C.yellow)
  text(4, 14, "Methods", C.muted)
  text(13, 14, c and tostring((function() local n=0; for _ in pairs(c.methods) do n=n+1 end; return n end)()) or "0", C.white)

  drawMetric(40, 6, 24, "DREHZAHL / OMEGA", compact(data.omega), "rad/s", C.cyan, data.omega, math.max(data.omega or 1, 1) * 1.25)
  drawMetric(66, 6, 24, "DREHMOMENT", compact(data.torque), "Nm", C.orange, data.torque, math.max(data.torque or 1, 1) * 1.25)
  drawMetric(92, 6, 26, "LEISTUNG", compact(data.power), "W", C.green, data.power, math.max(data.power or 1, 1) * 1.25)

  panel(2, 18, 58, 9, "ROTARY POWER")
  text(5, 20, "Drehzahl", C.muted)
  text(20, 20, fmt(data.omega, 2), C.cyan)
  text(35, 20, data.omegaMethod or "keine API", C.muted)
  bar(5, 21, 48, data.omega or 0, math.max(data.omega or 1, 1) * 1.25, C.cyan)

  text(5, 23, "Drehmoment", C.muted)
  text(20, 23, fmt(data.torque, 2), C.orange)
  text(35, 23, data.torqueMethod or "keine API", C.muted)
  bar(5, 24, 48, data.torque or 0, math.max(data.torque or 1, 1) * 1.25, C.orange)

  panel(62, 18, 56, 9, "MACHINE STATE")
  text(65, 20, "Status", C.muted)
  local st = data.active == true and "AKTIV" or data.active == false and "STOP" or "UNBEKANNT"
  text(78, 20, "● " .. st, statusColor(data))
  text(65, 22, "Temperatur", C.muted)
  text(78, 22, fmt(data.temp, 1), data.temp and (data.temp > 800 and C.red or data.temp > 500 and C.orange or C.green) or C.yellow)
  text(92, 22, "°C", C.muted)
  text(65, 24, "ECU", C.muted)
  text(78, 24, fmt(data.ecu, 1), C.purple)
  text(92, 24, data.ecuMethod or "nicht verfügbar", C.muted)
  text(65, 26, "Fuel", C.muted)
  text(78, 26, compact(data.fuel), C.yellow)
  text(92, 26, data.fuelMethod or "nicht verfügbar", C.muted)
end

local function drawComponents()
  panel(2, 6, 116, 28, "COMPONENT SCANNER")
  text(4, 8, "#", C.muted)
  text(8, 8, "TYPE", C.muted)
  text(34, 8, "ROTARY", C.muted)
  text(46, 8, "SCORE", C.muted)
  text(58, 8, "ADDRESS", C.muted)
  hline(4, 9, 112, C.line)
  for i, c in ipairs(components) do
    if i <= 24 then
      local y = 9 + i
      local active = i == selected
      if active then fill(3, y, 114, 1, C.panel2, C.white) end
      text(4, y, tostring(i), active and C.cyan or C.muted)
      text(8, y, c.type:sub(1, 24), c.rotary and C.green or C.white)
      text(34, y, c.rotary and "YES" or "NO", c.rotary and C.green or C.muted)
      text(46, y, tostring(c.score), c.score > 0 and C.orange or C.muted)
      text(58, y, c.address:sub(1, 36), C.blue)
    end
  end
  text(4, 32, "↑/↓ Auswahl   ENTER Details   R Scan   A Auto-Refresh   Q Beenden", C.muted)
end

local function drawMethods()
  local c = selectedComponent()
  panel(2, 6, 116, 28, "AVAILABLE METHODS")
  if not c then
    text(5, 9, "Keine Komponente erkannt.", C.red)
    return
  end
  text(5, 8, c.type .. "  @  " .. c.address, C.cyan)
  local list = {}
  for name in pairs(c.methods) do list[#list + 1] = name end
  table.sort(list)
  local y, col = 10, 0
  for _, name in ipairs(list) do
    local x = 5 + col * 38
    local available = c.methods[name]
    text(x, y, "● " .. name, available and C.green or C.muted)
    y = y + 1
    if y > 31 then
      y = 10
      col = col + 1
      if col > 2 then break end
    end
  end
  text(5, 33, "Nur tatsächlich vom verbundenen Component gemeldete Methoden werden angezeigt.", C.muted)
end

local function draw()
  if not gpu then return end
  clear()
  drawHeader()
  if page == 1 then
    local data = readData(selectedComponent())
    drawOverview(data)
  elseif page == 2 then
    drawComponents()
  else
    drawMethods()
  end

  fill(2, 36, 116, 3, 0x0B151E, C.muted)
  text(4, 37, "[1] Dashboard", page == 1 and C.cyan or C.muted)
  text(22, 37, "[2] Components", page == 2 and C.cyan or C.muted)
  text(43, 37, "[3] Methods", page == 3 and C.cyan or C.muted)
  text(65, 37, "[R] Scan", C.white)
  text(79, 37, "[A] Auto", autoRefresh and C.green or C.yellow)
  text(93, 37, "[Q] Quit", C.white)
  text(4, 39, message, C.muted)
end

local function scan()
  discover()
  lastUpdate = computer.uptime()
  message = string.format("Scan abgeschlossen: %d Komponenten gefunden", #components)
  draw()
end

local function keyAction(code)
  if code == string.byte("q") or code == string.byte("Q") then
    running = false
  elseif code == string.byte("r") or code == string.byte("R") then
    scan()
  elseif code == string.byte("a") or code == string.byte("A") then
    autoRefresh = not autoRefresh
    message = autoRefresh and "Live-Aktualisierung aktiviert" or "Live-Aktualisierung pausiert"
    draw()
  elseif code == string.byte("1") then
    page = 1; draw()
  elseif code == string.byte("2") then
    page = 2; draw()
  elseif code == string.byte("3") then
    page = 3; draw()
  elseif code == 200 then
    selected = math.max(1, selected - 1); draw()
  elseif code == 208 then
    selected = math.min(math.max(1, #components), selected + 1); draw()
  elseif code == 28 then
    page = 1; message = "Komponente " .. tostring(selected) .. " ausgewählt"; draw()
  end
end

if gpu and screen then
  pcall(gpu.bind, gpu, screen.address)
end
if gpu then pcall(gpu.setResolution, gpu, W, H) end

scan()

while running do
  local ev, a, b = event.pull(0.25)
  if ev == "key_down" then
    keyAction(b)
  elseif ev == "touch" then
    local x, y = b, a
    if y >= 36 and y <= 39 then
      if x < 20 then page = 1
      elseif x < 40 then page = 2
      elseif x < 62 then page = 3
      elseif x < 78 then scan()
      elseif x < 92 then autoRefresh = not autoRefresh
      else running = false end
      draw()
    elseif page == 2 and y >= 10 and y <= 33 then
      local row = y - 9
      if row >= 1 and row <= #components then
        selected = row
        page = 1
        message = "Komponente ausgewählt"
        draw()
      end
    end
  end

  if autoRefresh and computer.uptime() - lastUpdate >= 0.5 then
    lastUpdate = computer.uptime()
    if page == 1 then draw() end
  end
end

if gpu then
  gpu.setBackground(0x000000)
  gpu.setForeground(C.white)
  gpu.fill(1, 1, W, H, " ")
  gpu.set(2, 2, "RotaryCraft Dashboard beendet.")
end
