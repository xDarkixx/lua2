# SchematicTxtGenerator – Windows

Windows-GUI zum Umwandeln und Prüfen von Minecraft-Bauwerken.

## Unterstützte Eingabe- und Ausgabeformate

- `.schematic` – klassisches gzip-NBT, kompatibel mit Minecraft 1.7.10/Schematica/WorldEdit
- `.schem` – Sponge Schematic mit Palette und VarInt-Blockdaten
- `.litematic` – Litematica mit Region, Palette und gepackten Long-Blockdaten
- `.obj` + `.mtl` – voxelbasierter OBJ-Export; Block-ID/Metadata werden im Objektnamen erhalten
- `.txt` – einfaches, editierbares `SCHEMATIC_TXT 1` Format

Damit kann jede der unterstützten Eingaben über **→ TXT** nach TXT konvertiert werden. Über **Konvertieren** sind alle fünf Zielformate verfügbar.

## OpenComputers: nur eine reine TXT-Datei

Der OpenComputers-Weg braucht für den Bau **keine `.schematic`, `.schem`, `.litematic` oder Minecraft-Konverterdatei**. Der Konverter läuft außerhalb von Minecraft und erzeugt eine einzige normale UTF-8-Textdatei:

```text
SCHEMATIC_TXT 1
name=MeineSchematic
size=20,10,30
materials=Alpha

0,0,0=1:0
1,0,0=1:0
2,0,0=20:0
```

Diese `blueprint.txt` kann auf das OpenComputers-Dateisystem kopiert werden. Das mitgelieferte `opencomputers/builder.lua` liest genau diese Textdatei, baut von unten nach oben und speichert bei einem Abbruch den nächsten Block in `blueprint.txt.state`.

### Robot starten

1. `blueprint.txt` auf den OpenComputers-Robot kopieren.
2. `builder.lua` auf den Robot kopieren.
3. Den Robot **einen Block vor X=0** stellen: relative Position `(-1,0,0)`.
4. Robot nach **+X** ausrichten.
5. Benötigte Baumaterialien in das Roboter-Inventar legen.
6. Starten:

```text
builder.lua blueprint.txt
```

Der Builder arbeitet Layer für Layer (`Y` aufsteigend) und führt die Koordinaten direkt aus der TXT-Datei aus. Ein `inventory_controller` kann verwendet werden, damit Metadaten beim Auswählen des Materials berücksichtigt werden.

### Material-Slots in derselben TXT-Datei

Wenn die automatische Auswahl nicht eindeutig ist, können im gleichen Text zusätzliche `slot=`-Zeilen stehen. Beispiel:

```text
slot=1,1:0
slot=2,4:0
```

Damit wird `1:0` aus Slot 1 und `4:0` aus Slot 2 genommen. Es bleibt trotzdem **nur eine Blueprint-TXT-Datei**; es ist keine zusätzliche Materialdatei erforderlich.

> Hinweis: Ein OpenComputers-Robot kann nur Materialien platzieren, die tatsächlich als passende Itemstacks im Inventar vorhanden sind. Die TXT-Datei beschreibt den Bauplan; sie erzeugt oder beschafft keine Items.

## Minecraft 1.7.10

`.schematic` ist das Zielformat für die klassische Minecraft-1.7.10-Welt. IDs bis 4095 und Metadata 0–15 werden unterstützt. Bei `.schem`/`.litematic` sind moderne Blockstates zusätzlich intern vorhanden; für nicht bekannte moderne Blockstates kann die Rückführung auf eine 1.7.10-ID verlustbehaftet sein.

## OBJ

Der OBJ-Export erzeugt pro nicht-leerem Block einen Würfel und eine passende `.mtl` Datei. Die Objektnamen haben das Schema:

`block_ID_META_xX_yY_zZ`

Dadurch kann ein von diesem Programm erzeugtes OBJ wieder zuverlässig eingelesen werden. Ein beliebiges extern erzeugtes OBJ ist dagegen nur dann importierbar, wenn es diese Blockobjekte enthält; allgemeine Meshes werden nicht stillschweigend in Minecraft-Blöcke umgewandelt.

## Start / EXE

Die vorhandenen Windows-Start- und Build-Skripte können weiterhin verwendet werden. Die GUI prüft beim Konvertieren das Dateiformat und meldet ungültige NBT-, TXT- oder OBJ-Daten als Fehler.

## Tests

Unter `tests/test_formats.py` liegen Round-Trip-Tests für TXT, `.schematic`, `.schem`, `.litematic` und OBJ/MTL.

Test lokal:

```bat
python -m unittest discover -s tests -v
```
