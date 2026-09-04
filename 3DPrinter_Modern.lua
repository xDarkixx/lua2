-- BULDACITY 3D PRINTER CONTROLLER
-- OpenComputers 1.7.10 / printer3d
-- Standalone: no network client required.

local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local unicode = require("unicode")

if not component.isAvailable("printer3d") then
  term.clear()
  print("BULDACITY 3D PRINTER")
  print("")
  print("FEHLER: Kein printer3d gefunden.")
  print("Schliesse einen OpenComputers 3D Printer an.")
  return
end

local printer = component.printer3d
local gpu = component.isAvailable("gpu") and component.gpu or nil

local W, H = 80, 25
if gpu then
  local ok, w, h = pcall(gpu.getResolution)
  if ok and w and h then W, H = w, h end
end

local state = {page="HOME", running=true, message="Bereit", count=1}
local shapes = {}

local function safe(fn, ...)
  local ok, a,b,c,d = pcall(fn, ...)
  if ok then return true,a,b,c,d end
  return false,a
end

local function clear()
  if gpu then gpu.setBackground(0x050812); gpu.setForeground(0xD8F6FF); gpu.fill(1,1,W,H," ") end
  term.clear()
end

local function writeAt(x,y,text)
  text = tostring(text or "")
  if gpu then gpu.set(x,y,text) else term.setCursor(x,y); io.write(text) end
end

local function bar(x,y,w,value,max)
  value = tonumber(value) or 0
  max = tonumber(max) or 1
  if max <= 0 then max = 1 end
  local n = math.floor(math.max(0, math.min(w, value/max*w)))
  writeAt(x,y,"[" .. string.rep("#",n) .. string.rep("-",w-n) .. "]")
end

