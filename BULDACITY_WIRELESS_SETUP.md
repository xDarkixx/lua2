# BULDACITY Tier-3 / OpenComputers Netzwerk

## Zielaufbau

Dieses Dokument beschreibt den kompletten Aufbau des BULDACITY-Netzwerks für Minecraft 1.7.10 mit OpenComputers:

- Forge 10.13.4.1614
- Tier-3 Hauptserver
- Tier-2/3 Maschinen-Controller
- Wireless Network Card
- OC-Kabel für lokale Maschinenverbindungen
- Funkverbindung zwischen Zentrale und Clients
- BULDACITY/2 auf Modem-Port `4242`
- keine Whitelist erforderlich

Die Netzwerkverbindung und die Maschinenverbindung sind getrennt: Funk überträgt BULDACITY-Daten, OC-Kabel verbinden einen Controller lokal mit den dafür vorgesehenen Maschinen-/Adapter-Komponenten.

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
- GPU + Screen, wenn eine lokale Anzeige benötigt wird
- Keyboard, wenn lokale Bedienung benötigt wird
- Wireless Network Card
- benötigte OpenComputers-Adapter bzw. kompatible Komponenten
- OC-Kabel
- passende Maschine bzw. Mod-Komponente

### Wichtig

Nicht jede Minecraft-Maschine wird direkt mit einem beliebigen OC-Adapter verbunden. Der Controller muss die für den jeweiligen Mod tatsächlich unterstützte OpenComputers-Komponente verwenden.

---

# 2. Verkabelung der Tier-3-Zentrale

Der Hauptserver besteht aus Computer, GPU, Screen, Keyboard und Wireless Network Card.

```text
                    ┌─────────────────────┐
                    │       SCREEN        │
                    └──────────┬──────────┘
                               │
                         Bildschirm
                               │
                    ┌──────────▼──────────┐
                    │         GPU          │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │      TIER-3 PC      │
                    │                     │
                    │ CPU / RAM / Speicher│
                    └───────┬───────┬─────┘
                            │       │
                       Keyboard    │
                                    │
                         ┌──────────▼──────────┐
                         │ Wireless Network    │
                         │ Card / Network Card │
                         └─────────────────────┘
```

### Physischer Aufbau

1. Tier-3 Computer platzieren.
2. GPU einsetzen.
3. Screen anschließen.
4. Keyboard anschließen.
5. Wireless Network Card einsetzen.
6. Computer starten.
7. Prüfen, ob der Modem-/Wireless-Anschluss erkannt wird.

Die Wireless Network Card benötigt kein OC-Kabel zur Netzwerkzentrale. Sie arbeitet über das OpenComputers-Modem-Interface.

---

# 3. Netzwerkaufbau

Die zentrale Funkverbindung sieht so aus:

```text
                         MINECRAFT-WELT

                  ┌────────────────────────┐
                  │     TIER-3 ZENTRALE    │
                  │                        │
                  │ Computer + GPU + Screen│
                  │ Wireless Network Card  │
                  │ BULDACITY/2 : 4242     │
                  └───────────┬────────────┘
                              ))))
                           WIRELESS
                              ))))
             ┌────────────────┼────────────────┐
             ))))             ))))             ))))
       ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
       │ OC CLIENT 01│  │ OC CLIENT 02│  │ OC CLIENT 03│
       │ Wireless    │  │ Wireless    │  │ Wireless    │
       │ Network Card│  │ Network Card │  │ Network Card│
       └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
              │                │                │
              ▼                ▼                ▼
           REAKTOR          DIESEL             AE2
           CONTROL          CONTROL           CONTROL
```

`))))` bedeutet Funk. Es gibt keine physische Netzwerkleitung zwischen den einzelnen Wireless-Clients und der Tier-3-Zentrale.

---

# 4. Verkabelung eines Maschinen-Controllers

Ein Maschinen-Controller hat zwei getrennte Aufgaben:

1. lokale Verbindung zur Maschine
2. Funkverbindung zur BULDACITY-Zentrale

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
 │                     │
 │ Reaktor / Diesel /  │
 │ AE2 / IC2 / etc.    │
 └─────────────────────┘

             ))))
          WIRELESS
             ))))
             ▼
       TIER-3 ZENTRALE
