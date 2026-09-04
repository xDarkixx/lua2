# BULDACITY Wireless Setup – Schritt für Schritt

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- Tier-3-Computer als Zentrale
- Network Card oder Wireless Network Card
- optional OpenComputers Relay / Access Point für längere Netzwerkwege
- Port `4242`

Der aktuelle Aufbau verwendet **BULDACITY/2**. Es gibt keine alte BULDACITY/1-Security-Struktur, keine Whitelist und keine UUID-Rollenverwaltung.

## 2. Zentrale aufbauen

```text
Tier-3
├── CPU
├── RAM
├── Speicher
├── GPU
├── Screen
├── Keyboard
└── Network/Wireless Network Card
```

Nach `/home` kopieren:
- `Network.lua`
- `BuldacityOS_Tier3.lua`
- `BuldacityUI.lua`
- `BuldacityComponentDashboard.lua`

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 3. Client aufbauen

```text
Controller-PC
├── CPU
├── RAM
├── Speicher
├── GPU/Screen (bei GUI-Controller)
└── Network/Wireless Network Card
```

Nach `/home` kopieren:
- `Network.lua`
- passender `*Network*.lua` Controller
- passender Mod-Controller

## 4. Automatische maximale Funkstärke

`Network.lua` erkennt eine Wireless Network Card automatisch. Beim Initialisieren und vor dem Senden wird die maximale vorgesehene BULDACITY-Funkstärke versucht. Danach wird die tatsächlich gesetzte Stärke ausgelesen.

Die gemeinsame Bibliothek verwendet standardmäßig `400` als maximalen Zielwert. Wenn ein älterer oder anders konfigurierter OpenComputers-Build diesen Wert nicht akzeptiert, wird sicher auf einen kleineren Wert zurückgefallen.

Prüfen:

```lua
local c=require("component")
print(c.modem.getStrength())
```

## 5. Relay / Access Point

OpenComputers kann Netzwerk-Nachrichten über Relay bzw. Access Point zwischen Netzwerkabschnitten weiterleiten. Dafür braucht BULDACITY keinen separaten Lua-Relay-Treiber. Die physische OpenComputers-Netzwerkkomponente übernimmt das Weiterleiten; `Network.lua` verarbeitet die danach eintreffenden `modem_message`-Events normal.

Beispiel:

```text
[Zentrale Wireless]
       ))))
        │
   [Relay / Access Point]
        │
     [Kabel]
        │
   [Client Network Card]
```

Die BULDACITY-Clients melden zusätzlich `relay=true`, Funkstatus und die zuletzt erkannte Funkentfernung an die Zentrale.

## 6. Funkverbindung

Standard:

```text
Protocol: BULDACITY/2
Port:     4242
```

Die Wireless Cards müssen sich direkt oder über einen korrekt verbundenen Relay/Access-Point-Netzwerkweg erreichen können.

## 7. Ersttest

1. Zentrale starten.
2. Nur einen Client einschalten.
3. Network-Controller starten.
4. Warten, bis der Client unter `DEVICES` erscheint.
5. Client auswählen.
6. `REMOTE` öffnen.
7. Touch/Tastatur testen.
8. Erst danach weitere Clients anschließen.

## 8. Autostart

`BuldacityAutoStart.lua` kann als `/home/autorun.lua` verwendet werden.

Server-Konfiguration:

```text
ROLE=SERVER
```

Client-Konfiguration, z. B. Big Reactors:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Der Autostart sucht Programme robust in `/home`, `/` und über die OpenOS-Pfadauflösung.

## 9. Big Reactors

Der lokale Big-Reactors-Controller unterstützt `br_reactor` und `br_turbine`. Die Oberfläche enthält CORE, RODS und TURBINE.

## 10. Diagnose

Prüfen:

```lua
component.list("modem")
component.list("br_reactor")
component.list("br_turbine")
```

Wireless-Stärke:

```lua
local c=require("component")
print(c.modem.getStrength())
```

Danach den Controller-Scan verwenden.

## 11. Häufige Fehler

**Client fehlt:** Karte, Funkstärke, Reichweite, Relay/Access Point, Port, `Network.lua` und Network-Controller prüfen.

**Wireless sendet nicht:** Prüfen, ob `getStrength()` größer als `0` ist und die Karte Energie hat.

**Relay-Weg funktioniert nicht:** Beide Netzwerkseiten des Relay/Access Points prüfen und sicherstellen, dass der Netzwerkweg physisch verbunden ist.

**Datei nicht gefunden:** Datei nach `/home` kopieren und den Network-Wrapper/Autostart verwenden.

**Remote leer:** Client-GPU/Screen und laufenden Network-Controller prüfen.

**Komponente fehlt:** Adapter/Driver bzw. direkte OC-Komponente prüfen. Ein Adapter garantiert keine Mod-API, wenn kein passender Driver vorhanden ist.
