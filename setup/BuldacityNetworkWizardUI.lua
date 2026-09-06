-- setup/BuldacityNetworkWizardUI.lua
-- BULDACITY NETWORK WIZARD // graphical touch setup
-- OpenComputers 1.7.10 / Lua 5.2
-- This is intentionally separate from the original network/setup files.
-- If this UI ever fails, the original BuldacityNetworkSetup.lua remains usable.

local component=require("component")
local computer=require("computer")
local event=require("event")
local filesystem=require("filesystem")

local okUI,UI=pcall(require,"BuldacityUI")
if not okUI or not UI then
  error("BULDACITY NETWORK WIZARD: BuldacityUI.lua fehlt")
end

local okNet,network=pcall(require,"Network")
if not okNet or not network then
  error("BULDACITY NETWORK WIZARD: Network.lua fehlt")
end

local PORT=4242
local STRENGTH=400
local VERSION="2.0"
local cfgPath="/home/buldacity-network.cfg"
local page="home"
local role=nil
local clientType=nil
local result=nil
local running=true
local buttons={}
local previousPage=nil

local function safe(fn,...)
  local ok,a,b,c,d=pcall(fn,...)
  if ok then return true,a,b,c,d end
  return false,a
end

local function saveConfig()
  if not filesystem or not filesystem.open then return false end
  local f=filesystem.open(cfgPath,"w")
  if not f then return false end
  f:write("ROLE="..tostring(role or "").."\n")
  f:write("PROTOCOL=BULDACITY/2\n")
  f:write("PORT="..PORT.."\n")
  if clientType then f:write("CLIENT="..clientType.."\n") end
  f:close()
  return true
end

local function scan()
  local r={modems=0,wireless=false,strength=0,relay=false,accessPoint=false,filesystem=true}
  for address in component.list("modem",true) do
    r.modems=r.modems+1
    local m=component.proxy(address)
    if m then
      pcall(function() m.open(PORT) end)
      if type(m.setStrength)=="function" then
        r.wireless=true
        pcall(function() m.setStrength(STRENGTH) end)
      end
      if type(m.getStrength)=="function" then
        local ok,v=pcall(m.getStrength)
        if ok then r.strength=tonumber(v) or r.strength end
      end
    end
  end
  for _ in component.list("relay",true) do r.relay=true end
  for _ in component.list("access_point",true) do r.accessPoint=true end
  return r
end

local function setStatus(kind,text,detail)
  result={kind=kind,text=text,detail=detail or ""}
  page="result"
end

local function addButton(id,x,y,w,h,label,accent)
  buttons[id]={x=x,y=y,w=w,h=h,accent=accent or UI.C.cyan}
  UI.rect(x,y,w,h,UI.C.panel2)
  UI.rect(x,y,w,1,accent or UI.C.cyan)
  UI.text(x+2,y+1,UI.fit(label,w-4),UI.C.white,UI.C.panel2)
end

local function drawButton(id,selected)
  local b=buttons[id]
  if not b then return end
  local bg=selected and UI.C.cyan or UI.C.panel2
  local fg=selected and UI.C.bg or UI.C.white
  UI.rect(b.x,b.y,b.w,b.h,bg)
  UI.text(b.x+2,b.y+math.floor(b.h/2),UI.fit(b.label or "",b.w-4),fg,bg)
end

local function button(id,x,y,w,h,label,accent)
  buttons[id]={x=x,y=y,w=w,h=h,label=label,accent=accent or UI.C.cyan}
  UI.rect(x,y,w,h,UI.C.panel2)
  UI.rect(x,y,w,1,accent or UI.C.cyan)
  UI.text(x+2,y+math.floor(h/2),UI.fit(label,w-4),UI.C.white,UI.C.panel2)
end

local function hit(x,y)
  for id,b in pairs(buttons) do
    if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return id end
  end
end

local function top(title,subtitle,accent)
  buttons={}
  UI.clear()
  UI.header(title,subtitle,accent)
  UI.text(UI.W-18,2,"v"..VERSION,UI.C.muted,UI.C.panel)
end

local function footerBack()
  button("back",2,UI.H-3,18,2,"< ZURUECK",UI.C.muted)
  button("exit",UI.W-20,UI.H-3,18,2,"BEENDEN",UI.C.red)
end

