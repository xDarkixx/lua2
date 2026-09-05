# BULDACITY v10.2 – komplette Setup-Anleitung

Aktueller Stand für Minecraft 1.7.10 + Forge 10.13.4.1614 + OpenComputers.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- Tier-3-System für die Zentrale
- GPU + Screen + Keyboard für die grafische Oberfläche
- mindestens eine echte OpenComputers `modem`-Komponente für Netzwerkbetrieb
- passende Mod und OC-Adapter/Komponente für den jeweiligen Controller

## 2. Zentrale

```text
Tier-3 Computer
├── CPU
├── RAM
├── Speicher
├── Tier-3 GPU
├── Screen
├── Keyboard
└── Modem / Wireless-Modem
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

`BuldacityUI.lua` stellt Panels, Karten, Buttons, Balken, LEDs, Gauges, Diagramme, Sparklines, Icons und Touch-Zonen bereit.

Die Desktop-Version `v10.2` enthält:

```text
DESKTOP / APPS / NETWORK / DEVICES / REMOTE / REACTOR
```

## 4. Client-PC

Für jeden Mod kann ein eigener OC-PC verwendet werden:

```text
CPU + RAM + Speicher + Modem
```

Optional:

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

## 5. Hardware prüfen

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

BULDACITY sucht Netzwerkhardware ausdrücklich mit:

```lua
component.list("modem", true)
```

Wenn kein `modem` erscheint, kann die Maschine nicht am BULDACITY-Netzwerk teilnehmen.

## 6. Netzwerk

```text
Protokoll: BULDACITY/2
Port:      4242
```

Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Client:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

## 7. Discovery / Handshake

Die aktuelle `Network.lua` registriert beim Client zuerst den Listener und sendet danach HELLO.

```text
SERVER_HELLO
 ↓
HELLO
 ↓
LINK_ACK
 ↓
LINK_CONFIRM
 ↓
PING
 ↓
PONG
 ↓
HEARTBEAT
 ↓
COMPONENT_REQUEST
 ↓
COMPONENT_DATA
```

HELLO und HEARTBEAT werden regelmäßig wiederholt. Dadurch können neu gestartete Clients später ebenfalls gefunden werden.

## 8. SCAN und klickbare Geräte

Auf der Zentrale:

```text
DESKTOP → SCAN
```

Danach:

```text
DESKTOP → Client anklicken → DEVICES
DEVICES → Client anklicken → auswählen
APPS → Controller anklicken → REMOTE
REMOTE → REQUEST SCREEN
```

Die Client-Zeilen sind in Desktop v10.2 echte Touch/Button-Zonen.

## 9. Component-System

Zentrale:

```text
/home/BuldacityComponentServer.lua
```

Client:

```text
/home/BuldacityComponentAgent.lua
```

Der Agent meldet Component-Typen, Adressen und Modemdiagnose an die Zentrale.

Log:

```text
/home/BuldacityComponents.log
```

## 10. Wireless

Direkt:

```text
ZENTRALE ))) ((( CLIENT
```

Über Relay/AP:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Die Software verarbeitet alle gefundenen Modems und liest bei Wireless-Hardware die Signalstärke aus.

Test:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

## 11. Netzwerkdiagnose

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

Geprüft bzw. angezeigt werden unter anderem:

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

## 12. Remote-PC

1. Client in `DEVICES` auswählen.
2. `REMOTE` öffnen.
3. `REQUEST SCREEN` senden.
4. Client benötigt GPU + Screen.

Übertragen werden Bildschirmdaten über:

```text
SCREEN_BEGIN
SCREEN_ROW
SCREEN_END
```

## 13. Mod-Controller

Enthalten sind unter anderem Controller für:

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
IndustrialCraft2
LogisticsPipes
Mekanism
PneumaticCraft
ProjectE
RFTools
RotaryCraft
SGCraft
ThermalExpansion
```

## 14. Autostart

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
/home/buldacity-role.cfg
```

Server:

```text
ROLE=SERVER
```

Client-Beispiel:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Der Autostart lädt die Dateien aus `/home` und startet auf Clients zuerst den Component Agent und anschließend den Controller.

## 15. Fehlerbehebung: kein Client

```text
1. Client läuft
2. modem vorhanden
3. Network.lua vorhanden
4. ComponentAgent vorhanden
5. Network-Wrapper läuft
6. Port 4242 geöffnet
7. Wireless-Signal > 0 bei Wireless
8. Relay/AP prüfen
9. Zentrale SCAN
10. NetworkTest starten
```

Wenn `NETWORK → SERVER MODEMS` `0` zeigt, zuerst die Hardware der Zentrale prüfen.

## 16. Fehlerbehebung: kein Wireless

```text
Wireless-Modem vorhanden?
Signalstärke > 0?
Port 4242 offen?
Reichweite ausreichend?
Relay/AP korrekt?
```

## 17. Fehlerbehebung: Remote leer

```text
Client ONLINE
GPU vorhanden
Screen vorhanden
Network-Wrapper läuft
REQUEST SCREEN ausführen
```

## 18. Abschlusscheck

- [ ] `/home/Network.lua`
- [ ] `/home/BuldacityUI.lua`
- [ ] `/home/BuldacityOS_Tier3.lua`
- [ ] `/home/BuldacityDesktop.lua` v10.2
- [ ] `/home/BuldacityComponentServer.lua`
- [ ] `/home/BuldacityComponentAgent.lua`
- [ ] mindestens ein `modem` erkannt
- [ ] Port 4242 geöffnet
- [ ] Client sichtbar
- [ ] Client anklickbar
- [ ] PING/PONG PASS
- [ ] Component IDs sichtbar
- [ ] APPS sichtbar
- [ ] Remote-Screen funktioniert
- [ ] Autostart funktioniert

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
