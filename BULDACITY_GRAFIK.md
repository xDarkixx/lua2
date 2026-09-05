# BULDACITY v10.2 – Grafiksystem

## Ziel

BULDACITY nutzt die echte OpenComputers-GPU als gemeinsame grafische Schicht für Zentrale und Mod-Controller.

## Grafische Bausteine

- GPU-Flächen mit `gpu.fill`
- Vorder-/Hintergrundfarben
- Panels und Karten
- horizontale und vertikale Balken
- Status-LEDs und Badges
- Buttons und Touch-Zonen
- Gauges
- Sparklines
- Live-Diagramme
- Pixel-Icons
- klickbare Client-/Controller-Zeilen
- Remote-Screen-Darstellung
- auflösungsgerechte Layouts

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
UI.statusLed()
UI.badge()
UI.sparkline()
UI.graph()
UI.icon()
UI.card()
```

`UI.statusLed` ist als kompatibler Alias für die LED-Funktion vorhanden.

## Desktop-Seiten v10.2

```text
DESKTOP
APPS
NETWORK
DEVICES
REMOTE
REACTOR
```

Die Desktop-Oberfläche verwendet echte Button-/Touch-Zonen für Clients und Controller.

Beispiel-Navigation:

```text
DESKTOP → Client anklicken → DEVICES
APPS → Controller anklicken → REMOTE
DEVICES → Client anklicken → Auswahl
REMOTE → REQUEST SCREEN
```

Auch Component-Einträge werden als UI-Zonen dargestellt.

## Netzwerk grafisch

Die NETWORK-Seite zeigt reale, von `Network.lua` gemeldete Zustände:

```text
Server-Modem-Anzahl
Wireless-Anzahl
Client-Anzahl
Signalstärke
Port 4242
Modem-Adresse
Wired/Wireless
Relay/AP
Scan-Status
Latency / PING-PONG
```

## Remote-Screen

Die zentrale Oberfläche kann einen Client-Screen über `SCREEN_REQUEST` anfordern. Die Darstellung basiert auf den übertragenen:

```text
SCREEN_BEGIN
SCREEN_ROW
SCREEN_END
```

Dafür benötigt der Client GPU + Screen.

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

## Auflösung

Für die größte Oberfläche sollte ein Tier-3-GPU/Screen-System verwendet werden. Die Anwendung liest die vorhandene Auflösung und passt das Layout daran an.

Bei kleineren Screens wird die Oberfläche kompakter; die Funktionen bleiben erhalten.

## Für alle Controller

```lua
local UI=require("BuldacityUI")
```

Die Controller verwenden `/home` als Arbeitsverzeichnis bzw. Paketpfad.

## Keine falschen Versprechen

OpenComputers ist eine Zeichen-/GPU-Umgebung. BULDACITY simuliert Fenster, Karten, Anzeigen und Icons mit den verfügbaren GPU-Operationen. Eine moderne Shader- oder 3D-Grafikengine wird nicht vorausgesetzt.
