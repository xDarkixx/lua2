# BULDACITY Tier-3 / OpenComputers Netzwerk

## Zielaufbau

Dieses Dokument beschreibt den aktuellen BULDACITY-Netzwerkaufbau für Minecraft 1.7.10 mit OpenComputers:

- Forge 10.13.4.1614
- Tier-3 Hauptserver mit `BuldacityOS_Tier3.lua`
- Tier-2/3 Maschinen-Controller
- Wireless Network Card oder kompatible Network Card
- OC-Kabel für lokale Maschinenverbindungen
- Funkverbindung zwischen Zentrale und Clients
- BULDACITY/2 auf Modem-Port `4242`
- zentrale Desktop-Oberfläche mit Apps
- Geräteverwaltung und Live-Remote-Oberflächen
- keine Whitelist erforderlich

Die Netzwerkverbindung und die Maschinenverbindung bleiben getrennt: Funk überträgt BULDACITY-Daten und die Controller-Oberflächen, OC-Kabel verbinden einen Controller lokal mit den vorgesehenen Maschinen-/Adapter-Komponenten.

---

## 1. Benötigte Hardware

### Tier-3 Hauptserver

- Tier-3 Computer
- CPU/RAM/Speicher passend zum Computer
- GPU
- Screen
- Keyboard
- Wireless Network Card

### Maschinen-Controller

Pro überwachte Maschine bzw. Maschinengruppe:

- Tier-2 oder Tier-3 Computer
- GPU + Screen für eine lokale Oberfläche
- Keyboard, wenn lokale Bedienung benötigt wird
- Wireless Network Card
- benötigte OpenComputers-Adapter bzw. kompatible Komponenten
- OC-Kabel
- passende Maschine bzw. Mod-Komponente

### Wichtig

Nicht jede Minecraft-Maschine wird direkt mit einem beliebigen OC-Adapter verbunden. Der Controller muss die für den jeweiligen Mod tatsächlich unterstützte OpenComputers-Komponente verwenden.

---

# 2. Tier-3-Zentrale

Die Zentrale verwendet jetzt ausschließlich:

```text
BuldacityOS_Tier3.lua
```

Der alte `BuldacityDesktop_Tier3.lua` wird nicht mehr verwendet.

```text
                    ┌─────────────────────┐
                    │       SCREEN        │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │         GPU          │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │      TIER-3 PC      │
                    │   BULDACITY OS      │
                    │ CPU / RAM / Storage │
                    └───────┬───────┬─────┘
                            │       │
                       Keyboard    │
                                    │
                         ┌──────────▼──────────┐
                         │ Wireless Network    │
                         │ Card / Network Card │
                         └─────────────────────┘
```

### Desktop-Apps

Der Tier-3-Desktop besitzt unter anderem:

- HOME
- NETWORK
- DEVICES
- CONTROLLER APPS
- REMOTE INTERFACE
- TERMINAL
- SYSTEM MONITOR

Unter `DEVICES` werden die gefundenen Controller angezeigt. Über `REMOTE` kann die Oberfläche eines ausgewählten Controllers zentral betrachtet und bedient werden.

---

# 3. Netzwerkaufbau

```text
                         MINECRAFT-WELT

                  ┌────────────────────────┐
                  │     TIER-3 ZENTRALE    │
                  │    BULDACITY OS        │
                  │  GPU + Screen + KB      │
                  │  Wireless Network Card │
                  │  BULDACITY/2 : 4242    │
                  └───────────┬────────────┘
                              ))))
                           WIRELESS
                              ))))
             ┌────────────────┼────────────────┐
             ))))             ))))             ))))
       ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
       │ OC CLIENT 01│  │ OC CLIENT 02│  │ OC CLIENT 03│
       │ Controller  │  │ Controller  │  │ Controller  │
       └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
              │                │                │
              ▼                ▼                ▼
           REAKTOR          DIESEL             AE2
           CONTROL          CONTROL           CONTROL
```

`))))` bedeutet Funk. Zwischen Wireless-Clients und Tier-3-Zentrale ist keine physische Netzwerkleitung erforderlich.

---

# 4. Live-Oberfläche der Controller

Die Controller können ihre aktuelle OpenComputers-GPU-Oberfläche an den Tier-3-Desktop übertragen.

Ablauf:

```text
┌────────────────┐       BULDACITY/2       ┌──────────────────┐
│ Tier-2/3       │  ====================>  │ Tier-3 Desktop   │
│ Controller     │      SCREEN_ROW         │ Remote Interface │
│ GPU + Screen   │  <====================  │                 │
└────────────────┘     INPUT / PING        └──────────────────┘
```

