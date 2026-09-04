# OpenComputers Komponenten & Anschlussübersicht

Diese Übersicht erklärt die OpenComputers-Komponenten für die Lua-Programme in diesem Repository.

## Grundaufbau

```text
[Touchscreen]
      │
[Computer] ─── [GPU]
      │
      ├── [Mod-Komponente / Adapter]
      └── optional [Redstone / Network Card]
```

## LogisticsPipes 0.9.3.132

Ziel: `logisticspipes-0.9.3.132.jar`, Minecraft 1.7.10.

### Wichtig zur OpenComputers-Unterstützung

LogisticsPipes enthält eine eigene OpenComputers-Proxy-Schicht. Der Quellcode zeigt `OpenComputersProxy` und OC-Wrapper-Klassen, die LP-Objekte und deren tatsächlich registrierte Befehle dynamisch bereitstellen.

Bei älteren 1.7.10-Kombinationen gab es Fälle, in denen Logistics Pipes von OpenComputers nur als `bc_pipe` erkannt wurde. Deshalb nimmt der Controller keine erfundene feste LP-Komponentenadresse an.

### Buldacity Controller

- `LogisticsPipes_Modern.lua` – lokale Touchscreen-Version
- `LogisticsPipesNetwork_Modern.lua` – Tier-2-Netzwerkversion

Die Oberfläche sucht die zur Laufzeit sichtbaren OpenComputers-Komponenten und zeigt die tatsächlich exponierten Methoden an. Dadurch werden keine nicht vorhandenen LP-Funktionen vorgetäuscht.

### Funktionen des Dashboards

- Buldacity Sci-Fi/Neon-Oberfläche
- LP-Kandidaten erkennen
- alle sichtbaren OC-Komponenten anzeigen
- tatsächlich exponierte LP-Methoden anzeigen
- API-Hilfe/Methodenübersicht
- Inventar-/Item-relevante Methoden erkennen
- Netzwerkstatus
- Control/API-Seite
- Touch-Navigation
- automatische Komponenten-Erkennung
- Refresh
- Tier-2-Anbindung an den Buldacity-Server

Die LP-OC-Wrapper besitzen `help()` und `helpCommand()` zur Anzeige der tatsächlich verfügbaren Befehle.

### Anschluss

```text
NORMAL:

Computer
   │
   ├── GPU ─── Screen/Touchscreen
   │
   └── OpenComputers-Verbindung
             │
             └── LogisticsPipes / erreichbarer LP-OC-Anschluss

NETZWERK:

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

Die normale LogisticsPipes-Rohrlogik bleibt Sache von LogisticsPipes/BuildCraft. Der Lua-Controller steuert nur das, was die installierte LP-Version tatsächlich über OpenComputers exponiert.

## Andere Systeme

### Big Reactors

```text
Computer + GPU + Screen + br_reactor
                         └─ optional br_turbine
```

### AE2

```text
Computer + GPU + Screen + me_controller + AE2 ME Network
```

### Diesel Generator

```text
Computer + GPU + Screen + ie_diesel_generator
```

### RotaryCraft

```text
Computer + GPU + Screen + optional Redstone
                         └─ RotaryCraft-Maschine
```

### PneumaticCraft

```text
Computer + GPU + Screen + PneumaticCraft-OC-Anschluss
                         └─ Drone / Drone Interface
```

## Schnellstart

1. OpenComputers-Computer aufstellen.
2. GPU und Screen anschließen.
3. Network Card für die Tier-2/Tier-3-Kommunikation installieren.
4. LogisticsPipes-OC-Anschluss so aufbauen, dass er vom Computer erreichbar ist.
5. `LogisticsPipes_Modern.lua` für lokal oder `LogisticsPipesNetwork_Modern.lua` für Tier 2 starten.
6. Auf `COMPONENTS` prüfen, was OpenComputers tatsächlich erkennt.
7. Auf `API` die vom installierten LP-Build exponierten Methoden prüfen.