local function header(title)
  clear()
  writeAt(2,1,"BULDACITY // 3D PRINTER")
  writeAt(math.max(2,W-#title-3),1,"["..title.."]")
  writeAt(2,2,string.rep("=",math.max(1,W-3)))
end

local function status()
  local ok,s,p = safe(printer.status)
  if not ok then return "ERROR",0,false end
  return tostring(s), tonumber(p) or 0, p
end

local function redrawHome()
  header("HOME")
  local s,p,ready = status()
  writeAt(3,4,"STATUS      : "..s)
  if s == "busy" or s == "buzy" then
    writeAt(3,5,"FORTSCHRITT : "); bar(18,5,30,p,100); writeAt(51,5,string.format("%3d%%",p))
  else
    writeAt(3,5,"MODELL       : "..(ready and "DRUCKBEREIT" or "NICHT BEREIT"))
  end
  local ok,label = safe(printer.getLabel)
  writeAt(3,7,"LABEL        : "..(ok and tostring(label or "") or "?"))
  local ok2,tip = safe(printer.getTooltip)
  writeAt(3,8,"TOOLTIP      : "..(ok2 and tostring(tip or "") or "?"))
  local ok3,sc = safe(printer.getShapeCount)
  local ok4,sm = safe(printer.getMaxShapeCount)
  writeAt(3,9,"SHAPES       : "..(ok3 and tostring(sc) or "?").." / "..(ok4 and tostring(sm) or "?"))
  writeAt(3,11,"[1] MODEL    [2] SETTINGS    [3] PRINT    [4] RESET")
  writeAt(3,13,"Vorlagen: [5] CUBE  [6] PILLAR  [7] PANEL  [8] BUTTON")
  writeAt(3,15,"[Q] Beenden")
  writeAt(3,H-2,"INFO: "..state.message)
end

local function showModel()
  header("MODEL")
  local ok,sc = safe(printer.getShapeCount)
  local ok2,sm = safe(printer.getMaxShapeCount)
  writeAt(3,4,"SHAPES: "..(ok and sc or "?").." / "..(ok2 and sm or "?"))
  writeAt(3,6,"[1] CUBE-VORLAGE")
  writeAt(3,7,"[2] PILLAR-VORLAGE")
  writeAt(3,8,"[3] PANEL-VORLAGE")
  writeAt(3,9,"[4] BUTTON-VORLAGE")
  writeAt(3,11,"[A] EIGENE BOX HINZUFUEGEN")
  writeAt(3,12,"[C] MODELL LEEREN")
  writeAt(3,14,"[B] ZURUECK")
  writeAt(3,H-2,"INFO: "..state.message)
end

local function showSettings()
  header("SETTINGS")
  local ok,ll = safe(printer.getLightLevel)
  local ok2,re = safe(printer.isRedstoneEmitter)
  local ok3,bm = safe(printer.isButtonMode)
  local ok4,c1,c2 = safe(printer.isCollidable)
  writeAt(3,4,"LIGHT LEVEL     : "..(ok and tostring(ll) or "?"))
  writeAt(3,5,"REDSTONE        : "..(ok2 and tostring(re) or "?"))
  writeAt(3,6,"BUTTON MODE     : "..(ok3 and tostring(bm) or "?"))
  writeAt(3,7,"COLLISION OFF   : "..(ok4 and tostring(c1) or "?"))
  writeAt(3,8,"COLLISION ON    : "..(ok4 and tostring(c2) or "?"))
  writeAt(3,10,"[1] Licht 0     [2] Licht 8     [3] Licht 16")
  writeAt(3,11,"[4] Redstone AN [5] Redstone AUS")
  writeAt(3,12,"[6] Button AN   [7] Button AUS")
  writeAt(3,13,"[8] Solid       [9] Ghost/Illusion")
  writeAt(3,15,"[L] Label setzen    [T] Tooltip setzen")
  writeAt(3,17,"[B] Zurueck")
  writeAt(3,H-2,"INFO: "..state.message)
end

local function showPrint()
  header("PRINT")
  local s,p,ready = status()
  writeAt(3,4,"STATUS: "..s)
  if s == "busy" or s == "buzy" then
    writeAt(3,5,"PROGRESS: "); bar(13,5,40,p,100); writeAt(56,5,string.format("%3d%%",p))
  else
    writeAt(3,5,"READY: "..tostring(ready))
  end
  writeAt(3,7,"ANZAHL KOPIEN: "..state.count)
  writeAt(3,9,"[1] 1 Kopie")
  writeAt(3,10,"[2] 5 Kopien")
  writeAt(3,11,"[3] 10 Kopien")
  writeAt(3,12,"[4] Eigene Anzahl")
  writeAt(3,14,"[P] DRUCK STARTEN")
  writeAt(3,16,"[B] Zurueck")
  writeAt(3,H-2,"INFO: "..state.message)
end

local function redraw()
  if state.page == "HOME" then redrawHome()
  elseif state.page == "MODEL" then showModel()
  elseif state.page == "SETTINGS" then showSettings()
  elseif state.page == "PRINT" then showPrint() end
end

local function ask(prompt, default)
  if gpu then
    writeAt(3,H-3,string.rep(" ",math.max(1,W-5)))
    writeAt(3,H-3,prompt)
  else term.setCursor(1,H-3); io.write(prompt) end
  local v = io.read()
  if v == nil or v == "" then return default end
  return v
end

local function resetModel()
  local ok,err = safe(printer.reset)
  shapes = {}
  state.message = ok and "Drucker/Modell zurueckgesetzt" or ("Reset Fehler: "..tostring(err))
end

local function addShape(x1,y1,z1,x2,y2,z2,texture,stateOn,tint)
  local ok,err = safe(printer.addShape,x1,y1,z1,x2,y2,z2,texture,stateOn or false,tint)
  if ok then
    table.insert(shapes,{x1,y1,z1,x2,y2,z2,texture,stateOn or false,tint})
    state.message = "Shape hinzugefuegt: "..texture
  else state.message = "Shape Fehler: "..tostring(err) end
end

local function template(kind)
  resetModel()
  safe(printer.setLabel,"Buldacity "..kind)
  safe(printer.setTooltip,"Buldacity 3D Printer - "..kind)
  if kind == "CUBE" then
    addShape(1,1,1,15,15,15,"stone")
  elseif kind == "PILLAR" then
    addShape(5,0,5,11,16,11,"iron_block")
    addShape(3,2,3,13,5,13,"iron_block")
    addShape(3,11,3,13,14,13,"iron_block")
  elseif kind == "PANEL" then
    addShape(0,0,1,16,16,3,"iron_block")
    addShape(2,2,3,5,5,4,"glass")
    addShape(7,2,3,9,5,4,"glowstone")
    addShape(11,2,3,14,5,4,"redstone_block")
  elseif kind == "BUTTON" then
    addShape(3,4,3,13,12,13,"iron_block")
    addShape(6,6,0,10,10,3,"stone_button")
    addShape(6,6,13,10,10,16,"stone_button",true)
    safe(printer.setRedstoneEmitter,true)
    safe(printer.setButtonMode,true)
  end
  state.page="MODEL"
end

local function customBox()
  local x1=tonumber(ask("minX 0-16: ",1)) or 1
  local y1=tonumber(ask("minY 0-16: ",1)) or 1
  local z1=tonumber(ask("minZ 0-16: ",1)) or 1
  local x2=tonumber(ask("maxX 0-16: ",15)) or 15
  local y2=tonumber(ask("maxY 0-16: ",15)) or 15
  local z2=tonumber(ask("maxZ 0-16: ",15)) or 15
  local texture=ask("Textur (z.B. stone): ","stone")
  x1=math.max(0,math.min(16,x1)); y1=math.max(0,math.min(16,y1)); z1=math.max(0,math.min(16,z1))
  x2=math.max(0,math.min(16,x2)); y2=math.max(0,math.min(16,y2)); z2=math.max(0,math.min(16,z2))
  if x2 <= x1 or y2 <= y1 or z2 <= z1 then
    state.message="Ungueltige Box: max muss groesser als min sein"
  else
    addShape(x1,y1,z1,x2,y2,z2,texture)
  end
end

local function setLabel()
  local v=ask("Label: ","Buldacity 3D Print")
  local ok,err=safe(printer.setLabel,v)
  state.message=ok and "Label gesetzt" or tostring(err)
end

local function setTooltip()
  local v=ask("Tooltip: ","Buldacity 3D Printer")
  local ok,err=safe(printer.setTooltip,v)
  state.message=ok and "Tooltip gesetzt" or tostring(err)
end

local function handleKey(ch)
  if state.page=="HOME" then
    if ch=="1" then state.page="MODEL"
    elseif ch=="2" then state.page="SETTINGS"
    elseif ch=="3" then state.page="PRINT"
    elseif ch=="4" then resetModel()
    elseif ch=="5" then template("CUBE")
    elseif ch=="6" then template("PILLAR")
    elseif ch=="7" then template("PANEL")
    elseif ch=="8" then template("BUTTON")
    elseif ch=="q" then state.running=false end
  elseif state.page=="MODEL" then
    if ch=="1" then template("CUBE")
    elseif ch=="2" then template("PILLAR")
    elseif ch=="3" then template("PANEL")
    elseif ch=="4" then template("BUTTON")
    elseif ch=="a" then customBox()
    elseif ch=="c" then resetModel()
    elseif ch=="b" then state.page="HOME" end
  elseif state.page=="SETTINGS" then
    if ch=="1" then safe(printer.setLightLevel,0); state.message="Licht 0"
    elseif ch=="2" then safe(printer.setLightLevel,8); state.message="Licht 8"
    elseif ch=="3" then safe(printer.setLightLevel,16); state.message="Licht 16"
    elseif ch=="4" then safe(printer.setRedstoneEmitter,true); state.message="Redstone AN"
    elseif ch=="5" then safe(printer.setRedstoneEmitter,false); state.message="Redstone AUS"
    elseif ch=="6" then safe(printer.setButtonMode,true); state.message="Button Mode AN"
    elseif ch=="7" then safe(printer.setButtonMode,false); state.message="Button Mode AUS"
    elseif ch=="8" then safe(printer.setCollidable,true,true); state.message="Solid"
    elseif ch=="9" then safe(printer.setCollidable,false,false); state.message="Ghost/Illusion"
    elseif ch=="l" then setLabel()
    elseif ch=="t" then setTooltip()
    elseif ch=="b" then state.page="HOME" end
  elseif state.page=="PRINT" then
    if ch=="1" then state.count=1; state.message="1 Kopie"
    elseif ch=="2" then state.count=5; state.message="5 Kopien"
    elseif ch=="3" then state.count=10; state.message="10 Kopien"
    elseif ch=="4" then state.count=math.max(1,tonumber(ask("Anzahl: ",1)) or 1); state.message="Kopien: "..state.count
    elseif ch=="p" then
      local ok,err=safe(printer.commit,state.count)
      state.message=ok and ("Druck gestartet: "..state.count.." Kopie(n)") or ("Druck Fehler: "..tostring(err))
    elseif ch=="b" then state.page="HOME" end
  end
end

local function loop()
  while state.running do
    redraw()
    local e={event.pull(0.25)}
    if e[1]=="key_down" then
      local char=e[3]
      if char and char>=32 and char<=126 then
        handleKey(string.char(char):lower())
      end
    elseif e[1]=="touch" then
      -- Keyboard control remains the primary input. Touch areas mirror the most useful actions.
      local x,y=e[3],e[4]
      if state.page=="HOME" then
        if y>=11 and y<=12 then
          if x<20 then state.page="MODEL" elseif x<38 then state.page="SETTINGS" elseif x<56 then state.page="PRINT" end
        end
      end
    end
  end
end

redraw()
loop()
term.clear()
print("Buldacity 3D Printer beendet.")
