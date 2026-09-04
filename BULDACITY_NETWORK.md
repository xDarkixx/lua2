# BULDACITY Netzwerk – Schritt für Schritt

Aktueller Stand: BULDACITY/2 für Minecraft 1.7.10 + OpenComputers.

## 1. Architektur

```text
                    TIER-3 ZENTRALE
               BuldacityOS_Tier3.lua
                      Network.lua
                           │
                    BULDACITY/2 :4242
                           │
                 Wireless / Wired Network
                           │
                    ┌──────┴──────┐
                    │ OpenComputers│
                    │ Relay / AP   │
                    └──────┬──────┘
                           │
             ┌─────────────┼─────────────┐
             │             │             │
          CLIENT        CLIENT        CLIENT
             │             │             │
           AE2 PC       Mekanism PC   Reactor PC
```

Es gibt genau **einen zentralen BULDACITY-Server**. Die Mod-Logik bleibt auf den jeweiligen normalen Controller-PCs.

OpenComputers-Relays und Access Points werden auf Netzwerkebene verarbeitet. Die Lua-Controller müssen keinen eigenen Relay-Treiber installieren: Eine über Relay/Access Point weitergeleitete `modem_message`-Nachricht wird von `Network.lua` normal verarbeitet. Bei Funkempfang kann OpenComputers zusätzlich die Entfernung im `modem_message`-Event liefern.

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

## 6. Wireless + Relay / Access Point

Die gemeinsame `Network.lua` übernimmt die Wireless-Konfiguration für Wireless Network Cards. Beim Start wird die maximale vorgesehene BULDACITY-Funkstärke versucht; die tatsächlich vom OpenComputers-Build akzeptierte Stärke wird anschließend ausgelesen.

Für große Anlagen kann der Netzwerkweg über OpenComputers Relay oder Access Point geführt werden:

```text
Wireless Card
      ))))
   Relay / AP
      │
   Network
      │
Wireless Card
```

Ein Relay/Access Point muss dabei physisch korrekt mit den jeweiligen Netzwerkseiten verbunden sein. Das Weiterleiten selbst erledigt OpenComputers; BULDACITY sendet und empfängt weiterhin über den normalen Modem-Port `4242`.

Die `Network.lua` markiert Clients als `relay=true` und überträgt zusätzlich Funkstatus, Signalstärke und die zuletzt erkannte Funkentfernung. Eine Relay-Verbindung ist dabei transparent und benötigt keinen separaten Lua-Relay-Prozess.

OpenComputers dokumentiert, dass Wireless Network Cards für Funkpakete eine gesetzte Signalstärke benötigen. Relays/Access Points können Netzwerk-Nachrichten zwischen Netzwerken weiterleiten. citeturn0search2turn0search6

## 7. Remote-PC

Nach der Anmeldung kann der Tier-3-Desktop einen Client auswählen und dessen Oberfläche remote bedienen.

Übertragen werden je nach Controller:
- Bildschirmdaten
- `key_down`
- `key_up`
- Touch
- Scroll

Die eigentliche Maschinenlogik läuft weiterhin auf dem Client-PC.

## 8. Big Reactors

Der lokale Controller `ReactorBigReactors043A_Touch_Responsive.lua` besitzt getrennte Seiten für:
- CORE
- RODS
- TURBINE

Die Network-Version überträgt Reaktor-Telemetrie an die Zentrale. Der zentrale Desktop besitzt eine eigene REACTOR-Ansicht.

## 9. Verbindung testen

1. Zentrale starten.
2. Network Card/Wireless Card prüfen.
3. Bei Wireless die Signalstärke prüfen.
4. Optional Relay/Access Point zwischen den Netzabschnitten einsetzen.
5. Port `4242` verwenden.
6. Nur **einen** Client starten.
7. Warten, bis er unter `DEVICES` erscheint.
8. Client auswählen.
9. `REMOTE` testen.
10. Erst danach weitere Clients hinzufügen.

## 10. Fehlerbehebung

### Client nicht sichtbar
- Network Card/Wireless Network Card prüfen.
- `Network.lua` vorhanden?
- richtiger Network-Controller gestartet?
- Client in Reichweite oder über Relay/Access Point verbunden?
- Port `4242`?

### Wireless funktioniert nicht
- Wireless Network Card vorhanden?
- Signalstärke größer als `0`?
- Energieversorgung ausreichend?
- Relay/Access Point korrekt angeschlossen?
- Netzwerk-Port `4242` geöffnet?

### Datei nicht gefunden
Network-Wrapper und Autostart suchen Programme robust in `/home`, `/` und über die OpenOS-Shell-Auflösung. Controller sollten daher bevorzugt in `/home` installiert werden.

### Remote leer
- GPU/Screen am Client prüfen.
- Network-Controller muss laufen.
- Client muss bereits registriert sein.

### Komponenten fehlen
Immer zuerst `component.list()` bzw. den jeweiligen Controller-Scan verwenden. Nur tatsächlich exponierte OC-Methoden dürfen als verfügbar betrachtet werden.

## 11. Autostart

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
