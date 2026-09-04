# BULDACITY v9 – komplette Schritt-für-Schritt-Anleitung

Diese Anleitung beschreibt den aktuellen Stand von `xDarkixx/lua2` für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- die jeweils benötigten Mod-Versionen
- für Netzwerk: Network Card oder Wireless Network Card
- für maximale Grafik: Tier-3 GPU + Screen

## 2. Zentrale bauen

```text
Tier-3 Computer
├── CPU
├── RAM
├── Speicher
├── Tier-3 GPU
├── Screen
├── Keyboard
└── Network/Wireless Network Card
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

## 3. Grafische Schicht

`BuldacityUI.lua` ist die gemeinsame GPU-Schicht.

Sie stellt unter anderem bereit:

```text
Panels          Karten
Buttons         Touch-Flächen
Balken          große Balken
Vertikalbalken  LEDs
Gauges          Status-Badges
Sparklines      Live-Charts
Pixel-Icons     Dashboard-Karten
```

Die Oberfläche passt sich an die verfügbare Screen-Auflösung an.

## 4. Controller-PC bauen

Für jeden Mod einen eigenen OpenComputers-PC verwenden:

```text
Controller-PC
├── CPU
├── RAM
├── Speicher
├── GPU + Screen
└── Network Card/Wireless Network Card
```

Nach `/home` kopieren:

```text
Network.lua
BuldacityUI.lua
BuldacityComponentAgent.lua
passender *Network_Modern.lua
passender *_Modern.lua
```

## 5. Mod-Komponente anschließen

Direkte OC-Komponente:

```text
Computer → Mod-Komponente
```

Adapter:

```text
Computer → OC-Kabel → Adapter → Mod-Block
```

Danach Komponenten prüfen:

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

## 6. Lokale Mod-GUI testen

Vor dem Netzwerk immer lokal testen:

1. Mod-Komponente anschließen.
2. passenden `_Modern.lua` Controller starten.
3. `SCAN` ausführen, falls vorhanden.
4. Werte prüfen.
5. Buttons/Touch testen.
6. erst danach den Network-Wrapper starten.

## 7. Network-Controller starten

Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Client:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

Netzwerkparameter:

```text
BULDACITY/2
Port 4242
```

## 8. Client auf der Zentrale finden

Auf der Zentrale:

```text
DESKTOP → SCAN
```

Danach:

```text
DEVICES
```

Der Client sollte dort mit Icon, Status, Link-Typ, Entfernung und Component-Anzahl auftauchen.

## 9. Component Explorer

Der Component Agent meldet die angeschlossenen OpenComputers-Components an den Server.

Zentrale:

```lua
dofile("/home/BuldacityComponentDashboard.lua")
```

Dort können Component-Typ und Adresse betrachtet werden.

## 10. Remote-PC

1. Client unter `DEVICES` auswählen.
2. `REMOTE` öffnen.
3. `REQUEST SCREEN` ausführen.
4. warten, bis das Bild übertragen wurde.
5. Remote-Eingabe testen.

Der Client benötigt dafür GPU + Screen.

## 11. Big Reactors

```text
ReactorBigReactors043A_Network.lua
ReactorBigReactors043A_Touch_Responsive.lua
```

Das Dashboard kann gemeldete Werte grafisch darstellen:

```text
POWER       ███████████████░░
TEMPERATURE ███████████░░░░░
FUEL        █████████████░░░
```

Zusätzlich gibt es eine Live-Kurve für gemeldete Power-Werte.

## 12. Diesel Generator

```text
DieselGeneratorNetwork_Modern.lua
DieselGenerator_Modern.lua
```

Die GUI besitzt grafischen Tankfüllstand, Generatorstatus, AUTO/MANUAL und Component-Adresse.

## 13. AE2

```text
AE2NetworkEndpoint_Modern.lua
AE2Network_Modern.lua
```

Die grafische AE2-Oberfläche enthält Storage-, Crafting-, Job-, CPU- und P2P-Ansichten.

## 14. Weitere Mod-Familien

Nach demselben Schema werden die vorhandenen Controller für unter anderem diese Mods verwendet:

```text
3D Printer
Applied Energistics 2
Big Reactors
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

Die gemeinsamen BULDACITY-Grafikfunktionen stehen allen Controllern zur Verfügung.

## 15. Wireless

Prüfen:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

Topologie:

```text
ZENTRALE ))) ((( CLIENT
```

oder:

```text
ZENTRALE ── Kabel ── RELAY ))) ((( CLIENT
```

Bei Wireless muss die Wireless-Hardware korrekt vorhanden und aktiviert sein.

## 16. Netzwerkdiagnose

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

Prüft unter anderem:

```text
HELLO
HEARTBEAT
PING
PONG
Entfernung
Wireless/Wired
Relay/Access Point
Latenz
```

## 17. Autostart

Zentrale:

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
/home/buldacity-role.cfg
```

Konfiguration:

```text
ROLE=SERVER
```

Client:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

## 18. Dateiablage

Grundsätzlich alles unter `/home`:

```text
/home/
├── Network.lua
├── BuldacityUI.lua
├── BuldacityOS_Tier3.lua
├── BuldacityDesktop.lua
├── BuldacityComponentServer.lua
├── BuldacityComponentAgent.lua
├── BuldacityComponentDashboard.lua
├── BuldacityAutoStart.lua
├── BuldacityNetworkTest.lua
├── BuldacityWirelessCheck_Modern.lua
└── <Mod-Dateien>
```

## 19. Fehlerbehebung

### `Network` fehlt

```text
/home/Network.lua
```

Dann:

```lua
local shell=require("shell")
shell.setWorkingDirectory("/home")
local Network=require("Network")
print(Network.PROTOCOL)
```

### `BuldacityUI` fehlt

```text
/home/BuldacityUI.lua
```

Test:

```lua
local UI=require("BuldacityUI")
print(UI.W,UI.H)
```

### Client fehlt

Prüfen:

```text
Network Card
Network.lua
BuldacityComponentAgent.lua
Network-Wrapper
Port 4242
Wireless-Signal
Relay/Access Point
```

Dann auf der Zentrale `SCAN`.

### Remote leer

Prüfen:

```text
Client läuft
GPU vorhanden
Screen vorhanden
Network-Wrapper läuft
Client erscheint in DEVICES
REQUEST SCREEN ausführen
```

## 20. Kompletter Ablauf

```text
Minecraft 1.7.10
 ↓
Forge
 ↓
OpenComputers
 ↓
Tier-3 Zentrale
 ↓
/home/BuldacityUI.lua
 ↓
/home/Network.lua
 ↓
BULDACITY v9
 ↓
Component Server
 ↓
Client-PC
 ↓
Component Agent
 ↓
Mod Controller
 ↓
Network Wrapper
 ↓
BULDACITY/2 : 4242
 ↓
DEVICES
 ↓
PING/PONG
 ↓
COMPONENTS
 ↓
REMOTE
 ↓
Mod-Dashboard
 ↓
Autostart
```

## 21. Abschlusscheck

- [ ] Zentrale startet
- [ ] GPU-GUI sichtbar
- [ ] BuldacityUI geladen
- [ ] Component Server läuft
- [ ] Client startet
- [ ] Mod-Komponente erkannt
- [ ] Client erscheint in DEVICES
- [ ] Component IDs sichtbar
- [ ] Netzwerk PASS
- [ ] Remote-Screen sichtbar
- [ ] Remote-Eingabe funktioniert
- [ ] Mod-Dashboard funktioniert
- [ ] Autostart funktioniert

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
