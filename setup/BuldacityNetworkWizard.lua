-- BULDACITY Network Wizard
-- OpenComputers 1.7.10 / Lua 5.2
-- Beginner-friendly network setup and diagnostics.

local component = require("component")
local computer = require("computer")
local event = require("event")

local PROTOCOL = "BULDACITY/2"
local PORT = 4242
local strength = 400

local function clear()
  io.write("\27[2J\27[H")
end

local function line()
  print("------------------------------------------------------------")
end

local function yes(ok)
  return ok and "[ OK ]" or "[ !! ]"
end

local function modems()
  local result = {}
  for address in component.list("modem", true) do
    local m = component.proxy(address)
    if m then result[#result + 1] = m end
  end
  return result
end

local function scan()
  local result = {}
  for _, m in ipairs(modems()) do
    local wireless = type(m.setStrength) == "function" or type(m.getStrength) == "function"
    local signal = 0
    if type(m.getStrength) == "function" then
      pcall(function() signal = tonumber(m.getStrength()) or 0 end)
    end
    local opened = pcall(function() m.open(PORT) end)
    if wireless and type(m.setStrength) == "function" then
      pcall(function() m.setStrength(strength) end)
    end
    result[#result + 1] = {
      address = m.address,
      wireless = wireless,
      signal = signal,
      opened = opened
    }
  end
  return result
end

local function networkStatus()
  local ms = scan()
  local wireless = false
  for _, m in ipairs(ms) do
    if m.wireless then wireless = true end
  end
  return ms, wireless
end

local function saveRole(role, client)
  local fs = component.isAvailable("filesystem") and component.filesystem
  if not fs then return false, "NO_FILESYSTEM" end
  local path = "/home/buldacity-network.cfg"
  local h, err = fs.open(path, "w")
  if not h then return false, tostring(err) end
  fs.write(h, "ROLE=" .. role .. "\n")
  fs.write(h, "PROTOCOL=" .. PROTOCOL .. "\n")
  fs.write(h, "PORT=" .. tostring(PORT) .. "\n")
  if client then fs.write(h, "CLIENT=" .. client .. "\n") end
  fs.close(h)
  return true, path
end

local function waitForNetwork(seconds)
  local deadline = computer.uptime() + seconds
  while computer.uptime() < deadline do
    local signal = {event.pull(1)}
    if signal[1] == "modem_message" and signal[4] == PORT then
      local packet = signal[6]
      if type(packet) == "table" and packet.protocol == PROTOCOL then
        return true, signal[3], packet.kind
      end
    end
  end
  return false
end

local function serverTest()
  local ms, wireless = networkStatus()
  clear()
  print("BULDACITY NETWORK WIZARD – SERVER TEST")
  line()
  print(yes(#ms > 0), " Modem: ", #ms, " gefunden")
  print(yes(#ms > 0), " Port: ", PORT, " wird automatisch geöffnet")
  print(yes(wireless), " Wireless: ", wireless and "JA" or "NEIN")
  print(" Signal-Stärke: ", strength)
  line()
  if #ms == 0 then
    print("FEHLER: Kein OpenComputers-Modem gefunden.")
    print("Baue ein Modem in den Computer ein und starte den Assistenten erneut.")
    return false
  end
  print("Server ist bereit.")
  print("Jetzt kannst du einen Client starten.")
  print("Warte 10 Sekunden auf einen BULDACITY/2 Client ...")
  local ok, sender, kind = waitForNetwork(10)
  if ok then
    print(yes(true), " Client gefunden: ", sender)
    print(" Paket: ", tostring(kind))
  else
    print("[ .. ] Noch kein Client gefunden.")
    print("Das ist kein Hardwarefehler. Starte jetzt den Client.")
  end
  return true
end

local function clientTest(client)
  local ms, wireless = networkStatus()
  clear()
  print("BULDACITY NETWORK WIZARD – CLIENT TEST")
  line()
  print(yes(#ms > 0), " Modem: ", #ms, " gefunden")
  print(yes(#ms > 0), " Port: ", PORT)
  print(yes(wireless), " Wireless: ", wireless and "JA" or "NEIN")
  print(" Client: ", client)
  line()
  if #ms == 0 then
    print("FEHLER: Kein Modem vorhanden.")
    return false
  end
  print("Sende HELLO ...")
  local packet = {protocol=PROTOCOL, kind="HELLO", sender=computer.address(), time=computer.uptime(), data={name=client, role="CLIENT", app=client, port=PORT}}
  local sent = 0
  for _, m in ipairs(modems()) do
    local ok = pcall(function() m.broadcast(PORT, packet) end)
    if ok then sent = sent + 1 end
  end
  print(yes(sent > 0), " HELLO gesendet über ", sent, " Modem(s)")
  print("Warte auf Server ...")
  local ok, sender, kind = waitForNetwork(8)
  if ok then
    print(yes(true), " Server gefunden: ", sender)
    print(" Paket: ", tostring(kind))
  else
    print("[ !! ] Kein Server-Paket erhalten.")
    print("Prüfe, ob die Tier-3-Zentrale läuft und ein Modem besitzt.")
  end
  return true
end

local function chooseClient()
  clear()
  print("BULDACITY NETWORK WIZARD – GERÄT AUSWÄHLEN")
  line()
  print("1) Big Reactors")
  print("2) SGCraft")
  print("3) Allgemeiner BULDACITY Client")
  line()
  io.write("Auswahl [1-3]: ")
  local n = tonumber(io.read()) or 3
  if n == 1 then return "BigReactors" end
  if n == 2 then return "SGCraft" end
  return "BULDACITY CLIENT"
end

local function main()
  clear()
  print("============================================================")
  print("        BULDACITY/2 – NETWORK WIZARD")
  print("============================================================")
  print("Du musst hier nichts über Lua wissen.")
  print("Der Assistent erkennt die vorhandene Netzwerk-Hardware.")
  print("")
  print("1) SERVER / TIER-3 einrichten")
  print("2) CLIENT einrichten")
  print("3) NUR Netzwerk testen")
  print("0) Beenden")
  line()
  io.write("Auswahl: ")
  local choice = io.read()

  if choice == "1" then
    local ok, path = saveRole("SERVER")
    serverTest()
    print("")
    print("Konfiguration: ", ok and path or "nicht gespeichert")
  elseif choice == "2" then
    local client = chooseClient()
    local ok, path = saveRole("CLIENT", client)
    clientTest(client)
    print("")
    print("Konfiguration: ", ok and path or "nicht gespeichert")
  elseif choice == "3" then
    local ms, wireless = networkStatus()
    clear()
    print("BULDACITY/2 – NETZWERKDIAGNOSE")
    line()
    print(yes(#ms > 0), " Modems: ", #ms)
    print(yes(wireless), " Wireless: ", wireless and "JA" or "NEIN")
    print(" Protokoll: ", PROTOCOL)
    print(" Port: ", PORT)
    for i, m in ipairs(ms) do
      print("")
      print("Modem ", i)
      print(" Adresse: ", m.address)
      print(" Port offen: ", m.opened and "JA" or "NEIN")
      print(" Wireless: ", m.wireless and "JA" or "NEIN")
      print(" Stärke: ", m.signal)
    end
  end

  print("")
  io.write("ENTER = zurück / beenden ...")
  io.read()
end

main()
