# SchematicTxtGenerator – Windows

Offline-Windows-GUI zum Konvertieren, Prüfen und Bearbeiten von Minecraft-Bauwerken. **Minecraft muss auf dem PC nicht installiert oder gestartet sein.** Der Converter ist bewusst **Minecraft-version-unabhängig**: Es gibt keine fest eingebaute Abhängigkeit von einer bestimmten Minecraft-Version oder einem bestimmten Mod.

## Unterstützte Formate

- `.schematic` – klassisches gzip-NBT mit Legacy-Block-ID/Metadata
- `.schem` – Sponge Schematic mit Block-State-Palette
- `.litematic` – Litematica mit Block-State-Palette und Regionen
- `.obj` – voxelbasierter OBJ-Import/Export des eigenen Formats
- `.txt` – reines `SCHEMATIC_TXT 1` Textformat

## Version-unabhängiges Datenmodell

Der Converter arbeitet intern mit einem neutralen Voxel-Modell:

- X, Y und Z Koordinaten
- Breite, Höhe und Länge
- Legacy-Block-ID und Metadata, **wenn die Quelldatei diese Informationen besitzt**
- Block-State als Text, **wenn die Quelle einen Block-State liefert**
- optionale Material-/Quellinformationen nur als Daten, nicht als notwendige Minecraft-Version

Wichtig: Eine alte `.schematic` enthält normalerweise nur Legacy-IDs/Metadata. Der Converter kann daraus keinen modernen Blocknamen zuverlässig rekonstruieren. Bei `.schem` und `.litematic` werden vorhandene Block-State-Namen und Properties dagegen als `# state=...` in der TXT erhalten.

## Ziel: eine reine TXT

Der Konverter kann ein Bauwerk komplett außerhalb von Minecraft einlesen und als **eine einzige normale UTF-8-TXT-Datei** ausgeben. Diese Datei enthält Abmessungen, Koordinaten, Block-ID, Metadata und – wenn vorhanden – den Block-State.

Beispiel:

```text
SCHEMATIC_TXT 1
name=MeinBauwerk
size=20,10,30
materials=Universal

0,0,0=1:0
1,0,0=1:0
2,0,0=20:0 # state=minecraft:glass
```

Die TXT ist bewusst einfach und versionsneutral gehalten. Sie kann auf beliebige Dateisysteme kopiert, archiviert oder von einem eigenen Roboter-/Builder-System eingelesen werden. Der Converter selbst enthält **keine zwingende Lua-Abhängigkeit** und benötigt für die Konvertierung kein Minecraft.

Der Export erfolgt von **unten nach oben**: zuerst Y=0, danach Y=1, Y=2 usw. Innerhalb einer Ebene wird Z und danach X verarbeitet.

## Block-Editor

Der integrierte **Block-Editor** arbeitet direkt auf dem neutralen Datenmodell. Funktionen:

- `.schematic`, `.schem`, `.litematic`, `.obj` und `.txt` direkt öffnen
- TXT direkt exportieren
- neues Bauwerk erstellen
- Layer über Y auswählen
- Mausrad: Ebene ±1
- Strg+Mausrad: Ebene ±10
- Bild↑/Bild↓ und Pfeil ↑/↓: Ebene ±1
- Home/Ende: unterste/oberste Ebene
- Blöcke per Linksklick setzen
- Blöcke per Rechtsklick löschen
- Block-ID 0–4095 und Metadata 0–15 manuell eingeben
- integrierte neutrale/Legacy-Referenzpalette
- direkte 3D-Vorschau des bearbeiteten Bauwerks

Die GUI begrenzt nicht die Größe der Quelldatei künstlich. Die Darstellung rendert jeweils nur die aktuell benötigte Editor-/Vorschauansicht.

## 3D-Vorschau

Die 3D-Ansicht läuft lokal über die Daten aus der Datei. Sie benötigt kein Minecraft. Das Bauwerk kann gedreht und gezoomt werden.

## Konvertierung

`Datei öffnen` lädt eine Datei und zeigt Dimensionen sowie Blockdaten. `TXT exportieren` erzeugt direkt die portable Textdatei. `Konvertieren` kann weiterhin zwischen den unterstützten Formaten umwandeln.

Beim Konvertieren gilt: Das Programm kann nur Informationen erhalten, die das jeweilige Quellformat tatsächlich enthält. Eine Legacy-`.schematic` wird daher nicht künstlich mit erfundenen modernen Block-States angereichert.

## OpenComputers

Der Converter erzeugt nur den Bauplan. Es ist absichtlich **kein OpenComputers-Lua-Builder Bestandteil des Converters**. Der erzeugte TXT-Bauplan kann später von einem eigenen OpenComputers-/Robot-Programm eingelesen werden.

Wichtig: Die TXT beschreibt die gewünschten Blöcke; sie kann ohne Kenntnis der tatsächlich vorhandenen Items nicht garantieren, dass ein Robot jeden Block platzieren kann. Die konkrete Materialversorgung ist Sache des Roboters bzw. der Minecraft-Mods.

## Windows / EXE

Mit `Start_Generator.bat` kann die GUI gestartet werden. Mit `Build_EXE.bat` bzw. dem Button `EXE kompilieren` kann die Windows-EXE gebaut werden.

## Tests

Unter `tests/test_formats.py` liegen Round-Trip-Tests für TXT, `.schematic`, `.schem`, `.litematic` und OBJ/MTL. Der OBJ-Test enthält ausdrücklich auch einen Legacy-Block mit ID 511, damit die `AddBlocks`-Übertragung über 255 nicht unbemerkt kaputtgeht.

```bat
python -m unittest discover -s tests -v
```
