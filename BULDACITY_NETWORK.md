# BULDACITY Netzwerk – Schritt für Schritt

Aktueller Stand: BULDACITY/2 für Minecraft 1.7.10 + OpenComputers.

## 1. Architektur

```text
                    TIER-3 ZENTRALE
               BuldacityOS_Tier3.lua
                      Network.lua
                           │
                    BULDACITY/2 :4242
             ┌─────────────┼─────────────┐
             │             │             │
          CLIENT        CLIENT        CLIENT
             │             │             │
           AE2 PC       Mekanism PC   Reactor PC
```

Es gibt genau **einen zentralen BULDACITY-Server**. Die Mod-Logik bleibt auf den jeweiligen normalen Controller-PCs.

## 2. Benötigte Dateien

### Zentrale
- `BuldacityOS_Tier3.lua`
- `Network.lua`
- `BuldacityUI.lua`
- `BuldacityComponentDashboard.lua`

### Clients
- der jeweilige `*Network*.lua` Controller
- `Network.lua`
- der jeweilige Mod-Controller

### Automatischer Start
- `BuldacityAutoStart.lua`
- `/home/buldacity-role.cfg`

Die alten BULDACITY/1-Dateien und die frühere separate Security-/Whitelist-Struktur gehören **nicht** mehr zum aktuellen Aufbau.

## 3. Zentrale Schritt für Schritt

1. Tier-3-Computer bauen.
2. CPU, RAM, Speicher, GPU, Screen und Keyboard einbauen.
3. Network Card oder Wireless Network Card einsetzen.
4. `Network.lua` und `BuldacityOS_Tier3.lua` nach `/home` kopieren.
5. Optional `BuldacityUI.lua` und `BuldacityComponentDashboard.lua` ebenfalls nach `/home` kopieren.
6. Desktop starten:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

7. Prüfen, ob der Desktop HOME/NETWORK/DEVICES/REMOTE anzeigt.

## 4. Client Schritt für Schritt

1. Normalen OpenComputers-PC bauen.
2. CPU, RAM, Speicher, GPU und Screen einbauen, wenn der Controller eine GUI besitzt.
3. Network Card/Wireless Network Card einsetzen.
4. `Network.lua` auf den PC kopieren.
5. Den passenden Network-Controller nach `/home` kopieren.
6. Mod-Komponenten/Adapter anschließen.
7. Network-Controller starten.
8. Die Zentrale muss den Client anschließend unter `DEVICES` erkennen.

## 5. Netzwerkstandard

- Minecraft: `1.7.10`
- Forge: `10.13.4.1614`
- OpenComputers: für Minecraft 1.7.10
- Protokoll: `BULDACITY/2`
- Port: `4242`
- keine Whitelist
- keine UUID-Rollenverwaltung

## 6. Remote-PC

Nach der Anmeldung kann der Tier-3-Desktop einen Client auswählen und dessen Oberfläche remote bedienen.

Übertragen werden je nach Controller:
- Bildschirmdaten
- `key_down`
- `key_up`
- Touch
- Scroll

Die eigentliche Maschinenlogik läuft weiterhin auf dem Client-PC.

## 7. Big Reactors

Der lokale Controller `ReactorBigReactors043A_Touch_Responsive.lua` besitzt getrennte Seiten für:
- CORE
- RODS
- TURBINE

Die Network-Version überträgt Reaktor-Telemetrie an die Zentrale. Der zentrale Desktop besitzt eine eigene REACTOR-Ansicht.

## 8. Verbindung testen

1. Zentrale starten.
2. Network Card/Wireless Card prüfen.
3. Port `4242` verwenden.
4. Nur **einen** Client starten.
5. Warten, bis er unter `DEVICES` erscheint.
6. Client auswählen.
7. `REMOTE` testen.
8. Erst danach weitere Clients hinzufügen.

## 9. Fehlerbehebung

### Client nicht sichtbar
- Network Card/Wireless Network Card prüfen.
- `Network.lua` vorhanden?
- richtiger Network-Controller gestartet?
- Client in Reichweite?
- Port `4242`?

### Datei nicht gefunden
Network-Wrapper und Autostart suchen Programme robust in `/home`, `/` und über die OpenOS-Shell-Auflösung. Controller sollten daher bevorzugt in `/home` installiert werden.

### Remote leer
- GPU/Screen am Client prüfen.
- Network-Controller muss laufen.
- Client muss bereits registriert sein.

### Komponenten fehlen
Immer zuerst `component.list()` bzw. den jeweiligen Controller-Scan verwenden. Nur tatsächlich exponierte OC-Methoden dürfen als verfügbar betrachtet werden.

## 10. Autostart

Auf jedem PC kann `BuldacityAutoStart.lua` als `/home/autorun.lua` installiert werden.

Server:

```text
ROLE=SERVER
```

Client, Beispiel Big Reactors:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Die unterstützten Client-Namen stehen in `BuldacityAutoStart.lua`.
