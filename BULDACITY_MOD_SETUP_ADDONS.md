# Buldacity – Zusatz-Setup: Galacticraft, ExtraPlanets, Forestry & Gendustry

## Versionen

### Galacticraft
- `GalacticraftCore-1.7-3.0.12.504.jar`
- `Galacticraft-Planets-1.7-3.0.12.504.jar`

### ExtraPlanets
- `ExtraPlanets-1.7.10-2.1.4.jar`
- optional vorhandene API-Datei: `ExtraPlanets-1.7.10-2.1.4-api.jar`

ExtraPlanets 2.1.4 ist ein Galacticraft-Addon für Minecraft 1.7.10. citeturn0search2turn0search7

### Forestry
- `forestry_1.7.10-4.2.16.64.jar`

Forestry 4.2.16.64 ist für Minecraft 1.7.10 veröffentlicht. citeturn0search5

### Gendustry
- `gendustry-1.6.4.135-mc1.7.10.jar`
- optional: `gendustry-1.6.4.135-mc1.7.10-api.jar`

Gendustry 1.6.4.135 ist ein Forestry-Addon; für diese Version sind Forestry und bdlib Abhängigkeiten. citeturn0search0turn0search11

## 1. Gemeinsamer OpenComputers-Grundaufbau

1. OpenComputers-Computer bauen.
2. CPU, RAM, Festplatte/EEPROM, Grafikkarte, Bildschirm und Tastatur einbauen.
3. OpenOS starten.
4. Adapter neben das Mod-Gerät setzen, sofern das Gerät nicht bereits als OC-Komponente erscheint.
5. Adapter mit OC-Kabel/Netzwerk mit dem Computer verbinden.
6. Buldacity-Launcher starten.
7. Den passenden Controller öffnen.
8. Rescan ausführen.
9. Nur Komponenten verwenden, die der Scan tatsächlich meldet.

Der OC-Adapter ist grundsätzlich für die Verbindung von Computern mit unterstützten Nicht-Komponenten-Blöcken gedacht; ob ein bestimmter Mod-Block unterstützt wird, hängt vom vorhandenen Driver ab. citeturn0search10turn1search6

## 2. Galacticraft – normal

Datei: `Galacticraft_Modern.lua`

Empfohlener Aufbau:

`Computer -> OC-Kabel -> Adapter -> Galacticraft-Gerät`

Je nach OpenComputers-Version/Driver können Galacticraft-Funktionen auch als direkte OC-Komponenten verfügbar sein. Der Buldacity-Controller macht deshalb eine Live-Komponentensuche statt eine nicht vorhandene API zu erfinden.

### Prüfschritte

1. GalacticraftCore installieren.
2. Galacticraft-Planets installieren.
3. MicdoodleCore/Abhängigkeiten der verwendeten Galacticraft-Version korrekt installieren.
4. OpenComputers installieren.
5. Zielgerät für die Überwachung aufstellen.
6. Adapter daneben setzen, falls das Zielgerät nicht direkt als OC-Komponente erscheint.
7. Computer starten.
8. `Galacticraft` im Buldacity-Desktop öffnen.
9. Komponentenliste kontrollieren.
10. Erst danach weitere Automatisierung ergänzen.

## 3. Galacticraft – Netzwerk

Datei: `GalacticraftNetwork_Modern.lua`

Für einen Tier-2-Controller:

`Galacticraft-Gerät -> Adapter/OC-Komponente -> Tier-2 Computer -> Network Card -> Tier-3 Server`

Auf dem Tier-3-System wird der Controller über das Buldacity-Netzwerk registriert. Netzwerkzugriff benötigt die im Projekt dokumentierte Buldacity-Netzwerkkonfiguration.

## 4. ExtraPlanets – normal

Datei: `ExtraPlanets_Modern.lua`

ExtraPlanets baut auf Galacticraft auf. Deshalb zuerst GalacticraftCore + Galacticraft-Planets korrekt installieren und anschließend ExtraPlanets 2.1.4 installieren. Die veröffentlichte ExtraPlanets-2.1.4-Datei ist für Minecraft 1.7.10. citeturn0search2turn0search4

### Aufbau

`Computer -> OC-Kabel -> Adapter -> unterstütztes ExtraPlanets/Galacticraft-Gerät`

Der Controller zeigt nur tatsächlich gefundene OC-Komponenten an.

## 5. ExtraPlanets – Netzwerk

Datei: `ExtraPlanetsNetwork_Modern.lua`

Aufbau:

`ExtraPlanets/Galacticraft -> OC-Schnittstelle/Adapter -> Tier-2 -> Network Card -> Tier-3`

