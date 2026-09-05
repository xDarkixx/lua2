# BULDACITY v10 – Netzwerk Schritt für Schritt

Diese Anleitung beschreibt das aktuelle BULDACITY/2-Netzwerk für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Architektur

```text
                    TIER-3 ZENTRALE
                 BuldacityOS + GPU UI
                         │
                  BULDACITY/2 :4242
                         │
          ┌──────────────┼──────────────┐
          │              │              │
        WIRED         WIRELESS       RELAY / AP
          │              )))              │
          ▼               (((             ▼
       CLIENT PC       CLIENT PC       CLIENT PC
          │              │               │
       Mod-Gerät      Mod-Gerät       Mod-Gerät
```

Die Zentrale verwaltet die Flotte. Die eigentliche Mod-Logik bleibt auf den jeweiligen Clients.

## 2. Netzwerk-API

BULDACITY verwendet die OpenComputers-Netzwerkkomponente als `modem` und nutzt die realen Methoden:

```text
modem.open(port)
modem.send(address, port, ...)
modem.broadcast(port, ...)
modem.setStrength(...)
modem.getStrength()
```

Eingehende Pakete kommen über:

```text
modem_message
```

Es wird **nicht** einfach eine erfundene `networkcard`-Komponente vorausgesetzt. Die vorhandene OC-Netzwerkhardware wird über `component.list("modem", true)` erkannt.

## 3. Zentrale installieren

Nach `/home`:

```text
Network.lua
BuldacityUI.lua
BuldacityOS_Tier3.lua
BuldacityDesktop.lua
BuldacityComponentServer.lua
BuldacityComponentDashboard.lua
BuldacityNetworkTest.lua
BuldacityWirelessCheck_Modern.lua
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 4. Client installieren

Nach `/home`:

```text
Network.lua
BuldacityUI.lua
BuldacityComponentAgent.lua
<Mod>Network_Modern.lua
<Mod>_Modern.lua
```

## 5. Netzwerkparameter

```text
Protokoll: BULDACITY/2
Port:      4242
```

Alle BULDACITY-Netzwerkprogramme verwenden diese Parameter gemeinsam.

## 6. Was die neue Netzdiagnose prüft

Die zentrale `Network.lua` prüft bei jedem Scan:

```text
MODEM ANZAHL
MODEM ADDRESS
MODEM TYP
WIRED / WIRELESS
SIGNALSTÄRKE
PORT 4242
OPEN STATUS
RELAY
ACCESS POINT
WIRELESS PATH
SCAN-STUFE
```

Das Desktop-Network-Panel zeigt diese Werte direkt an.

## 7. Alle Modems werden berücksichtigt

BULDACITY verwendet nicht nur ein primäres Modem. Alle gefundenen Modems werden geöffnet und für `send`/`broadcast` berücksichtigt.

Das ist wichtig, wenn ein Rechner mehrere Netzwerkkomponenten besitzt oder Wired und Wireless parallel verwendet.

## 8. Wireless

Direkt:

```text
ZENTRALE ))) ((( CLIENT
```

Über Relay/Access Point:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Die Software erkennt Wireless-fähige Modems anhand der verfügbaren `getStrength`/`setStrength`-Funktionen und liest die Signalstärke aus.

## 9. Relay / Access Point

Die Diagnose zählt erkannte:

```text
relay
access_point
```

und bildet daraus einen Pfadstatus wie:

```text
NONE
WIRED_RELAY
WIRELESS_RELAY
ACCESS_POINT
RELAY+ACCESS_POINT
```

Ein Relay kann nur dann einen Wireless-Pfad liefern, wenn die passende Wireless-Hardware vorhanden ist.

## 10. Verbindung testen

Reihenfolge:

```text
1. Zentrale starten
2. Client starten
3. CLIENT HELLO abwarten
4. Zentrale → SCAN
5. DEVICES öffnen
6. Client auswählen
7. PING/PONG prüfen
8. REMOTE öffnen
```

Zusätzlich:

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

## 11. Handshake

Der normale Ablauf ist:

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
```

`PONG` wird als erfolgreicher Verbindungstest gespeichert.

## 12. Component-Diagnose

Der zentrale Component Server scannt die lokale Hardware und jeder Component Agent scannt die Client-Hardware.

Gemeldet werden unter anderem:

```text
Component-Typ
Component-Adresse
Modem-Adresse
Modem-Typ
Wireless-Status
Signalstärke
Port
Component-Anzahl
```

Die Daten werden in der Zentrale zusammengeführt.

## 13. Logs

Der Component Server schreibt:

```text
/home/BuldacityComponents.log
```

Dort stehen Server-, Client-, Component- und Modemdaten.

## 14. Kein Client sichtbar

Prüfe in dieser Reihenfolge:

```text
[ ] Client-PC läuft
[ ] Network-Hardware vorhanden
[ ] /home/Network.lua vorhanden
[ ] /home/BuldacityComponentAgent.lua vorhanden
[ ] Mod-Network-Wrapper läuft
[ ] Port 4242 geöffnet
[ ] Wireless-Signal > 0 bei Wireless
[ ] Relay/AP korrekt aufgebaut
[ ] Zentrale → SCAN
[ ] BuldacityNetworkTest.lua
```

Auf der Zentrale sollte die NETWORK-Seite zuerst `SERVER MODEMS` größer als 0 anzeigen.

## 15. Kein Modem erkannt

Auf der betroffenen Maschine:

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

Wenn kein `modem` auftaucht, kann BULDACITY keine Netzwerkpakete senden.

## 16. Wireless funktioniert nicht

Prüfen:

```text
WIRELESS-HARDWARE vorhanden
SIGNALSTÄRKE > 0
PORT 4242 geöffnet
Entfernung innerhalb der Reichweite
Relay/AP vorhanden und richtig verbunden
```

Danach:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

## 17. Remote-PC

Die Zentrale kann über `SCREEN_REQUEST` den Client-Screen anfordern. Der Client überträgt `SCREEN_BEGIN`, `SCREEN_ROW` und `SCREEN_END`.

Dafür benötigt der Client GPU + Screen.

## 18. Netzwerkseiten der Oberfläche

```text
DESKTOP
  └─ Fleet / Online / Linked / Modems

NETWORK
  ├─ Server Modems
  ├─ Wireless
  ├─ Client-Anzahl
  ├─ Signalstärke
  ├─ Port
  ├─ Address
  ├─ Relay/AP
  └─ Scan-Status

DEVICES
  └─ Client + Component IDs

REMOTE
  └─ Client-Screen
```

## 19. Abschluss

```text
ZENTRALE ONLINE
      ↓
MODEM READY
      ↓
SERVER_HELLO
      ↓
CLIENT HELLO
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
DEVICES / COMPONENTS
      ↓
REMOTE
```

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