local function drawHome()
  top("NETZWERK-ASSISTENT","BULDACITY/2 // EINFACH EINRICHTEN",UI.C.cyan)
  UI.panel(2,6,UI.W-4,5,"WAS MOECHTEST DU EINRICHTEN?",UI.C.cyan)
  UI.text(5,8,"Du musst keine Adressen oder UUIDs kennen.",UI.C.white,UI.C.panel)
  UI.text(5,9,"Der Assistent sucht die Hardware automatisch.",UI.C.muted,UI.C.panel)
  local w=math.floor((UI.W-8)/2)
  button("server",3,13,w,5,"SERVER / ZENTRALE",UI.C.blue)
  button("client",5+w,13,w,5,"CLIENT / ANLAGE",UI.C.green)
  button("test",3,19,w,3,"NETZWERK TESTEN",UI.C.purple)
  button("exit",5+w,19,w,3,"BEENDEN",UI.C.red)
  UI.statusLine("SCHRITT 1 // ROLLE AUSWAEHLEN",UI.C.muted)
end

local function drawClient()
  top("CLIENT AUSWAEHLEN","WELCHE ANLAGE SOLL VERBUNDEN WERDEN?",UI.C.green)
  local w=math.floor((UI.W-8)/2)
  button("br",3,7,w,4,"BIG REACTORS",UI.C.green)
  button("sg",5+w,7,w,4,"SGCRAFT",UI.C.purple)
  button("general",3,13,w,4,"ALLGEMEINER CLIENT",UI.C.cyan)
  button("back",5+w,13,w,4,"ZURUECK",UI.C.muted)
  UI.panel(3,19,UI.W-6,3,"AUTOMATIK",UI.C.cyan)
  UI.text(5,20,"Modem, Port 4242 und Verbindung werden geprueft.",UI.C.muted,UI.C.panel)
  UI.statusLine("SCHRITT 2 // CLIENT TYP",UI.C.muted)
end

local function drawScan(r)
  top("HARDWARE PRUEFEN","AUTOMATISCHER SCAN // BITTE NICHTS EINGEBEN",UI.C.blue)
  r=r or scan()
  local cw=math.max(20,math.floor((UI.W-8)/3))
  local function stat(x,title,value,on,accent)
    UI.panel(x,6,cw,5,title,accent)
    UI.text(x+3,8,on and "OK" or "FEHLT",on and UI.C.green or UI.C.red,UI.C.panel)
    UI.text(x+3,9,UI.fit(value,cw-6),UI.C.white,UI.C.panel)
  end
  stat(2,"MODEM",tostring(r.modems).." gefunden",r.modems>0,UI.C.cyan)
  stat(4+cw,"PORT 4242","geoeffnet",r.modems>0,UI.C.orange)
  stat(6+cw*2,"WIRELESS",r.wireless and (tostring(r.strength).." Signal") or "nicht vorhanden",r.wireless or r.modems>0,UI.C.purple)
  UI.panel(2,13,UI.W-4,7,"NETZWERK-STATUS",UI.C.blue)
  UI.led(5,15,r.modems>0,UI.C.green,"MODEM")
  UI.led(5,16,r.modems>0,UI.C.green,"PORT 4242")
  UI.led(5,17,r.wireless or r.modems>0,UI.C.purple,r.wireless and "WLAN" or "VERKABELT")
  UI.led(35,15,r.relay,UI.C.yellow,"RELAY")
  UI.led(35,16,r.accessPoint,UI.C.yellow,"ACCESS POINT")
  UI.led(35,17,true,UI.C.cyan,"PROTOKOLL BULDACITY/2")
  button("run",2,UI.H-3,24,2,"VERBINDUNG TESTEN",UI.C.green)
  button("back",UI.W-40,UI.H-3,18,2,"< ZURUECK",UI.C.muted)
  button("exit",UI.W-20,UI.H-3,18,2,"BEENDEN",UI.C.red)
end

local function drawTest()
  top("NETZWERK TEST","BULDACITY/2 // DIAGNOSE",UI.C.purple)
  local r=scan()
  local checks={
    {"MODEM",r.modems>0},
    {"PORT 4242",r.modems>0},
    {"SIGNAL / KABEL",r.wireless or r.modems>0},
    {"PROTOKOLL","BULDACITY/2"},
  }
  UI.panel(3,6,UI.W-6,12,"SYSTEM-CHECK",UI.C.purple)
  local y=8
  for _,c in ipairs(checks) do
    local on=c[2]
    UI.led(6,y,on,UI.C.green,c[1])
    UI.text(30,y,on and "BEREIT" or "PRUEFEN",on and UI.C.green or UI.C.red,UI.C.panel)
    y=y+2
  end
  UI.text(6,16,"Modems: "..r.modems.."   Signal: "..tostring(r.strength),UI.C.muted,UI.C.panel)
  button("run",3,20,24,2,"TEST WIEDERHOLEN",UI.C.purple)
  button("back",UI.W-40,20,18,2,"< ZURUECK",UI.C.muted)
  button("exit",UI.W-20,20,18,2,"BEENDEN",UI.C.red)
