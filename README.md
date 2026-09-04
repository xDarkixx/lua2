# lua2

OpenComputers-Lua-Programme für Minecraft 1.7.10 und die jeweils im Script angegebenen Mod-Versionen.

## Controller-Struktur

Die Repository enthält bewusst zwei Controller-Stile:

- **Normal** – die klassischen Controller-Dateien bleiben erhalten.
- **Modern** – die aktuellen, grafisch überarbeiteten `_Modern.lua` Controller bleiben erhalten.
- **Big Reactors** – `ReactorBigReactors043A_Touch_Responsive.lua` ist der aktuelle Big-Reactors-Controller für Big Reactors 0.4.3A.

Es werden keine alten Sicherheits-/Whitelist-Module benötigt.

## Big Reactors 0.4.3A

`ReactorBigReactors043A_Touch_Responsive.lua` ist jetzt der zentrale Big-Reactors-Touch-Controller.

Funktionen:

- automatische Erkennung mehrerer `br_reactor` Komponenten
- Auswahl mehrerer Reaktoren
- Start / Stop per Touch und Tastatur
- Control-Rod-Auswahl und Regelung
- alle Control-Rods gemeinsam auf 0 / 50 / 100 % setzen
- Energie-, Brennstoff- und Temperaturanzeige
- Sicherheitsabschaltung bei zu wenig Brennstoff oder zu hoher Temperatur
- AUTO-Regelung: Start unter 10 %, Stop ab 90 % Energie
- Big-Reactors-Turbinen-Telemetrie
- Turbine Start / Stop und Inductor-Steuerung, soweit die Komponente die Methode anbietet
- funktioniert direkt als OpenComputers-Programm und kann hinter dem Buldacity-Netzwerkclient betrieben werden

## Buldacity Netzwerk

Das aktuelle Netzwerk besteht aus einem Tier-3-Hauptrechner und beliebig vielen OpenComputers-Clients.

- `BuldacityOS_Tier3.lua` – zentraler Tier-3-Desktop
- `BuldacityNetworkClient.lua` – gemeinsamer Clientdienst
- `BuldacityNetworkLauncher.lua` – Start-Wrapper
- `BuldacityControllerLauncher.lua` – Controller-Auswahl
- `BuldacityWireless.lua` – Wireless-/Modem-Schicht
- `BuldacityNetworkStatus.lua` – Diagnose
- `BuldacityNetworkInstall.lua` – Installation/Dateiprüfung

### Netzwerkstandard

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- Protokoll `BULDACITY/2`
- Port `4242`
- Tier-3 als zentrale Desktop-/Netzwerkstation
- Tier-2/Tier-3 als Controller-Clients
- Remote-Bildschirm sowie Tastatur-, Touch- und Scroll-Weiterleitung

Die Architektur enthält **keine Whitelist, keine UUID-Rollenverwaltung und keine separate Access-Control-Datei**.

## Dokumentation

- `BULDACITY_SETUP_GUIDE.md` – Grundaufbau
- `BULDACITY_NETWORK.md` – aktuelles BULDACITY/2-Netzwerk
- `BULDACITY_WIRELESS_SETUP.md` – Wireless, Komponenten und Fehlerbehebung
- `BULDACITY_MOD_SETUP_ADDONS.md` – zusätzliche Mod-Controller
- `COMPONENTS.md` – OpenComputers-Komponenten

Die Dokumentation beschreibt nur noch den aktuellen Aufbau. Alte BULDACITY/1-Dateien und nicht mehr benötigte Sicherheitsdokumente gehören nicht mehr zum Setup.

## Mod-Controller

Für die vorhandenen Mod-Familien bleiben die **Normal-Dateien** und die **Modern-Dateien** erhalten. Die Modern-Varianten verwenden die tatsächliche OpenComputers-Komponentenerkennung und behaupten keine nicht vorhandenen Mod-APIs.

Beispiele:

- Applied Energistics 2
- Diesel Generator / Immersive Engineering
- RotaryCraft
- Mekanism
- Thermal / Thermal Expansion
- ProjectE
- RFTools
- SGCraft
- PneumaticCraft
- LogisticsPipes
- IndustrialCraft 2
- Immersive Integration
- Immersive Railroading
- Galacticraft
- ExtraPlanets
- Forestry
- Gendustry
- OpenComputers 3D Printer

## Installation

1. Minecraft 1.7.10 mit Forge und OpenComputers starten.
2. Die benötigten Mod-Komponenten an den OpenComputers-Rechner anschließen.
3. Die gewünschten Normal-, Modern- oder Big-Reactors-Dateien nach `/home` kopieren.
4. Für Buldacity auf dem Tier-3-Rechner `BuldacityOS_Tier3.lua` starten.
5. Auf einem Controller `BuldacityControllerLauncher.lua` bzw. den gewünschten Controller starten.
6. Für Big Reactors direkt `ReactorBigReactors043A_Touch_Responsive.lua` starten.

## Erster Netzwerktest

Zuerst nur Tier 3 und einen Client verbinden. Der Client muss im Desktop erscheinen und regelmäßig Heartbeats senden. Danach Remote Interface öffnen und erst dann weitere Maschinen anschließen.

Weitere Details stehen in den drei Buldacity-Anleitungen oben.