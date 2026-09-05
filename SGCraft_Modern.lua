-- SGCraft_Modern.lua
-- BULDACITY // STARGATE COMMAND CENTER
-- Minecraft 1.7.10 / SGCraft-1.13.3-mc1.7.10.jar
-- GUI/controller only. Network is handled by SGCraftNetwork_Modern.lua.

local component = require("component")
local event = require("event")
local computer = require("computer")
local UI = require("SGCraftUI")
local gpu = component.gpu

local gates = {}
local selected = 1
local page = "status"
local running = true
local target = ""
local message = ""
local log = {}

local function safe(o, n)
  if o == nil then
    return nil
  end
  if type(o[n]) ~= "function" then
    return nil
  end
  local ok, r1, r2, r3, r4 = pcall(o[n])
  if ok then
    return r1, r2, r3, r4
  end
  return nil
end

local function addLog(s)
  log[#log + 1] = os.date("%H:%M:%S") .. " " .. tostring(s)
  while #log > 8 do
    table.remove(log, 1)
  end
end

local function scan()
  gates = {}
  for address in component.list("stargate", true) do
    gates[#gates + 1] = {
      address = address,
      proxy = component.proxy(address)
    }
  end
  if selected > #gates then
    selected = #gates
  end
  if selected < 1 then
    selected = 1
  end
  addLog("SCAN: " .. tostring(#gates) .. " Stargate Interface(s)")
end

local function selectedGate()
  return gates[selected]
end

local function readGate(g)
  if g == nil then
    return nil
  end

  local state, chevrons, direction = safe(g.proxy, "stargateState")
  local localAddress = safe(g.proxy, "localAddress")
  local remoteAddress = safe(g.proxy, "remoteAddress")
  local energy = safe(g.proxy, "energyAvailable")
  local irisState = safe(g.proxy, "irisState")

  if energy == nil then energy = 0 end
  if irisState == nil then irisState = "Offline" end
  if state == nil then state = "Unknown" end
  if chevrons == nil then chevrons = 0 end
  if direction == nil then direction = "-" end
  if localAddress == nil then localAddress = "-" end
  if remoteAddress == nil then remoteAddress = "-" end

  local maxEnergy = 100000
  local energyNumber = tonumber(energy) or 0
  local energyPct = energyNumber / maxEnergy * 100
  if energyPct < 0 then energyPct = 0 end
  if energyPct > 100 then energyPct = 100 end

  return {
    address = g.address,
    state = state,
    chevrons = tonumber(chevrons) or 0,
    direction = direction,
    localAddress = localAddress,
    remote = remoteAddress,
    energy = energyNumber,
    iris = irisState,
    energyPct = energyPct
  }
end

local function dial()
  local g = selectedGate()
  if g == nil or target == "" then
    addLog("DIAL: gate/target missing")
    return
  end

  local ok = pcall(function()
    g.proxy.dial(target)
  end)

  if ok then
    addLog("DIAL START: " .. target)
  else
    addLog("DIAL ERROR")
  end
end

local function disconnect()
  local g = selectedGate()
  if g == nil then return end

  local ok = pcall(function()
    g.proxy.disconnect()
  end)

  if ok then
    addLog("DISCONNECTED")
  else
    addLog("DISCONNECT ERROR")
  end
end

local function setIris(open)
  local g = selectedGate()
  if g == nil then return end

  local ok
  if open then
    ok = pcall(function()
      g.proxy.openIris()
    end)
  else
    ok = pcall(function()
      g.proxy.closeIris()
    end)
  end

  if ok then
    if open then
      addLog("IRIS OPEN")
    else
      addLog("IRIS CLOSED")
    end
  else
    addLog("IRIS ERROR")
  end
end

local function sendMessage()
  local g = selectedGate()
  if g == nil or message == "" then return end

  local ok = pcall(function()
    g.proxy.sendMessage(message)
  end)

  if ok then
    addLog("MSG SENT: " .. message)
  else
    addLog("MSG ERROR")
  end
end

local function draw()
  local g = selectedGate()
  local gd = readGate(g)

  local data = {
    page = page,
    gates = {},
    selected = selected,
    gate = gd,
    title = "STARGATE COMMAND / " .. string.upper(page),
    target = target,
    message = message,
    log = log,
    energyNeed = nil
  }

  for i = 1, #gates do
    local gate = gates[i]
    local state = safe(gate.proxy, "stargateState")
    if state == nil then state = "Offline" end
    data.gates[i] = {
      address = gate.address,
      state = state
    }
  end

  if page == "dial" then
    if target == "" then
      data.title = "DIALING CONSOLE // TARGET EMPTY"
    else
      data.title = "DIALING CONSOLE // TARGET " .. target
    end
  elseif page == "iris" then
    data.title = "IRIS SECURITY // ACCESS CONTROL"
  elseif page == "link" then
    data.title = "LINK // MESSAGE CHANNEL"
  end

  UI.draw(data)
end

scan()
draw()

local lastDraw = computer.uptime()

while running do
  local ev, _, a, b, key, ch = event.pull(0.2)

  if ev == "key_down" then
    if key == 17 then
      running = false
    elseif key == 2 then
      page = "status"
    elseif key == 3 then
      page = "gates"
    elseif key == 4 then
      page = "dial"
    elseif key == 5 then
      page = "iris"
    elseif key == 6 then
      page = "link"
    elseif key == 31 then
      scan()
    elseif key == 15 and #gates > 0 then
      selected = (selected % #gates) + 1
    elseif key == 32 and page == "dial" then
      dial()
    elseif key == 45 then
      disconnect()
    elseif key == 24 and page == "iris" then
      setIris(true)
    elseif key == 46 and page == "iris" then
      setIris(false)
    elseif key == 50 and page == "link" then
      sendMessage()
    elseif key == 14 then
      if page == "dial" then
        target = target:sub(1, -2)
      elseif page == "link" then
        message = message:sub(1, -2)
      end
    elseif ch and ch >= 32 and ch <= 126 then
      if page == "dial" then
        target = target .. string.char(ch):upper()
      elseif page == "link" then
        message = message .. string.char(ch)
      end
    end
    draw()

  elseif ev == "touch" then
    local x = a
    local y = b
    local handled = false

    for id in pairs(UI.buttons) do
      if UI.hit(id, x, y) then
        handled = true
        if id == "status" or id == "gates" or id == "dial" or id == "iris" or id == "link" then
          page = id
        elseif id == "scan" then
          scan()
        elseif id == "dialNow" then
          dial()
        elseif id == "disconnect" then
          disconnect()
        elseif id == "openIris" then
          setIris(true)
        elseif id == "closeIris" then
          setIris(false)
        elseif id == "sendMessage" then
          sendMessage()
        end
        draw()
        break
      end
    end

    if not handled and page == "gates" and y >= 8 and y <= UI.H - 5 then
      local index = math.floor((y - 8) / 3) + 1
      if gates[index] ~= nil then
        selected = index
        draw()
      end
    end

  elseif ev == "sgStargateStateChange" or ev == "sgChevronEngaged" or ev == "sgIrisStateChange" or ev == "sgDialIn" or ev == "sgDialOut" then
    addLog(ev)
    draw()

  elseif ev == "sgMessageReceived" then
    addLog("REMOTE MSG: " .. tostring(a))
    draw()
  end

  if computer.uptime() - lastDraw > 0.5 then
    lastDraw = computer.uptime()
    draw()
  end
end

gpu.setBackground(0)
gpu.setForeground(UI.C.white)
gpu.fill(1, 1, UI.W, UI.H, " ")
