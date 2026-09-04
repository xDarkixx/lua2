# BULDACITY Wireless Setup – Schritt für Schritt

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- Tier-3-Computer als Zentrale
- Network Card oder Wireless Network Card
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

## 4. Funkverbindung

Standard:

```text
Protocol: BULDACITY/2
Port:     4242
```

Die Wireless Cards müssen sich erreichen können. Bei großen Anlagen die Zentrale möglichst zentral platzieren.

## 5. Ersttest

1. Zentrale starten.
2. Nur einen Client einschalten.
3. Network-Controller starten.
4. Warten, bis der Client unter `DEVICES` erscheint.
5. Client auswählen.
6. `REMOTE` öffnen.
7. Touch/Tastatur testen.
8. Erst danach weitere Controller anschließen.

## 6. Autostart

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

## 7. Big Reactors

Der lokale Big-Reactors-Controller unterstützt `br_reactor` und `br_turbine`. Die Oberfläche enthält CORE, RODS und TURBINE.

## 8. Diagnose

Prüfen:

```lua
component.list("modem")
component.list("br_reactor")
component.list("br_turbine")
```

Danach den Controller-Scan verwenden.

## 9. Häufige Fehler

**Client fehlt:** Karte, Reichweite, Port, `Network.lua` und Network-Controller prüfen.

**Datei nicht gefunden:** Datei nach `/home` kopieren und den Network-Wrapper/Autostart verwenden.

**Remote leer:** Client-GPU/Screen und laufenden Network-Controller prüfen.

**Komponente fehlt:** Adapter/Driver bzw. direkte OC-Komponente prüfen. Ein Adapter garantiert keine Mod-API, wenn kein passender Driver vorhanden ist.