Der Client überträgt:

- `SCREEN_BEGIN`
- `SCREEN_ROW`
- `SCREEN_END`

Der Tier-3-Desktop baut daraus die Controller-Oberfläche auf.

Zusätzlich können Eingaben übertragen werden:

- Tastatur `key_down`
- Tastatur `key_up`
- Touch
- Scroll

Damit kann die Zentrale die laufende Controller-Oberfläche ansehen und Eingaben an den ausgewählten Controller weiterreichen.

### Hinweis

Die Übertragung erfolgt als GPU-Zeichen-/Farbzellen und nicht als Minecraft-Pixel-Video. Dadurch bleibt die Lösung für OpenComputers geeignet und benötigt keinen externen VNC/RDP-Dienst.

---

# 5. Verkabelung eines Maschinen-Controllers

```text
 ┌─────────────────────┐
 │   OC CONTROLLER PC  │
 │                     │
 │ Tier-2 / Tier-3     │
 │ Wireless Network    │
 │ Card                │
 └──────────┬──────────┘
            │
          OC-Kabel
            │
            ▼
 ┌─────────────────────┐
 │ OC Adapter /        │
 │ passende Komponente │
 └──────────┬──────────┘
            │
            ▼
 ┌─────────────────────┐
 │ Maschine / Anlage   │
 │ Reaktor / Diesel /  │
 │ AE2 / IC2 / etc.    │
 └─────────────────────┘

             ))))
          WIRELESS
             ))))
             ▼
       TIER-3 ZENTRALE
```

---

# 6. Software

## Tier-3

Mindestens:

```text
BuldacityWireless.lua
BuldacityNetworkClient.lua
BuldacityOS_Tier3.lua
```

Der Tier-3-Desktop startet:

```text
BuldacityOS_Tier3.lua
```

## Controller

Mindestens:

```text
BuldacityWireless.lua
BuldacityNetworkClient.lua
BuldacityControllerLauncher.lua
<Controller-Lua-Datei>
```

Start:

```text
BuldacityControllerLauncher.lua
```

---

# 7. Netzwerkstandard

```text
Protokoll: BULDACITY/2
Port:      4242
Transport: OpenComputers modem
```

Verwendete OpenComputers-Funktionen:

- `component.list("modem")`
- `modem.open(4242)`
- `modem.broadcast(...)`
- `modem.send(...)`
- `modem_message`

Es wird keine künstliche TCP/IP-Schicht benötigt.

---

# 8. Controller-Apps

Der zentrale Desktop kann die vorhandenen BULDACITY-Controller verwalten, unter anderem:

- AE2
- Diesel / Immersive Engineering
- Mekanism
- Thermal
- ProjectE
- RFTools
- SGCraft
- Reactor / Big Reactors
- RotaryCraft
- Thermal Expansion
- PneumaticCraft
- LogisticsPipes
- Immersive Engineering
- Immersive Integration
- Immersive Railroading
- IndustrialCraft 2
- Galacticraft
- ExtraPlanets
- Forestry
- Gendustry

Die App-Liste prüft, ob die jeweilige Lua-Datei auf dem Tier-3-System vorhanden ist. Die eigentliche Maschinensteuerung läuft weiterhin auf dem jeweiligen Controller.

---

# 9. Bedienung Tier 3

```text
1 = HOME
2 = NETWORK
3 = DEVICES
4 = CONTROLLER APPS
5 = REMOTE
6 = TERMINAL
7 = SYSTEM
Q = Desktop beenden
R = Netzwerk-Ankündigung / Remote-Refresh
Pfeil hoch/runter = Gerät auswählen
ENTER = ausgewählten Controller öffnen
```

In `REMOTE` werden Tastatur-, Touch- und Scroll-Eingaben an den ausgewählten Controller weitergegeben.

---

# 10. Testreihenfolge

### Hauptserver

- [ ] Minecraft startet
- [ ] Forge 10.13.4.1614 geladen
- [ ] OpenComputers geladen
- [ ] Tier-3 Computer funktioniert
- [ ] GPU funktioniert
- [ ] Screen funktioniert
- [ ] Wireless Network Card wird erkannt
- [ ] `BuldacityOS_Tier3.lua` startet

### Netzwerk

- [ ] Port `4242` geöffnet
- [ ] `BULDACITY/2` aktiv
- [ ] Client sendet HELLO
- [ ] Server erkennt Client
- [ ] HEARTBEAT funktioniert
- [ ] PING/PONG funktioniert

