# BULDACITY v10 – Schritt für Schritt

Diese Anleitung beschreibt die aktuelle grafische BULDACITY-Version für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Was v10 bietet

BULDACITY verwendet eine gemeinsame GPU-Oberfläche (`BuldacityUI.lua`) und einen zentralen BULDACITY/2-Netzwerkdienst.

Enthalten sind:

- GPU-Panels, Karten und Balken
- Status-LEDs, Badges und Buttons
- Gauges, Sparklines und Diagramme
- Pixel-Icons
- Desktop / APPS / NETWORK / DEVICES / REMOTE / REACTOR
- zentrale Component-Verwaltung
- Remote-Screen
- Multi-Modem-Erkennung
- Wired/Wireless-Diagnose
- Signalstärke und Port-Anzeige
- Relay-/Access-Point-Erkennung
- PING/PONG- und Heartbeat-Diagnose

## 2. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- Tier-3-System für die Zentrale
- GPU + Screen für die grafische Oberfläche
- Netzwerkkomponente für Netzwerkbetrieb
- gewünschte Mod + passende OC-Komponente/Adapter

## 3. Grundregel: alles nach `/home`

Alle BULDACITY-Lua-Dateien werden unter `/home` abgelegt.

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityOS_Tier3.lua
/home/BuldacityDesktop.lua
/home/BuldacityComponentServer.lua
/home/BuldacityComponentAgent.lua
/home/BuldacityComponentDashboard.lua
/home/BuldacityAutoStart.lua
/home/BuldacityNetworkTest.lua
/home/BuldacityWirelessCheck_Modern.lua
```

Mod-spezifische Dateien ebenfalls nach `/home`.

## 4. Zentrale aufbauen

```text
Tier-3 CPU
RAM
Speicher
Tier-3 GPU
Screen
Keyboard
Network/Wireless Network Card
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 5. Netzwerk-Hardware prüfen

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

Für BULDACITY-Netzwerk muss eine `modem`-Komponente vorhanden sein.

Die Software sucht ausdrücklich mit:

```lua
component.list("modem", true)
```

und verarbeitet alle gefundenen Modems.

## 6. Netzwerk starten

```text
Protokoll: BULDACITY/2
Port: 4242
```

Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Client:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

## 7. Netzwerk-Scan

Auf der Zentrale:

```text
DESKTOP → SCAN
```

Die NETWORK-Seite zeigt jetzt:

```text
SERVER MODEMS
WIRELESS
CLIENTS
MODEM ADDRESS
SIGNAL
PORT 4242
RELAY/AP
SCAN STATUS
```

## 8. Client entdecken

Der normale Ablauf:

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
PONG PASS
 ↓
HEARTBEAT
```

Der Client erscheint anschließend unter `DEVICES`.

## 9. Wireless

```text
ZENTRALE ))) ((( CLIENT
```

oder:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Wireless-fähige Modems werden erkannt und ihre Stärke ausgelesen. Wenn `setStrength()` vorhanden ist, wird die konfigurierte maximale BULDACITY-Stärke verwendet.

## 10. Netzwerkdiagnose

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

Zusätzlich:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

Prüfen:

```text
MODEM
WIRELESS
SIGNAL
PORT
ADDRESS
RELAY/AP
HELLO
HEARTBEAT
PING
PONG
DISTANCE
LATENCY
```

## 11. Component-System

Zentrale:

```text
/home/BuldacityComponentServer.lua
```

Client:

```text
/home/BuldacityComponentAgent.lua
```

Die Component-Daten enthalten Typen, Adressen und Modemdiagnose.

Log:

```text
/home/BuldacityComponents.log
```

## 12. Component Dashboard

```lua
dofile("/home/BuldacityComponentDashboard.lua")
```

Damit können Client-Componenten und IDs betrachtet werden.

## 13. APPS

Die zentrale Oberfläche enthält eine eigene `APPS`-Seite für die erkannten Client-Anwendungen.

```text
DESKTOP → APPS
```

Dort werden verbundene Controller und ihr Online-Status angezeigt.

## 14. Remote-PC

1. Client unter `DEVICES` auswählen.
2. `REMOTE` öffnen.
3. `REQUEST SCREEN` senden.
4. Client muss GPU + Screen besitzen.

Die Übertragung erfolgt über BULDACITY-Pakete.

## 15. Mod-Controller

Vorhandene Controller umfassen unter anderem:

```text
3D Printer
AE2
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
Big Reactors / Extreme Reactors
```

## 16. Autostart

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
/home/buldacity-role.cfg
```

Zentrale:

```text
ROLE=SERVER
```

Client:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

## 17. Fehler: kein Client

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
10. NetworkTest
```

Wenn `NETWORK → SERVER MODEMS` bereits `0` zeigt, zuerst die Netzwerkhardware der Zentrale reparieren.

## 18. Fehler: kein Wireless

Prüfen:

```text
Wireless-Modem vorhanden
Signalstärke > 0
Port 4242 offen
Reichweite
Relay/AP
```

## 19. Fehler: Remote leer

Prüfen:

```text
Client ONLINE
GPU vorhanden
Screen vorhanden
Network-Wrapper läuft
REQUEST SCREEN
```

## 20. Abschlussprüfung

- [ ] `/home/Network.lua`
- [ ] `/home/BuldacityUI.lua`
- [ ] `/home/BuldacityOS_Tier3.lua`
- [ ] `/home/BuldacityDesktop.lua`
- [ ] `/home/BuldacityComponentServer.lua`
- [ ] `/home/BuldacityComponentAgent.lua`
- [ ] mindestens ein Modem erkannt
- [ ] Port 4242 geöffnet
- [ ] Client sichtbar
- [ ] PING/PONG PASS
- [ ] Component IDs sichtbar
- [ ] APPS sichtbar
- [ ] Remote-Screen funktioniert
- [ ] Autostart funktioniert

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