```

### Kabelführung

- OC-Kabel möglichst kurz und übersichtlich verlegen.
- Kabel nicht unnötig über große Distanzen führen.
- Controller möglichst nahe an der zu steuernden Maschine platzieren.
- Wireless Network Card im Controller verwenden, damit die BULDACITY-Kommunikation unabhängig von der Maschinenverkabelung bleibt.

---

# 5. Große Anlage / Maschinenhalle

Für eine größere Basis empfiehlt sich eine sternförmige Struktur.

```text
                         ┌────────────────┐
                         │ TIER-3 SERVER  │
                         │ ZENTRALE       │
                         │ Port 4242      │
                         └───────┬────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
       WIRELESS               WIRELESS               WIRELESS
          │                      │                      │
          ▼                      ▼                      ▼
   ┌────────────┐         ┌────────────┐         ┌────────────┐
   │ ENERGIE    │         │ MASCHINEN  │         │ LAGER      │
   │ CONTROLLER │         │ CONTROLLER │         │ CONTROLLER │
   └─────┬──────┘         └─────┬──────┘         └─────┬──────┘
         │                      │                      │
       OC-Kabel               OC-Kabel               OC-Kabel
         │                      │                      │
    ┌────┼────┐             ┌───┼────┐             ┌───┼────┐
    ▼    ▼    ▼             ▼   ▼    ▼             ▼   ▼    ▼
 Reactor Diesel IC2       Mekanism Thermal IE/Rotary AE2  Storage
```

So kann jeder Bereich seinen eigenen Controller bekommen, während der Tier-3-Server als zentrale Bedienoberfläche dient.

---

# 6. Empfohlene physische Raumaufteilung

```text
┌───────────────────────────────────────────────────────────┐
│                     HAUPTZENTRALE                         │
│                                                           │
│   ┌──────────────┐       ┌──────────────────────────┐     │
│   │ Tier-3 PC    │       │ Bildschirm / Bedienplatz │     │
│   │ Wireless     │──────▶│ Buldacity Desktop        │     │
│   └──────────────┘       └──────────────────────────┘     │
│                                                           │
└───────────────────────────────┬───────────────────────────┘
                                │
                           WIRELESS ))))
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ ENERGIEHALLE    │   │ MASCHINENHALLE  │   │ LAGER           │
│                 │   │                 │   │                 │
│ OC Controller   │   │ OC Controller   │   │ OC Controller   │
│      │          │   │      │          │   │      │          │
│    OC-Kabel     │   │    OC-Kabel     │   │    OC-Kabel     │
│      ▼          │   │      ▼          │   │      ▼          │
│ Generatoren     │   │ Maschinen       │   │ AE2/Storage     │
│ Reactor         │   │ RotaryCraft     │   │ Systeme         │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

---

# 7. Software auf dem Hauptserver

Die Dateien auf den OpenComputers-Speicher kopieren:

- `BuldacityWireless.lua`
- `BuldacityDesktop_Tier3.lua`
- bei Bedarf weitere BULDACITY-Dateien

Start:

```text
BuldacityDesktop_Tier3.lua
```

Der Desktop initialisiert das Netzwerk über die OpenComputers-Modem-Komponente.

---

# 8. Software auf einem Maschinen-Controller

Auf jeden Controller kommen mindestens:

- `BuldacityWireless.lua`
- `BuldacityNetworkClient.lua`
- `BuldacityControllerLauncher.lua`
- das benötigte Controller-Skript

Start über:

```text
BuldacityControllerLauncher.lua
```

Der Controller verbindet sich anschließend drahtlos mit der BULDACITY-Zentrale.

---

# 9. Netzwerkstandard

```text
Protokoll: BULDACITY/2
Port:      4242
Transport: OpenComputers modem
```

Verwendet werden die echten OpenComputers-Funktionen:

- `component.list("modem")`
- `modem.open(4242)`
- `modem.broadcast(...)`
- `modem.send(...)`
- `modem_message`

Es wird keine künstliche TCP/IP-Schicht benötigt.

---

# 10. Testaufbau

Zuerst nur einen Controller anschließen.

```text
       TIER-3 SERVER
            │
         WIRELESS
            │
            ▼
       TEST CLIENT
            │
         OC-Kabel
            │
            ▼
        TEST-MASCHINE
```

