# BULDACITY v10.2 – Netzwerk-Anleitung

Diese Anleitung beschreibt den aktuellen BULDACITY/2-Netzwerkstand für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Architektur

```text
                    TIER-3 ZENTRALE
              BuldacityOS + Desktop/GPU
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

## 2. Netzwerk-Hardware

BULDACITY verwendet die echte OpenComputers-Netzwerkkomponente `modem`.

Erkennung:

```lua
component.list("modem", true)
```

Verwendete Methoden sind unter anderem:

```text
modem.open(port)
modem.send(address, port, ...)
modem.broadcast(port, ...)
modem.setStrength(...)
modem.getStrength()
```

Eingehende Pakete kommen über `modem_message`.

Es wird keine erfundene `networkcard`-Komponente im Lua-Code vorausgesetzt. Je nach OC-Hardware ist das Netzwerkgerät als Modem/Wireless-Modem verfügbar.

## 3. Netzwerkparameter

```text
Protokoll: BULDACITY/2
Port:      4242
```

Alle BULDACITY-Netzwerkprogramme verwenden diese Parameter gemeinsam.

## 4. Zentrale installieren

Nach `/home` kopieren:

```text
Network.lua
BuldacityUI.lua
BuldacityOS_Tier3.lua
BuldacityDesktop.lua
BuldacityComponentServer.lua
BuldacityComponentDashboard.lua
BuldacityNetworkTest.lua
BuldacityWirelessCheck_Modern.lua
BuldacityAutoStart.lua
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 5. Client installieren

Nach `/home` kopieren:

```text
Network.lua
BuldacityUI.lua
BuldacityComponentAgent.lua
<Mod>Network_Modern.lua
<Mod>_Modern.lua
```

Der Client-Wrapper startet den Netzwerk-Client und danach den jeweiligen Mod-Controller.

## 6. Aktueller Discovery-Ablauf

Die aktuelle `Network.lua` registriert beim Client zuerst den `modem_message`-Listener und sendet erst danach HELLO. Dadurch geht die erste Server-Antwort nicht verloren.

Normaler Ablauf:

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

Der Client sendet HELLO und HEARTBEAT regelmäßig erneut. Die Zentrale sendet außerdem regelmäßig `SERVER_HELLO`, damit neu gestartete Clients gefunden werden.

## 7. Multi-Modem

BULDACITY verarbeitet **alle** gefundenen `modem`-Komponenten.

Die Diagnose erfasst unter anderem:

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
```

## 8. Zentrale SCAN

Auf der Zentrale:

```text
DESKTOP → SCAN
```

Nach einem erfolgreichen Handshake sollte der Client in `DEVICES` und in der Netzwerkübersicht erscheinen.

## 9. Wireless / Relay / Access Point

Direkt:

```text
ZENTRALE ))) ((( CLIENT
```

Über Relay/Access Point:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Wireless-fähige Modems werden anhand ihrer verfügbaren Funktionen erkannt. Wenn möglich, wird die Signalstärke gelesen und auf die konfigurierte BULDACITY-Stärke gesetzt.

## 10. Component-System

Der zentrale Component Server scannt seine Hardware. Jeder Client kann mit `BuldacityComponentAgent.lua` seine lokale Hardware melden.

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

Log:

```text
/home/BuldacityComponents.log
```

## 11. Desktop / klickbare Clients

Die aktuelle `BuldacityDesktop.lua` v10.2 besitzt:

```text
DESKTOP
APPS
NETWORK
DEVICES
REMOTE
REACTOR
```

Client-Einträge in `DESKTOP`, `APPS` und `DEVICES` sind als Buttons/Touch-Zonen registriert.

Bedienung:

```text
DESKTOP → Client anklicken → DEVICES
APPS → Controller anklicken → REMOTE
DEVICES → Client anklicken → Client auswählen
REMOTE → REQUEST SCREEN
```

Auch Component-Einträge werden als UI-Zonen dargestellt.

## 12. Remote-PC

Die Zentrale kann mit `SCREEN_REQUEST` den Bildschirm eines Clients anfordern. Der Client überträgt:

```text
SCREEN_BEGIN
SCREEN_ROW
SCREEN_END
```

Dafür benötigt der Client GPU + Screen.

## 13. Verbindung testen

```text
1. Zentrale starten
2. Client starten
3. CLIENT HELLO abwarten
4. Zentrale → SCAN
5. NETWORK prüfen
6. DEVICES öffnen
7. Client auswählen
8. PING/PONG prüfen
9. REMOTE öffnen
10. REQUEST SCREEN
```

Zusätzlich:

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

Wireless:

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

## 14. Kein Client sichtbar

```text
[ ] Client-PC läuft
[ ] modem-Komponente vorhanden
[ ] /home/Network.lua vorhanden
[ ] /home/BuldacityComponentAgent.lua vorhanden
[ ] Mod-Network-Wrapper läuft
[ ] Port 4242 geöffnet
[ ] Wireless-Signal > 0 bei Wireless
[ ] Relay/AP korrekt aufgebaut
[ ] Zentrale → SCAN
[ ] BuldacityNetworkTest.lua
```

Wenn `SERVER MODEMS` auf der Zentrale `0` zeigt, zuerst die Netzwerkhardware der Zentrale prüfen.

## 15. Kein Modem erkannt

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

Es muss mindestens ein Eintrag mit Typ `modem` vorhanden sein.

## 16. Wireless funktioniert nicht

Prüfen:

```text
WIRELESS-HARDWARE vorhanden
SIGNALSTÄRKE > 0
PORT 4242 geöffnet
Entfernung innerhalb der Reichweite
Relay/AP vorhanden und richtig verbunden
```

## 17. Remote leer

```text
Client ONLINE
GPU vorhanden
Screen vorhanden
Network-Wrapper läuft
REQUEST SCREEN ausführen
```

## 18. Logs und Diagnose

```text
/home/BuldacityComponents.log
/home/BuldacityNetworkTest.lua
/home/BuldacityWirelessCheck_Modern.lua
```

## 19. Autostart

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

## 20. Abschluss

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
COMPONENT DATA
      ↓
DEVICES
      ↓
REMOTE
```

**Grundregel: Alle BULDACITY-Dateien werden aus `/home` geladen.**
