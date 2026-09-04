# lua2

OpenComputers-Lua-Programme für Minecraft 1.7.10 und die jeweils im Script angegebenen Mod-Versionen.

## Controller-Struktur

Die Repository enthält bewusst zwei Controller-Stile:

- **Normal** – die klassischen Controller-Dateien bleiben erhalten.
- **Modern** – die grafisch überarbeiteten `_Modern.lua` Controller bleiben als lokale Desktop-Apps erhalten und werden nicht heimlich verändert.
- **Big Reactors** – `ReactorBigReactors043A_Touch_Responsive.lua` ist der aktuelle Big-Reactors-Controller für Big Reactors 0.4.3A.
- **Network-Controller** – die vorhandenen `*Network*.lua` Programme laufen auf normalen Tier-3-Controller-PCs und stellen die Verbindung zum zentralen Rechner her.

## BULDACITY Desktop 5.0

`BuldacityOS_Tier3.lua` ist der **einzige zentrale BULDACITY-Server**. Zusammen mit `Network.lua` bildet er den Tier-3-Netzwerkkern.

Der Desktop ist als echter OpenComputers-Arbeitsplatz aufgebaut:

- HOME mit Live-Flotte und Systemlog
- NETWORK mit Heartbeat-/Link-Monitor
- DEVICES mit Auswahl der normalen Controller-PCs
- APPS mit lokaler Modern-App-Bibliothek
- DISKS mit echten gemounteten Dateisystemen, Label, Kapazität, Belegung, frei und Read-only-Status
- SYSTEM mit echten Computerwerten und Live-Gauges
- REMOTE als Live-Remote-PC mit Bildschirmübertragung
- Tastatur-Weiterleitung inklusive `key_down` und `key_up`
- Touch- und Scroll-Weiterleitung
- automatische Controller-Erkennung und Heartbeats
- einheitliches Desktop-Design mit Panels, Statusfarben und Live-Anzeigen

Die Anzeige ist nicht nur ein einfacher Balken: Speicher- und Systemwerte werden als konkrete Werte mit Einheiten und Status dargestellt; bei Systemmetriken gibt es zusätzlich Live-Gauges.

## Netzwerkarchitektur

Es gibt **nur einen Server**:

```text
                  ┌──────────────────────────────┐
                  │ Tier-3 OpenComputers PC      │
                  │ BuldacityOS_Tier3.lua        │
                  │ + Network.lua                │
                  │ CENTRAL BULDACITY SERVER     │
                  └──────────────┬───────────────┘
                                 │ BULDACITY/2 :4242
              ┌──────────────────┼──────────────────┐
              │                  │                  │
      ┌───────▼───────┐  ┌──────▼────────┐  ┌──────▼────────┐
      │ Normal PC     │  │ Normal PC     │  │ Normal PC     │
      │ AE2 Network   │  │ Mekanism Net  │  │ Reactor Net   │
      │ Client        │  │ Client        │  │ Client        │
      └───────────────┘  └───────────────┘  └───────────────┘
```

Alle Mod-Controller bleiben auf ihren normalen OpenComputers-PCs. Der Tier-3-Desktop sammelt deren Status und kann ihre Bildschirme sowie Eingaben remote bedienen. Es werden **keine zusätzlichen BULDACITY-Server pro Mod** benötigt.

## Netzwerkstandard

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- Protokoll `BULDACITY/2`
- Port `4242`
- Tier-3 als zentraler Desktop-/Netzwerk-Hub
- normale OpenComputers-PCs als Controller-Clients
- automatische Discovery und Heartbeat
- Remote-Screen sowie Tastatur-, Touch- und Scroll-Weiterleitung
- keine Whitelist und keine UUID-Rollenverwaltung

## Big Reactors 0.4.3A

`ReactorBigReactors043A_Touch_Responsive.lua` ist der aktuelle Big-Reactors-Touch-Controller.

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
4. Auf dem zentralen Tier-3-Hauptrechner `BuldacityOS_Tier3.lua` starten.
5. Auf normalen Controller-PCs den passenden `*Network*.lua` Controller starten. Dieser verwendet `Network.lua` für BULDACITY/2.
6. Die `_Modern.lua` Dateien bleiben lokale Apps. Der zentrale Desktop zeigt sie in **APPS** an, ohne sie in den Netzwerkkern einzubauen.
7. Für Big Reactors direkt `ReactorBigReactors043A_Touch_Responsive.lua` starten oder den passenden Network-Wrapper auf einem normalen Controller-PC verwenden.

## Erster Netzwerktest

Zuerst den Tier-3-Desktop starten und danach einen Network-Controller auf einem normalen PC. Der Client sollte automatisch unter **DEVICES** erscheinen. Anschließend **REMOTE** öffnen und den Controller auswählen.

Im Remote-Modus wird der echte Zeicheninhalt des Ziel-GPUs übertragen. Eingaben können vom zentralen Bildschirm an den normalen Controller-PC zurückgesendet werden. Damit verhält sich der Desktop für die unterstützten Controller wie eine Remote-Konsole bzw. ein Remote-PC-Arbeitsplatz.

Die Netzwerkverbindung benötigt nur ein Modem bzw. eine Wireless Network Card auf den beteiligten OpenComputers-PCs. Port `4242` und Protokoll `BULDACITY/2` werden automatisch verwendet.

## OpenComputers Speicher

OpenComputers stellt gemountete Dateisysteme über die Filesystem-API bereit. Der Desktop nutzt diese Mounts für die **DISKS**-Ansicht und zeigt reale Speicherinformationen an, statt einen künstlichen Fortschrittsbalken zu simulieren.

## Dokumentation

- `BULDACITY_SETUP_GUIDE.md` – Grundaufbau
- `BULDACITY_NETWORK.md` – aktuelles BULDACITY/2-Netzwerk
- `BULDACITY_WIRELESS_SETUP.md` – Wireless, Komponenten und Fehlerbehebung
- `BULDACITY_MOD_SETUP_ADDONS.md` – zusätzliche Mod-Controller
- `COMPONENTS.md` – OpenComputers-Komponenten
