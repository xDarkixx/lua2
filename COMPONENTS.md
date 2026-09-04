# OpenComputers Komponenten & Anschlussübersicht

Diese Übersicht erklärt die OpenComputers-Komponenten für die Lua-Programme in diesem Repository.

## Grundaufbau

```text
[Touchscreen]
      │
[Computer] ─── [GPU]
      │
      ├── [Mod-Komponente / Adapter]
      └── [Network Card / Wireless Network Card]
```

## LogisticsPipes 0.9.3.132

Ziel: `logisticspipes-0.9.3.132.jar`, Minecraft 1.7.10.

### OpenComputers-Unterstützung

LogisticsPipes besitzt eine OpenComputers-Integrationsschicht mit Wrappern für LP-Objekte und deren zur Laufzeit verfügbaren Befehle. Der Buldacity-Controller fragt deshalb die OC-Komponenten und Methoden direkt ab, statt eine feste Adresse oder eine erfundene API anzunehmen.

Je nach installiertem LP/OpenComputers/BuildCraft-Setup kann ein Pipe-Endpunkt anders erkannt werden; bei älteren Kombinationen wurde beispielsweise `bc_pipe` beobachtet. Der Controller berücksichtigt deshalb dynamische Erkennung.

### Buldacity Controller

- `LogisticsPipes_Modern.lua` – lokale Touchscreen-Version
- `LogisticsPipesNetwork_Modern.lua` – Tier-2-Netzwerkversion

### Dashboard-Funktionen

- Buldacity Sci-Fi/Neon-Oberfläche
- Live-Komponentenbus
- automatischer Scan alle 2 Sekunden
- manuelles Refresh
- LP-Kandidaten-Erkennung
- Auswahl eines LP-Endpunkts per Touch
- Anzeige aller aktuell exponierten OC-Methoden
- sortierte API-Übersicht
- API-Methodenzähler
- Erkennung von Item-, Inventory-, Request- und Crafting-relevanten Methoden
- Netzwerkstatus
- Tier-2/Tier-3-Betrieb
- sichere Zero-Argument-Probes für nicht mutierende Methoden
- keine erfundenen Argumente für LP-Befehle

### Komponentenliste

Die Liste ist **nicht statisch**. `component.list()` wird während des laufenden Programms regelmäßig neu ausgewertet. Dadurch werden neue Komponenten automatisch aufgenommen und entfernte Komponenten automatisch entfernt. Die Auswahl eines bereits verwendeten LP-Endpunkts wird nach Möglichkeit über dessen Adresse erhalten.

### Anschluss NORMAL

```text
Computer
   │
   ├── GPU ─── Screen/Touchscreen
   │
   └── OpenComputers-Verbindung
             │
             └── LogisticsPipes / erreichbarer LP-OC-Anschluss
```

### Anschluss NETZWERK

```text
Tier-3 Server
     │
 Wireless Network
     │
     ├──────── Tier-2 Computer
     │                 │
     │                 ├── GPU ─── Screen
     │                 └── LP-OC-Verbindung
     │
     └──────── weitere Tier-2 Controller
```

Die normale LogisticsPipes-Rohrlogik bleibt Sache von LogisticsPipes/BuildCraft. Der Lua-Controller kann nur Funktionen ausführen, die die installierte LP-OC-Integration tatsächlich exponiert.

## PneumaticCraft

```text
Computer + GPU + Screen + PneumaticCraft-OC-Anschluss
                         └─ Drone / Drone Interface
```

## Big Reactors

```text
Computer + GPU + Screen + br_reactor
                         └─ optional br_turbine
```

## AE2

```text
Computer + GPU + Screen + me_controller + AE2 ME Network
```

## Diesel Generator

```text
Computer + GPU + Screen + ie_diesel_generator
```

## RotaryCraft

```text
Computer + GPU + Screen + optional Redstone
                         └─ RotaryCraft-Maschine
```

## Schnellstart LogisticsPipes

1. OpenComputers-Computer aufstellen.
2. GPU und Screen anschließen.
3. Für Tier 2/Tier 3 eine Network Card oder Wireless Network Card installieren.
4. LogisticsPipes-OC-Anschluss so aufbauen, dass der Computer ihn erreichen kann.
5. `LogisticsPipes_Modern.lua` lokal oder `LogisticsPipesNetwork_Modern.lua` auf Tier 2 starten.
6. Auf `COMPONENTS` prüfen, was aktuell erkannt wird.
7. Einen LP-Kandidaten antippen.
8. Auf `API` die tatsächlich exponierten Methoden prüfen.
9. Für sichere parameterlose Status-/Info-Aufrufe kann die Control-Seite einen Zero-Argument-Probe ausführen.
10. Für Methoden mit Argumenten werden keine erfundenen Parameter gesendet.
