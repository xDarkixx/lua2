# lua2

OpenComputers-Lua-Programme für Minecraft 1.7.10 und die jeweils im Script angegebenen Mod-Versionen.

## Aktueller BULDACITY-Stand

BULDACITY verwendet einen zentralen Tier-3-Desktop und normale OpenComputers-Controller als Clients.

- Zentraler Desktop: `BuldacityOS_Tier3.lua`
- Netzwerk: `Network.lua`
- Protokoll: `BULDACITY/2`
- Port: `4242`
- Gemeinsames UI-Design: `BuldacityUI.lua`
- Generisches Dashboard: `BuldacityComponentDashboard.lua`
- Autostart: `BuldacityAutoStart.lua`
- Vollständige Schritt-für-Schritt-Anleitung: `BULDACITY_SCHRITT_FUER_SCHRITT.md`

## Desktop

Der zentrale Desktop bietet unter anderem:

- HOME
- NETWORK
- DEVICES
- APPS
- DISKS
- SYSTEM
- REMOTE
- REACTOR

Er verwendet Panels, Statusanzeigen, Live-Werte, Gauges, Buttons und Touch-Bereiche. Die Oberfläche passt sich an die verfügbare GPU-Auflösung an.

## Controller

Die klassischen Normal-Dateien bleiben erhalten. Die grafischen `_Modern.lua` Controller bleiben lokale Apps und werden nicht heimlich durch den Netzwerkcode ersetzt.

Network-Controller laufen auf normalen OpenComputers-PCs und verbinden sich mit dem zentralen Tier-3-System.

## Big Reactors 0.4.3A

`ReactorBigReactors043A_Touch_Responsive.lua` besitzt eine eigene grafische Oberfläche mit:

- CORE
- RODS
- TURBINE
- Energie
- Brennstoff
- Temperatur
- Control Rods
- AUTO
- Sicherheitsabschaltung
- Turbinenstatus
- Rotor Speed
- Output
- Fluid Flow
- Inductor

## Mod-Familien

Aktuelle Controller gibt es unter anderem für:

- Applied Energistics 2
- Big Reactors
- Diesel Generator / Immersive Engineering
- ExtraPlanets
- Forestry
- Galacticraft
- Gendustry
- Immersive Integration
- Immersive Railroading
- IndustrialCraft 2
- LogisticsPipes
- Mekanism
- PneumaticCraft
- ProjectE
- RFTools
- RotaryCraft
- SGCraft
- Thermal Expansion
- OpenComputers 3D Printer

## Installation – Kurzfassung

1. Minecraft 1.7.10 + Forge installieren.
2. OpenComputers und benötigte Mods installieren.
3. Tier-3-Zentrale bauen.
4. `Network.lua` + `BuldacityOS_Tier3.lua` nach `/home` kopieren.
5. Zentrale starten.
6. Pro Mod einen normalen Controller-PC aufbauen.
7. `Network.lua` und den passenden Network-Controller nach `/home` kopieren.
8. Mod-Komponente bzw. Adapter anschließen.
9. Lokale Modern-GUI testen.
10. Network-Controller starten.
11. Zentrale `DEVICES` prüfen.
12. `REMOTE` testen.
13. Autostart einrichten.

## Schritt-für-Schritt

Die vollständige aktuelle Anleitung steht in `BULDACITY_SCHRITT_FUER_SCHRITT.md`.

Weitere Dokumentation:

- `BULDACITY_SETUP_GUIDE.md`
- `BULDACITY_NETWORK.md`
- `BULDACITY_WIRELESS_SETUP.md`
- `BULDACITY_MOD_SETUP_ADDONS.md`
- `COMPONENTS.md`
- `BULDACITY_AUTOSTART.md`

## Wichtiger Installationsgrundsatz

**Installieren → Anschließen → Scannen → lokale GUI testen → Netzwerk testen → Zentrale prüfen → Autostart aktivieren.**

Bei fehlenden Funktionen immer die tatsächlich verfügbaren OpenComputers-Komponenten und Methoden prüfen. Ein Adapter garantiert nicht automatisch eine vollständige Mod-API.
