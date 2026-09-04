# lua2

OpenComputers-Lua-Programme für Minecraft 1.7.10 und die jeweils im Script angegebenen Mod-Versionen.

## Controller-Struktur

Die Repository enthält bewusst zwei Controller-Stile:

- **Normal** – die klassischen Controller-Dateien bleiben erhalten.
- **Modern** – die grafisch überarbeiteten `_Modern.lua` Controller bleiben als Desktop-Apps erhalten.
- **Big Reactors** – `ReactorBigReactors043A_Touch_Responsive.lua` ist der aktuelle Big-Reactors-Controller für Big Reactors 0.4.3A.
- **Network-Controller** – die `*_Network_Modern.lua` Programme laufen auf normalen Controller-PCs und stellen die Verbindung zum Tier-3-Hauptrechner her.

## Neue Buldacity-Architektur

Der Tier-3-Hauptrechner ist jetzt ein echter zentraler Desktop-Hub:

- `BuldacityOS_Tier3.lua` ist der zentrale Desktop und Netzwerk-Hub.
- `Network.lua` ist die gemeinsame Netzwerkbibliothek für normale Controller-PCs.
- Die alten separaten `Buldacity*` Netzwerk-Hilfsprogramme werden nicht mehr benötigt.
- Der Desktop entdeckt Controller automatisch über `BULDACITY/2`.
- Modern-Controller werden im Desktop als Apps angezeigt.
- Network-Controller laufen auf den normalen PCs und melden ihren Namen, Controller und Status.
- Remote-Bildschirm, Tastatur, Touch und Scroll können über den Tier-3-Desktop verwendet werden.
- Keine Whitelist, keine UUID-Rollenverwaltung und keine separate Access-Control-Datei.

### Netzwerkstandard

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- Protokoll `BULDACITY/2`
- Port `4242`
- Tier-3 als zentraler Desktop-/Netzwerk-Hub
- normale OpenComputers-PCs als Controller-Clients
- automatische Discovery und Heartbeat
- Remote-Screen sowie Tastatur-, Touch- und Scroll-Weiterleitung

## Big Reactors 0.4.3A

`ReactorBigReactors043A_Touch_Responsive.lua` ist der zentrale Big-Reactors-Touch-Controller.

Funktionen:

- automatische Erkennung mehrerer `br_reactor` Komponenten
- Auswahl mehrerer Reaktoren
- Start / Stop per Touch und Tastatur
- Control-Rod-Auswahl und Regelung
- alle Control-Rods gemeinsam auf 0 / 50 / 100 % setzen
- Energie-, Brennstoff- und Temperaturanzeige
- Sicherheitsabschaltung bei zu wenig Brennstoff oder zu hoher Temperatur
- AUTO-Regelung
- Big-Reactors-Turbinen-Telemetrie
- Turbine Start / Stop und Inductor-Steuerung, soweit die Komponente die Methode anbietet

## Mod-Controller

Für die vorhandenen Mod-Familien bleiben die **Normal-Dateien** und die **Modern-Dateien** erhalten.

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
2. Die benötigten Mod-Komponenten an den jeweiligen OpenComputers-PC anschließen.
3. Die gewünschten Normal- oder Modern-Controller nach `/home` kopieren.
4. Auf dem Tier-3-Hauptrechner `BuldacityOS_Tier3.lua` starten.
5. Auf normalen Controller-PCs den passenden `*_Network_Modern.lua` Controller starten. Dieser verwendet `Network.lua` für BULDACITY/2.
6. Modern-Controller bleiben normale Desktop-Apps und müssen nicht in den Tier-3-Netzwerkkern eingebaut werden.
7. Für Big Reactors direkt `ReactorBigReactors043A_Touch_Responsive.lua` starten.

## Erster Netzwerktest

Zuerst den Tier-3-Desktop starten und danach einen Network-Controller auf einem normalen PC. Der Client sollte automatisch unter **DEVICES** erscheinen. Anschließend **REMOTE** öffnen und den Controller auswählen.

Die Netzwerkverbindung benötigt nur einen Modem bzw. eine Wireless Network Card auf den beteiligten OpenComputers-PCs. Port `4242` und Protokoll `BULDACITY/2` werden automatisch verwendet.

## Dokumentation

- `BULDACITY_SETUP_GUIDE.md` – Grundaufbau
- `BULDACITY_NETWORK.md` – aktuelles BULDACITY/2-Netzwerk
- `BULDACITY_WIRELESS_SETUP.md` – Wireless, Komponenten und Fehlerbehebung
- `BULDACITY_MOD_SETUP_ADDONS.md` – zusätzliche Mod-Controller
- `COMPONENTS.md` – OpenComputers-Komponenten