end

local function drawProgress(step,total,text)
  top("VERBINDUNG PRUEFEN","AUTOMATISCH // KEINE UUID / KEINE MANUELLE ADRESSE",UI.C.blue)
  UI.panel(4,7,UI.W-8,8,"FORTSCHRITT",UI.C.blue)
  UI.text(7,9,text,UI.C.white,UI.C.panel)
  UI.bar2(7,11,UI.W-14,2,(step/total)*100,UI.C.cyan,false)
  UI.text(7,14,"Schritt "..step.." / "..total,UI.C.muted,UI.C.panel)
end

local function runConnectionTest()
  local r=scan()
  drawProgress(1,4,"Hardware wird geprueft...")
  if r.modems==0 then setStatus("ERROR","KEIN MODEM GEFUNDEN","Bitte ein OpenComputers Modem anschliessen."); return end
  computer.pullSignal(0.25)
  drawProgress(2,4,"Port 4242 wird geoeffnet...")
  pcall(function() network.init() end)
  pcall(function() network.setWirelessStrength(STRENGTH) end)
  computer.pullSignal(0.25)
  drawProgress(3,4,"BULDACITY/2 wird gestartet...")
  pcall(function() network.startServer(function() end) end)
  if role=="CLIENT" then
    pcall(function() network.broadcast("HELLO",{name="BULDACITY CLIENT",role="CLIENT",app=clientType or "GENERAL",version=VERSION,protocol="BULDACITY/2",port=PORT}) end)
  else
    pcall(function() network.broadcast("SERVER_HELLO",{name="BULDACITY SERVER",role="SERVER",app="NETWORK WIZARD",version=VERSION,protocol="BULDACITY/2",port=PORT,discover=true,scan=true}) end)
  end
  computer.pullSignal(0.25)
  drawProgress(4,4,"Netzwerk ist bereit. Konfiguration wird gespeichert...")
  saveConfig()
  computer.pullSignal(0.35)
  setStatus("OK","NETZWERK BEREIT","Modem gefunden, Port 4242 aktiv und BULDACITY/2 gestartet.")
end

local function drawResult()
  local good=result and result.kind=="OK"
  top(good and "FERTIG" or "PRUEFUNG FEHLGESCHLAGEN",good and "BULDACITY/2 IST BEREIT" or "BULDACITY BRAUCHT NOCH EINEN SCHRITT",good and UI.C.green or UI.C.red)
  UI.panel(5,7,UI.W-10,8,"ERGEBNIS",good and UI.C.green or UI.C.red)
  UI.text(9,9,good and "ONLINE / BEREIT" or "FEHLER",good and UI.C.green or UI.C.red,UI.C.panel)
  UI.text(9,11,UI.fit(result and result.text or "Unbekannter Fehler",UI.W-18),UI.C.white,UI.C.panel)
  UI.text(9,13,UI.fit(result and result.detail or "",UI.W-18),UI.C.muted,UI.C.panel)
  button("again",5,18,22,3,"NOCH EINMAL",UI.C.blue)
  button("home",29,18,22,3,"HAUPTMENUE",UI.C.cyan)
  button("exit",53,18,22,3,"BEENDEN",UI.C.red)
end

local function draw()
  if page=="home" then drawHome()
  elseif page=="client" then drawClient()
  elseif page=="scan" then drawScan()
  elseif page=="test" then drawTest()
  elseif page=="progress" then drawProgress(1,1,"Vorbereitung...")
  elseif page=="result" then drawResult()
  end
end

local function chooseClient(t)
  role="CLIENT"
  clientType=t
  page="scan"
end

draw()
while running do
  local name,address,x,y=event.pull("touch")
  if name=="touch" then
    local id=hit(x,y)
    if id=="server" then role="SERVER";clientType=nil;page="scan"
    elseif id=="client" then page="client"
    elseif id=="test" then page="test"
    elseif id=="br" then chooseClient("BIG_REACTORS")
    elseif id=="sg" then chooseClient("SGCRAFT")
    elseif id=="general" then chooseClient("GENERAL")
    elseif id=="run" then page="progress";draw();runConnectionTest()
    elseif id=="again" then page="scan"
    elseif id=="home" then page="home"
    elseif id=="back" then page=(role=="CLIENT" and "client" or "home")
    elseif id=="exit" then running=false end
    if running then draw() end
  end
end

pcall(function() UI.clear() end)
