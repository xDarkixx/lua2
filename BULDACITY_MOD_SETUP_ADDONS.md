# BULDACITY – Zusatz-Setup: Galacticraft, ExtraPlanets, Forestry & Gendustry

Diese Anleitung ergänzt `BULDACITY_SETUP_GUIDE.md` für die vier Mod-Familien.

## 1. Gemeinsamer Ablauf

Für jede Mod-Familie gilt:

1. Mod und benötigte Abhängigkeiten installieren.
2. OpenComputers-PC bauen.
3. direkte OC-Komponente prüfen.
4. falls nötig Adapter direkt neben den Mod-Block setzen.
5. OC-Kabel anschließen.
6. passenden lokalen Controller starten.
7. `Scan`/Komponentensuche ausführen.
8. nur tatsächlich gefundene Komponenten/API verwenden.
9. passenden Network-Controller starten.
10. Zentrale unter `DEVICES` prüfen.

## 2. Galacticraft

Lokaler Controller:
`Galacticraft_Modern.lua`

Network-Controller:
`GalacticraftNetwork_Modern.lua`

Empfohlener Aufbau:

```text
Galacticraft-Gerät
       │
  direkte OC-Komponente
       │
oder Adapter + OC-Kabel
       │
  Controller-PC
       │
 Network Card
       │
 BULDACITY Tier-3
```

Der Controller zeigt nur Komponenten, die zur Laufzeit tatsächlich verfügbar sind.

## 3. ExtraPlanets

Lokaler Controller:
`ExtraPlanets_Modern.lua`

Network-Controller:
`ExtraPlanetsNetwork_Modern.lua`

ExtraPlanets baut auf Galacticraft auf. Daher zuerst die benötigten Galacticraft-Komponenten korrekt installieren und anschließend den ExtraPlanets-Controller prüfen.

## 4. Forestry

Lokaler Controller:
`Forestry_Modern.lua`

Network-Controller:
`ForestryNetwork_Modern.lua`

Der Scan sucht nach tatsächlich verfügbaren Forestry-/Bee-/Apiary-/Farm-Komponenten. Nicht vorhandene APIs werden nicht als funktionierend ausgegeben.

## 5. Gendustry

Lokaler Controller:
`Gendustry_Modern.lua`

Network-Controller:
`GendustryNetwork_Modern.lua`

Gendustry benötigt die passenden Forestry-/bdlib-Abhängigkeiten der verwendeten Installation. Danach gilt derselbe Scan- und Netzwerkablauf.

## 6. Grafik

Die gemeinsamen GUI-Bausteine sind:

```text
BuldacityUI.lua
      │
      └── BuldacityComponentDashboard.lua
              │
              └── generische Mod-Komponenten-GUI
```

Die Oberfläche verwendet BULDACITY-Panels, Statusanzeigen, Buttons, Balken und Touch-Bereiche. Spezial-Controller wie Big Reactors behalten ihre spezialisierte GUI.

## 7. Netzwerk

```text
Galacticraft / ExtraPlanets / Forestry / Gendustry
                         │
                    Network.lua
                         │
                 BULDACITY/2 :4242
                         │
                 Tier-3 BULDACITY
```

## 8. Autostart

Auf einem Client kann `/home/autorun.lua` mit `BuldacityAutoStart.lua` eingerichtet werden.

Beispiele:

```text
ROLE=CLIENT
CLIENT=Galacticraft
```

oder:

```text
ROLE=CLIENT
CLIENT=Forestry
```

## 9. Fehlerbehebung

### Keine Komponente
- `component.list()` ausführen.
- Adapter prüfen.
- OC-Kabel prüfen.
- passenden Driver/Integration prüfen.

### Network-Client fehlt
- Network Card prüfen.
- `Network.lua` vorhanden?
- richtigen Network-Controller gestartet?
- Tier-3 zuerst starten.

### GUI fehlt
- GPU und Screen prüfen.
- lokalen Controller direkt starten.
- BULDACITY-Dateien nach `/home` kopieren.

## 10. Grundregel

**Installieren → Anschließen → Scannen → lokale GUI testen → Netzwerk testen → Zentrale prüfen → Autostart aktivieren.**