### Remote-Oberfläche

- [ ] Controller erscheint unter DEVICES
- [ ] Controller steht auf ONLINE
- [ ] REMOTE öffnen
- [ ] `SCREEN_REQUEST` wird gesendet
- [ ] `SCREEN_BEGIN` kommt an
- [ ] `SCREEN_ROW` kommt an
- [ ] `SCREEN_END` kommt an
- [ ] Oberfläche wird auf dem Tier-3-Screen dargestellt
- [ ] Tastatur funktioniert
- [ ] Touch funktioniert
- [ ] Scroll funktioniert

### Maschine

- [ ] OC-Kabel korrekt angeschlossen
- [ ] Adapter/Komponente wird erkannt
- [ ] Controller liest Maschinendaten
- [ ] Steuerbefehle funktionieren
- [ ] Controller bleibt online

---

# 11. Fehlerdiagnose

## Controller wird nicht gefunden

1. Wireless Network Card prüfen.
2. Funkbereich prüfen.
3. Port `4242` prüfen.
4. `BULDACITY/2` prüfen.
5. Client neu starten.
6. `R` auf der Zentrale ausführen.

## Controller ist online, aber Oberfläche bleibt leer

1. Controller muss eine GPU besitzen.
2. Screen muss funktionieren.
3. `BuldacityNetworkClient.lua` muss aktuell sein.
4. Prüfen, ob der Controller `SCREEN_REQUEST` empfängt.
5. Controller neu starten.
6. REMOTE erneut öffnen.

## Oberfläche wird angezeigt, aber Eingaben funktionieren nicht

1. richtigen Controller auswählen.
2. REMOTE öffnen.
3. Netzwerkverbindung prüfen.
4. `BuldacityNetworkClient.lua` prüfen.
5. lokale Controller-Events prüfen.

## Funk funktioniert, aber Maschine nicht

Dann ist das Netzwerk wahrscheinlich in Ordnung. Die lokale OC-Maschinenverbindung muss separat geprüft werden.

---

# 12. Aufbauprinzip

```text
                    BULDACITY OS
                         │
                  ┌──────▼──────┐
                  │ TIER-3      │
                  │ ZENTRALE    │
                  │ Desktop     │
                  └──────┬──────┘
                         │
                      WIRELESS
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
    Controller       Controller       Controller
    Reactor          Diesel           AE2
        │                │                │
     OC-Kabel         OC-Kabel         OC-Kabel
        │                │                │
     Maschine         Maschine         Lager
```

**Funk = BULDACITY-Netzwerk + Remote-Oberfläche.**

**OC-Kabel = lokale Maschinen-/Komponentenverbindung.**

---

# 13. Wichtige aktuelle Dateistruktur

```text
BuldacityOS_Tier3.lua          <- zentrale Desktop-Oberfläche
BuldacityWireless.lua          <- gemeinsamer Netzwerktransport
BuldacityNetworkClient.lua     <- Client + Screen-Streaming
BuldacityNetworkLauncher.lua   <- Netzwerkstart
BuldacityControllerLauncher.lua<- Controller-Auswahl
BuldacityNetworkStatus.lua     <- Diagnose
BuldacityNetworkInstall.lua    <- Installation/Prüfung
```

Der alte `BuldacityDesktop_Tier3.lua` wird nicht mehr benötigt und wurde entfernt, damit keine doppelte Tier-3-Desktop-Implementierung vorhanden ist.

---

# 14. Empfohlene Installation

1. Minecraft + Forge installieren.
2. OpenComputers installieren.
3. Tier-3-Zentrale aufbauen.
4. GPU/Screen/Keyboard anschließen.
5. Wireless Network Card einsetzen.
6. Buldacity-Dateien installieren.
7. `BuldacityOS_Tier3.lua` starten.
8. Einen einzigen Test-Controller aufbauen.
9. Wireless Network Card einsetzen.
10. OC-Kabel zum Maschinen-Adapter verlegen.
11. `BuldacityControllerLauncher.lua` starten.
12. Controller an der Zentrale prüfen.
13. `DEVICES` öffnen.
14. Controller auswählen.
15. `REMOTE` öffnen und Live-Oberfläche prüfen.
16. Maschine testen.
17. Erst danach weitere Controller hinzufügen.

So kann jeder Abschnitt einzeln geprüft werden und Fehler lassen sich eindeutig auf Funknetz, Remote-Übertragung oder lokale Maschinen-/Komponentenverbindung eingrenzen.
