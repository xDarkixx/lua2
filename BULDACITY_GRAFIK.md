# BULDACITY v10 – Grafiksystem

## Ziel

BULDACITY nutzt die echte OpenComputers-GPU als gemeinsame grafische Schicht für Zentrale und Mod-Controller.

## Grafische Bausteine

- farbige GPU-Flächen mit `gpu.fill`
- Vorder-/Hintergrundfarben
- Panels und Karten
- horizontale und vertikale Balken
- Status-LEDs
- Buttons und Touch-Zonen
- Gauges
- Sparklines
- Live-Diagramme
- Pixel-Icons
- Remote-Screen-Darstellung
- resolution-aware Layouts

## Gemeinsame Bibliothek

```text
/home/BuldacityUI.lua
```

Wichtige Funktionen:

```text
UI.panel()
UI.button()
UI.bar()
UI.bar2()
UI.vbar()
UI.gauge()
UI.led()
UI.badge()
UI.sparkline()
UI.graph()
UI.icon()
UI.card()
```

## Desktop-Seiten

Die zentrale BULDACITY-Oberfläche enthält:

```text
DESKTOP
APPS
NETWORK
DEVICES
REMOTE
REACTOR
```

Die NETWORK-Seite ist speziell für die neue Multi-Modem-Diagnose ausgelegt und zeigt unter anderem:

```text
Server-Modem-Anzahl
Wireless-Anzahl
Signalstärke
Port 4242
Modem-Adresse
Wired/Wireless
Relay/AP
Scan-Status
Client-Modemstatus
```

## Beispiel

```lua
local UI=require("BuldacityUI")
UI.clear()
UI.header("POWER PLANT","LIVE GPU DASHBOARD",UI.C.orange)
UI.card(2,6,30,7,"power","POWER","8.2 kRF/t",82,UI.C.orange)
UI.card(34,6,30,7,"fluid","FUEL","64 %",64,UI.C.green)
UI.panel(2,15,62,10,"LIVE POWER",UI.C.cyan)
UI.graph(5,18,56,6,{10,20,18,35,31,52,70,64,82},UI.C.orange)
UI.statusLine("BULDACITY GPU ONLINE",UI.C.green)
```

## Icons

`UI.icon()` zeichnet Pixel-Symbole direkt mit GPU-Flächen. Unterstützt sind unter anderem:

```text
power / energy
network / modem
computer / pc
reactor
gear / machine
disk / storage
printer
fluid / tank
```

## Maximale Darstellung

Für die größte Oberfläche sollte ein Tier-3-GPU/Screen-System verwendet werden. Die Anwendung fragt die vorhandene Auflösung ab und passt das Layout daran an.

Bei kleineren Screens wird die Oberfläche kompakter; die Funktionen bleiben erhalten.

## Für alle Controller

```lua
local UI=require("BuldacityUI")
```

Die Controller müssen `/home` als Arbeitsverzeichnis bzw. als `package.path` verwenden.

## Netzwerk-Diagnose grafisch

Die zentrale UI liest die Netzwerkdaten aus `Network.lua` und stellt echte Hardwarezustände dar. Dazu gehören Modem-Anzahl, Modem-Adressen, Wireless-Status, Signalstärke, Port, Relay/AP und Scan-Stufe.

Damit ist die Anzeige nicht nur eine statische Grafik, sondern eine Darstellung der tatsächlich gemeldeten OpenComputers-Komponenten.

## Keine falschen Versprechen

OpenComputers ist eine Zeichen-/GPU-Umgebung. BULDACITY simuliert deshalb Fenster, Karten, Anzeigen und Icons mit den verfügbaren GPU-Operationen. Eine moderne Pixel-Grafik-Engine oder Shader-Pipeline wird nicht vorausgesetzt.
