# BULDACITY v10.2 – Schritt für Schritt

Diese Anleitung beschreibt den aktuellen grafischen BULDACITY-Stand für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Was v10.2 bietet

- gemeinsame GPU-Oberfläche `BuldacityUI.lua`
- BULDACITY/2-Netzwerk auf Port `4242`
- Multi-Modem-Erkennung
- automatische Client-Discovery mit HELLO/HEARTBEAT
- LINK_ACK, LINK_CONFIRM und PING/PONG
- zentrale Component-Verwaltung
- klickbare Client-/Controller-Einträge
- DEVICES-, APPS- und REMOTE-Navigation
- Remote-Screen
- Wired/Wireless- und Relay/AP-Diagnose
- Autostart für Server und Clients

## 2. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- Tier-3-System für die Zentrale
- GPU + Screen für die GUI
- mindestens ein `modem` für Netzwerkbetrieb
- gewünschte Mod + passende OC-Komponente/Adapter

## 3. Alles nach `/home`

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

## 4. Zentrale starten

```text
Tier-3 CPU
RAM
Speicher
Tier-3 GPU
Screen
Keyboard
Modem
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 5. Modem prüfen

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

BULDACITY sucht ausdrücklich:

```lua
component.list("modem", true)
```

## 6. Netzwerk starten

```text
BULDACITY/2
Port 4242
```

Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Client:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

## 7. Client entdecken

Die aktuelle Reihenfolge ist:

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
 ↓
COMPONENT_REQUEST
 ↓
COMPONENT_DATA
```

Der Client registriert den Empfangs-Listener vor dem ersten HELLO. HELLO und HEARTBEAT werden anschließend regelmäßig erneut gesendet.

## 8. SCAN

Auf der Zentrale:

```text
DESKTOP → SCAN
```

Danach `NETWORK` und `DEVICES` öffnen.

## 9. Clients anklicken

Die aktuelle Desktop-Version `v10.2` registriert Client-Zeilen als echte Button-/Touch-Zonen.

```text
DESKTOP → Client anklicken → DEVICES
DEVICES → Client anklicken → Auswahl
APPS → Controller anklicken → REMOTE
REMOTE → REQUEST SCREEN
```

Wenn ein Client sichtbar ist, aber nicht reagiert, zuerst die aktuelle `BuldacityUI.lua` und `BuldacityDesktop.lua` aus `/home` prüfen.

## 10. Component-System

Zentrale:

```text
/home/BuldacityComponentServer.lua
```

Client:

```text
/home/BuldacityComponentAgent.lua
```

Der Agent meldet Hardware, Component-IDs und Modemdaten.

## 11. Wireless

```text
ZENTRALE ))) ((( CLIENT
```

oder:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Test:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

## 12. Netzwerkdiagnose

```lua
dofile("/home/BuldacityNetworkTest.lua")
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
LINK_ACK
LINK_CONFIRM
PING
PONG
HEARTBEAT
DISTANCE
LATENCY
```

## 13. Remote-PC

1. Client in `DEVICES` auswählen.
2. `REMOTE` öffnen.
3. `REQUEST SCREEN` senden.
4. Client benötigt GPU + Screen.

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

Client:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

## 15. Kein Client

```text
1. Client läuft
2. modem vorhanden
3. Network.lua vorhanden
4. ComponentAgent vorhanden
5. Network-Wrapper läuft
6. Port 4242 offen
7. Wireless-Signal prüfen
8. Relay/AP prüfen
9. Zentrale SCAN
10. NetworkTest
```

## 16. Remote leer

```text
Client ONLINE
GPU vorhanden
Screen vorhanden
Network-Wrapper läuft
REQUEST SCREEN ausführen
```

## 17. Logs

```text
/home/BuldacityComponents.log
```

## 18. Abschlussprüfung

- [ ] alle Kern-Dateien in `/home`
- [ ] `modem` erkannt
- [ ] Port 4242 offen
- [ ] Zentrale läuft
- [ ] Client läuft
- [ ] Client erscheint in `DEVICES`
- [ ] Client ist anklickbar
- [ ] PING/PONG PASS
- [ ] Component IDs sichtbar
- [ ] APPS sichtbar
- [ ] Remote-Screen funktioniert
- [ ] Autostart funktioniert

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