Der Network-Controller ist getrennt vom normalen Controller, damit die lokale Hardwareprüfung und die Buldacity-Netzwerkansicht getrennt bleiben.

## 6. Forestry – normal

Datei: `Forestry_Modern.lua`

Version: `forestry_1.7.10-4.2.16.64.jar`. citeturn0search5

### Aufbau

`Computer -> OC-Kabel -> Adapter -> Forestry-Gerät`

Typische Zielgeräte können je nach verfügbarer OC-Integration z. B. Bienen-/Apiary-/Farm-bezogene Geräte sein. Nicht automatisch unterstützte Forestry-Blöcke werden nicht als steuerbar ausgegeben.

### Prüfschritte

1. Forestry installieren.
2. OpenComputers installieren.
3. Forestry-Gerät aufstellen.
4. Adapter direkt daneben setzen, falls nötig.
5. Computer verbinden.
6. `Forestry` im Buldacity-Desktop öffnen.
7. Rescan durchführen.
8. Erkannten Komponententyp notieren.
9. Erst danach konkrete Steuerfunktionen konfigurieren.

OpenComputers selbst hatte in 1.7.10 eine Forestry-API-Anpassung; die tatsächlich verfügbaren Komponenten hängen aber von der eingesetzten OC-Version und Integration ab. citeturn1search9

## 7. Forestry – Netzwerk

Datei: `ForestryNetwork_Modern.lua`

`Forestry-Gerät -> Adapter/OC-Komponente -> Tier-2 Computer -> Network Card -> Tier-3`

Der Network-Controller führt einen Live-Scan durch und zeigt Forestry-/Bee-/Apiary-/Farm-Komponenten an, die tatsächlich verfügbar sind.

## 8. Gendustry – normal

Datei: `Gendustry_Modern.lua`

Version: `gendustry-1.6.4.135-mc1.7.10.jar`.

Gendustry ist ein Forestry-Addon und benötigt Forestry sowie bdlib. citeturn0search0turn0search11

### Installationsreihenfolge

1. Minecraft 1.7.10 + Forge.
2. OpenComputers.
3. bdlib passende 1.7.10-Version.
4. Forestry 4.2.16.64.
5. Gendustry 1.6.4.135.
6. Buldacity-Dateien.
7. Computer/Adapter aufbauen.
8. `Gendustry` im Desktop öffnen.
9. Rescan durchführen.

### Aufbau

`Computer -> OC-Kabel -> Adapter -> Gendustry/Forestry-Gerät`

Wichtig: Der Controller darf keine Gendustry-API vortäuschen. Wenn die verwendete OC-Integration keinen direkten Gendustry-Treiber liefert, zeigt er die tatsächlich verfügbaren Komponenten an und meldet nicht unterstützte Blöcke entsprechend.

## 9. Gendustry – Netzwerk

Datei: `GendustryNetwork_Modern.lua`

`Gendustry-Gerät -> Adapter/OC-Komponente -> Tier-2 -> Network Card -> Tier-3`

Die Netzwerkseite übernimmt die Komponentenerkennung am Controller; die Buldacity-Netzwerkschicht übernimmt die Übertragung zum Server.

## 10. Welche Dateien gehören jetzt zusammen?

| Mod | Normal | Netzwerk |
|---|---|---|
| Galacticraft | `Galacticraft_Modern.lua` | `GalacticraftNetwork_Modern.lua` |
| ExtraPlanets | `ExtraPlanets_Modern.lua` | `ExtraPlanetsNetwork_Modern.lua` |
| Forestry | `Forestry_Modern.lua` | `ForestryNetwork_Modern.lua` |
| Gendustry | `Gendustry_Modern.lua` | `GendustryNetwork_Modern.lua` |

## 11. Buldacity Desktop

Die vier Mod-Familien wurden in `BuldacityControllerLauncher.lua` aufgenommen:

- Galacticraft
- Galacticraft Network
- ExtraPlanets
- ExtraPlanets Network
- Forestry
- Forestry Network
- Gendustry
- Gendustry Network

Damit sind sie genauso über den Buldacity-Launcher erreichbar wie die bisherigen Controller.

## 12. Wichtig: Adapter ist nicht automatisch gleich Mod-Integration

Ein Adapter allein garantiert keine vollständige Mod-Steuerung. Der Adapter stellt unterstützte Blöcke als Komponenten bereit; dafür muss ein passender Driver existieren. citeturn0search10turn1search6

Darum gilt für alle vier neuen Mod-Familien:

**Installieren → Adapter anschließen → Komponenten-Scan → erkannte API prüfen → erst dann automatisieren.**

So verhindert Buldacity, dass Funktionen angezeigt werden, die auf der konkreten 1.7.10-Mod-/OC-Kombination gar nicht existieren.