Erst wenn dieser Aufbau funktioniert, weitere Controller hinzufügen.

---

# 11. Testreihenfolge

### Hauptserver

- [ ] Minecraft startet
- [ ] Forge 10.13.4.1614 geladen
- [ ] OpenComputers geladen
- [ ] Tier-3 Computer funktioniert
- [ ] GPU funktioniert
- [ ] Screen funktioniert
- [ ] Wireless Network Card wird erkannt

### Netzwerk

- [ ] Port `4242` geöffnet
- [ ] `BULDACITY/2` aktiv
- [ ] Client sendet HELLO
- [ ] Server erkennt Client
- [ ] HEARTBEAT funktioniert
- [ ] PING/PONG funktioniert

### Maschine

- [ ] OC-Kabel korrekt angeschlossen
- [ ] Adapter/Komponente wird erkannt
- [ ] Controller liest Maschinendaten
- [ ] Steuerbefehle funktionieren
- [ ] Controller bleibt online

### Zentrale

- [ ] Client erscheint in DEVICES
- [ ] Online/Offline-Status funktioniert
- [ ] Ping funktioniert
- [ ] Rescan funktioniert
- [ ] Remote-Eingaben funktionieren

---

# 12. Fehlerdiagnose

## Client wird nicht gefunden

1. Wireless Network Card prüfen.
2. Prüfen, ob beide Computer im Funkbereich sind.
3. Port `4242` prüfen.
4. `BULDACITY/2` prüfen.
5. Client neu starten.
6. Server-Rescan ausführen.

## Maschine wird nicht erkannt

1. OC-Kabel prüfen.
2. Adapter prüfen.
3. richtige Komponente für den verwendeten Mod prüfen.
4. Controller neu starten.
5. lokale Controller-Ausgabe prüfen.

## Funk funktioniert, aber Maschine nicht

Dann ist das Netzwerk wahrscheinlich in Ordnung. Die lokale OC-Maschinenverbindung muss separat geprüft werden.

## Maschine funktioniert, aber Server sieht Controller nicht

Dann zuerst die Wireless-Verbindung und den BULDACITY-Client prüfen.

---

# 13. Aufbauprinzip

Die wichtigste Regel ist:

```text
                    BULDACITY
                       │
                ┌──────▼──────┐
                │ TIER-3      │
                │ ZENTRALE    │
                └──────┬──────┘
                       │
                    WIRELESS
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
    Controller     Controller     Controller
        │              │              │
     OC-Kabel       OC-Kabel       OC-Kabel
        │              │              │
     Maschine       Maschine       Maschine
```

**Funk = BULDACITY-Netzwerk.**

**OC-Kabel = lokale Maschinen-/Komponentenverbindung.**

Damit bleibt der Aufbau sauber, erweiterbar und leicht zu testen.

---

# 14. Sicherheit / Zugriff

Dieses Setup verwendet bewusst **keine Whitelist**. Jeder kompatible BULDACITY-Client kann sich grundsätzlich am Netzwerk melden.

Das bedeutet: In einer gemeinsam genutzten oder nicht vertrauenswürdigen Welt sollte die Steuerung nicht ungeschützt erreichbar sein. Für eine private Testwelt ist der offene Aufbau dagegen einfach und praktisch.

---

# 15. Empfohlene Reihenfolge beim echten Aufbau

1. Minecraft + Forge installieren.
2. OpenComputers installieren.
3. Tier-3-Zentrale aufbauen.
4. Screen/GPU/Keyboard anschließen.
5. Wireless Network Card einsetzen.
6. `BuldacityWireless.lua` installieren.
7. `BuldacityDesktop_Tier3.lua` starten.
8. Einen einzigen Test-Controller aufbauen.
9. Wireless Network Card einsetzen.
10. OC-Kabel zum Maschinen-Adapter verlegen.
11. `BuldacityNetworkClient.lua` starten.
12. Controller an der Zentrale prüfen.
13. Maschine testen.
14. Erst danach weitere Controller hinzufügen.
15. Am Ende alle Bereiche der Anlage verbinden.

So lässt sich jeder Abschnitt einzeln testen und ein Fehler kann eindeutig auf **Funknetz**, **OC-Kabel/Adapter** oder **Maschinen-Controller** eingegrenzt werden.
