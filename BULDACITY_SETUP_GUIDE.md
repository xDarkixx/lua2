# BULDACITY v10 – komplette Setup-Anleitung

Diese Anleitung beschreibt den aktuellen Stand von `xDarkixx/lua2` für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- benötigte Mod-Versionen
- Network Card/Wireless Network Card für Netzwerkbetrieb
- Tier-3 GPU + Screen für maximale Grafik

## 2. Zentrale

```text
Tier-3 Computer
├── CPU
├── RAM
├── Speicher
├── Tier-3 GPU
├── Screen
├── Keyboard
└── Netzwerkkomponente
```

Nach `/home` kopieren:

```text
Network.lua
BuldacityUI.lua
BuldacityOS_Tier3.lua
BuldacityDesktop.lua
BuldacityComponentServer.lua
BuldacityComponentDashboard.lua
BuldacityAutoStart.lua
BuldacityNetworkTest.lua
BuldacityWirelessCheck_Modern.lua
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 3. Grafik

`BuldacityUI.lua` ist die gemeinsame GPU-Schicht für Desktop und Controller.

Sie stellt Panels, Karten, Buttons, Balken, LEDs, Gauges, Diagramme, Sparklines, Icons und Touch-Zonen bereit.

## 4. Controller-PC

Für jeden Mod einen eigenen OC-PC verwenden:

```text
CPU + RAM + Speicher + Netzwerkkomponente
```

Optional für eine lokale GUI:

```text
GPU + Screen + Keyboard
```

Nach `/home`:

```text
Network.lua
BuldacityUI.lua
BuldacityComponentAgent.lua
<Mod>Network_Modern.lua
<Mod>_Modern.lua
```

## 5. Component prüfen

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

Für BULDACITY-Netzwerk muss mindestens eine `modem`-Komponente vorhanden sein.

## 6. Mod-Komponente

Direkt:

```text
Computer → Mod-Komponente
```

Oder über Adapter/Kabel:

```text
Computer → OC-Kabel → Adapter → Mod-Block
```

Erst lokal prüfen, danach Netzwerk aktivieren.

## 7. Netzwerk

Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Client:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

Parameter:

```text
BULDACITY/2
Port 4242
```

## 8. Netzwerk-Hardware

Die aktuelle `Network.lua` erkennt alle `modem`-Komponenten mit:

```lua
component.list("modem", true)
```

Jedes gefundene Modem wird geprüft und für den Netzwerkbetrieb geöffnet. Wireless-fähige Modems werden über `getStrength/setStrength` erkannt.

## 9. Zentrale SCAN

Auf der Zentrale:

```text
DESKTOP → SCAN
```

Die NETWORK-Seite zeigt:

```text
Server-Modems
Wireless-Modems
Signalstärke
Port 4242
Modem-Adresse
Relay/AP
Scan-Status
```

## 10. Client finden

Danach:

```text
DEVICES
```

Der Client sollte mit Status, Netzwerktyp, Modem-Anzahl und Component-Anzahl auftauchen.

## 11. Component Explorer

```lua
dofile("/home/BuldacityComponentDashboard.lua")
```

Der Component Agent meldet Component-Typen und Adressen an die Zentrale.

## 12. Wireless

Direkt:

```text
ZENTRALE ))) ((( CLIENT
```

oder:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Prüfen:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

## 13. Netzwerkdiagnose

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

Der Netzwerkdienst prüft bzw. protokolliert:

```text
MODEM
MODEM ADDRESS
WIRED/WIRELESS
SIGNAL
PORT 4242
RELAY/AP
HELLO
LINK_ACK
LINK_CONFIRM
PING
PONG
HEARTBEAT
DISTANCE
LATENCY
```

## 14. Remote-PC

1. Client in `DEVICES` auswählen.
2. `REMOTE` öffnen.
3. `REQUEST SCREEN` ausführen.
4. Client benötigt GPU + Screen.

Die Übertragung verwendet Bildschirmzeilen statt einer externen Grafik-Engine.

## 15. Mod-Controller

Das Repo enthält Controller für unter anderem:

```text
3D Printer
Applied Energistics 2
Big Reactors / Extreme Reactors
Diesel Generator
Extra Planets
Forestry
Galacticraft
Gendustry
Immersive Engineering
Immersive Integration
Immersive Railroading
IndustrialCraft 2
Logistics Pipes
Mekanism
PneumaticCraft
ProjectE
RFTools
RotaryCraft
SGCraft
Thermal Expansion
```

## 16. Autostart

Zentrale:

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
/home/buldacity-role.cfg
```

```text
ROLE=SERVER
```

Client:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

## 17. Fehlerbehebung

### Kein Modem

```lua
local component=require("component")
for address,typ in component.list() do print(address,typ) end
```

Wenn kein `modem` auftaucht: Netzwerkhardware prüfen.

### Client nicht sichtbar

```text
1. Client läuft
2. modem vorhanden
3. Network.lua vorhanden
4. ComponentAgent vorhanden
5. Network-Wrapper läuft
6. Port 4242 offen
7. Wireless-Signal > 0
8. Relay/AP prüfen
9. Zentrale SCAN
10. NetworkTest
```

### Wireless nicht erreichbar

```text
Wireless-Hardware vorhanden?
Signalstärke > 0?
Port 4242 geöffnet?
Entfernung innerhalb der Reichweite?
Relay/AP korrekt?
```

### Remote leer

```text
Client online
GPU vorhanden
Screen vorhanden
Network-Wrapper läuft
REQUEST SCREEN ausführen
```

## 18. Logs

Die Component-Diagnose schreibt:

```text
/home/BuldacityComponents.log
```

## 19. Vollständiger Ablauf

```text
Minecraft 1.7.10
 ↓
Forge
 ↓
OpenComputers
 ↓
Tier-3 Zentrale
 ↓
/home/Network.lua
 ↓
/home/BuldacityUI.lua
 ↓
Component Server
 ↓
BULDACITY Desktop
 ↓
SCAN
 ↓
Client Component Agent
 ↓
Mod Controller
 ↓
BULDACITY/2 : 4242
 ↓
PING/PONG
 ↓
DEVICES
 ↓
COMPONENTS
 ↓
REMOTE
 ↓
Mod-Dashboard
 ↓
Autostart
```

## 20. Abschlusscheck

- [ ] Zentrale startet
- [ ] GPU-GUI sichtbar
- [ ] Network.lua geladen
- [ ] mindestens ein Modem erkannt
- [ ] Component Server läuft
- [ ] Client startet
- [ ] Client erscheint in DEVICES
- [ ] Modem-/Wireless-Diagnose sichtbar
- [ ] PING/PONG PASS
- [ ] Component IDs sichtbar
- [ ] Remote-Screen funktioniert
- [ ] Mod-Dashboard funktioniert
- [ ] Autostart funktioniert

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
