# BULDACITY v9 – Grafiksystem

## Ziel

BULDACITY nutzt die OpenComputers-GPU als gemeinsame grafische Schicht für Zentrale und Mod-Controller.

## Grafische Bausteine

- farbige Flächen mit `gpu.fill`
- Vorder-/Hintergrundfarben
- Panels und Karten
- horizontale Fortschrittsbalken
- große mehrzeilige Balken
- vertikale Balken
- Status-LEDs
- Buttons und Touch-Zonen
- Messanzeigen
- Sparklines
- Live-Diagramme
- Pixel-Icons
- Remote-Screen-Darstellung

## Gemeinsame Bibliothek

```text
/home/BuldacityUI.lua
```

Die wichtigsten Funktionen:

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

`UI.icon()` zeichnet kleine Pixel-Symbole direkt mit GPU-Flächen. Unterstützt sind unter anderem:

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

Für die größte Oberfläche sollte ein Tier-3-GPU/Screen-System verwendet werden. Die Anwendung fragt die vorhandene Auflösung ab und passt die Oberfläche daran an.

Bei kleineren Screens wird die Oberfläche kompakter; die Funktionen bleiben erhalten.

## Für alle Controller

Die Bibliothek liegt zentral im Repository und kann von jedem Controller geladen werden:

```lua
local UI=require("BuldacityUI")
```

Der Controller muss `/home` als Arbeitsverzeichnis bzw. als `package.path` verwenden. Die aktuellen BULDACITY-Wrapper setzen dies für den gemeinsamen Netzwerkbetrieb voraus.

## Keine falschen Versprechen

OpenComputers ist eine Zeichen-/GPU-Umgebung. BULDACITY simuliert deshalb Fenster, Karten, Anzeigen und Icons mit den verfügbaren GPU-Operationen. Eine moderne Pixel-Grafik-Engine oder Shader-Pipeline wird nicht vorausgesetzt.
