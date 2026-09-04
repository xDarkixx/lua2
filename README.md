# lua2

OpenComputers Lua-Programme für Minecraft 1.7.10 und die im jeweiligen Script angegebenen Mod-Versionen.

## Systeme

- **Big Reactors** – Reaktor-Dashboard, Control-Rods, Status, Energie, Brennstoff und automatische Regelung
- **Applied Energistics 2** – ME-Netzwerk, Items und Craftables
- **Immersive Engineering** – Dieselgenerator, Tankstatus und AUTO/MANUAL-Steuerung
- **RotaryCraft** – Dashboard und optionale Redstone-Steuerung

## Dokumentation

**Komponenten, Anschluss und Aufbau:**

[COMPONENTS.md](COMPONENTS.md)

Dort steht Schritt für Schritt:

1. welche OpenComputers-Komponente benötigt wird
2. wie Computer, GPU und Screen verbunden werden
3. welche Mod-Komponente für welches Script gebraucht wird
4. wie `br_reactor`, `br_turbine`, `me_controller` und `ie_diesel_generator` eingesetzt werden
5. welche Funktionen die einzelnen Dashboards haben
6. welche Versionen als Ziel verwendet werden

## Moderne Dashboards

- `ReactorBigReactors043A_Touch_Responsive.lua`
- `AE2Network_Modern.lua`
- `DieselGenerator_Modern.lua`
- `RotaryCraftDashboard_Modern.lua`

Die ursprünglichen Lua-Dateien bleiben erhalten.
