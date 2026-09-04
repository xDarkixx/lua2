# lua2

OpenComputers Lua-Programme für Minecraft 1.7.10 und die im jeweiligen Script angegebenen Mod-Versionen.

## Systeme

- **Big Reactors** – Reaktor-Dashboard, Control-Rods, Status, Energie, Brennstoff und automatische Regelung
- **Applied Energistics 2** – ME-Netzwerk, Items und Craftables
- **Immersive Engineering** – Dieselgenerator, Tankstatus und AUTO/MANUAL-Steuerung
- **RotaryCraft** – Dashboard und optionale Redstone-Steuerung
- **Mekanism** – gemeinsames Buldacity-Dashboard für Mekanism-Komponenten
- **Thermal** – gemeinsames Buldacity-Dashboard für Thermal-Systeme
- **ProjectE** – Buldacity-Komponenten-Dashboard
- **RFTools** – Buldacity-Komponenten-Dashboard
- **SGCraft** – Stargate-Dashboard mit OpenComputers-Anbindung
- **PneumaticCraft** – Buldacity-Dashboard und Netzwerk-Controller für die OC-Drohnenanbindung
- **LogisticsPipes 0.9.3.132** – Buldacity-Logistik-Dashboard, Live-Komponentenscan, API-Erkennung und Netzwerkbetrieb

## LogisticsPipes 0.9.3.132

Für `logisticspipes-0.9.3.132.jar` auf Minecraft 1.7.10 gibt es zwei Startvarianten:

- `LogisticsPipes_Modern.lua` – lokale Buldacity-Touch-Oberfläche
- `LogisticsPipesNetwork_Modern.lua` – Tier-2-Version mit Buldacity-Netzwerk

Das Dashboard arbeitet mit der **tatsächlich zur Laufzeit exponierten OpenComputers-API**. Es erfindet keine feste LP-Adresse und keine nicht vorhandenen Methoden. Das ist wichtig, weil LP/OpenComputers-Kombinationen je nach Setup unterschiedlich erkannt werden können, unter anderem als `bc_pipe`.

Die Oberfläche bietet:

- Buldacity Sci-Fi/Neon-Design
- Live-Komponentenliste
- automatische Aktualisierung alle 2 Sekunden
- LP-Kandidaten-Erkennung
- Auswahl des LP-Endpunkts per Touch
- vollständige Anzeige der vom OC-Runtime gemeldeten Methoden
- API-Methodenzähler
- Inventar-/Item-/Request-/Crafting-relevante Erkennung über die reale API
- sicheren Zero-Argument-API-Probe-Modus
- Netzwerkstatus
- Tier-2-Anbindung
- manuelles Refresh und Tastatursteuerung

## Buldacity Netzwerk

Buldacity kann mehrere Tier-2-OpenComputers als Controller mit einem Tier-3-OpenComputers als zentralem Server verbinden.

- `BuldacityServer_Tier3.lua` – PC-artiger Tier-3-Server-Desktop
- `BuldacityNetworkClient.lua` – gemeinsamer Netzwerkdienst
- `BuldacityControllerLauncher.lua` – startet Controller mit Netzwerkregistrierung
- `BULDACITY_NETWORK.md` – vollständige Hardware-, Software-, Aufbau-, Installations-, Protokoll- und Fehlerbehebungsbeschreibung

Netzwerkstandard:

- **Protokoll:** `BULDACITY/1`
- **Port:** `4242`
- **Hardware:** Network Card oder Wireless Network Card auf Tier 2 und Tier 3
- **Remote:** Tastatur, Touch und Scroll können vom Tier 3 zum ausgewählten Tier 2 weitergeleitet werden

## Dokumentation

**Komponenten, Anschluss und Aufbau:**

[COMPONENTS.md](COMPONENTS.md)

**Tier-2/Tier-3-Netzwerk:**

[BULDACITY_NETWORK.md](BULDACITY_NETWORK.md)

Dort steht Schritt für Schritt:

1. welche OpenComputers-Hardware benötigt wird
2. welche Network Card benötigt wird
3. wie Tier 3 als Server aufgebaut wird
4. wie Tier 2 als Controller aufgebaut wird
5. wie die Rechner miteinander verbunden werden
6. welche Dateien auf welche Maschine gehören
7. wie der Launcher verwendet wird
8. wie `HELLO`, `HEARTBEAT`, `SERVER`, `PING`, `PONG` und `INPUT` funktionieren
9. wie Remote-Tastatur und Remote-Touch funktionieren
10. welche Einschränkungen die aktuelle Bildschirmübertragung hat
11. wie Fehler gesucht und behoben werden

## Moderne Dashboards

- `ReactorBigReactors043A_Touch_Responsive.lua`
- `AE2Network_Modern.lua`
- `DieselGenerator_Modern.lua`
- `RotaryCraftDashboard_Modern.lua`
- `Mekanism_Modern.lua`
- `Thermal_Modern.lua`
- `ProjectE_Modern.lua`
- `RFTools_Modern.lua`
- `SGCraft_Modern.lua`
- `ThermalExpansion_Modern.lua`
- `PneumaticCraft_Modern.lua`
- `LogisticsPipes_Modern.lua`
- `LogisticsPipesNetwork_Modern.lua`

Die ursprünglichen Lua-Dateien bleiben erhalten.
