# SchematicTxtGenerator – Windows

Offline-Windows-GUI zum Konvertieren, Prüfen und Bearbeiten von Minecraft-Bauwerken. **Minecraft muss auf dem PC nicht installiert oder gestartet sein.**

## Unterstützte Formate

- `.schematic` – klassisches gzip-NBT für Minecraft 1.7.10/Schematica/WorldEdit
- `.schem` – Sponge Schematic
- `.litematic` – Litematica
- `.obj` – voxelbasierter OBJ-Import/Export
- `.txt` – reines `SCHEMATIC_TXT 1` Textformat

## Ziel: eine reine TXT

Der Konverter kann ein Bauwerk komplett außerhalb von Minecraft einlesen und als **eine einzige normale UTF-8-TXT-Datei** ausgeben. Diese Datei enthält Abmessungen, Koordinaten, Block-ID, Metadata und – wenn vorhanden – den Block-State.

Beispiel:

```text
SCHEMATIC_TXT 1
name=MeinBauwerk
size=20,10,30
materials=Alpha

0,0,0=1:0
1,0,0=1:0
2,0,0=20:0
```

Die TXT ist bewusst einfach gehalten: Sie kann auf beliebige Dateisysteme kopiert, archiviert oder von einem eigenen Roboter-/Builder-System eingelesen werden. Der Converter selbst enthält **keine zwingende Lua-Abhängigkeit** und benötigt für die Konvertierung kein Minecraft.

## Block-Editor

Der integrierte **Block-Editor** arbeitet direkt auf dem reinen Datenmodell. Funktionen:

- vorhandene TXT öffnen und wieder als TXT speichern
- neues Bauwerk erstellen
- Layer über Y auswählen
- Blöcke per Linksklick setzen
- Blöcke per Rechtsklick löschen
- Zoom für große Layer
- Block-ID 0–4095 und Metadata 0–15 manuell eingeben
- kleine integrierte 1.7.10-Blockpalette
- direkte 3D-Vorschau des bearbeiteten Bauwerks

Damit lässt sich eine TXT auch komplett ohne Ausgangs-Schematic erstellen oder korrigieren.

## 3D-Vorschau

Die 3D-Ansicht läuft lokal über die Daten aus der Datei. Sie benötigt kein Minecraft. Das Bauwerk kann gedreht und gezoomt werden.

## Konvertierung

`Datei öffnen` lädt eine Datei und zeigt Dimensionen sowie Blockdaten. `→ TXT` erzeugt direkt die portable Textdatei. `Konvertieren` kann weiterhin zwischen den unterstützten Formaten umwandeln.

## OpenComputers

Der Converter erzeugt nur den Bauplan. Es ist absichtlich **kein OpenComputers-Lua-Builder Bestandteil des Converters**. Der erzeugte TXT-Bauplan kann später von einem eigenen OpenComputers-/Robot-Programm eingelesen werden.

Wichtig: Die TXT beschreibt die gewünschten Blöcke; sie kann ohne Kenntnis der tatsächlich vorhandenen Items nicht garantieren, dass ein Robot jeden Block platzieren kann. Die konkrete Materialversorgung ist Sache des Roboters bzw. der Minecraft-Mods.

## Windows / EXE

Mit `Start_Generator.bat` kann die GUI gestartet werden. Mit `Build_EXE.bat` bzw. dem Button `EXE kompilieren` kann die Windows-EXE gebaut werden.

## Tests

Unter `tests/test_formats.py` liegen Round-Trip-Tests für TXT, `.schematic`, `.schem`, `.litematic` und OBJ/MTL.

```bat
python -m unittest discover -s tests -v
```
