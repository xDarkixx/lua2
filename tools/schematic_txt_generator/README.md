# SchematicTxtGenerator – Windows

Windows-GUI zum Umwandeln und Prüfen von Minecraft-Bauwerken.

## Unterstützte Eingabe- und Ausgabeformate

- `.schematic` – klassisches gzip-NBT, kompatibel mit Minecraft 1.7.10/Schematica/WorldEdit
- `.schem` – Sponge Schematic mit Palette und VarInt-Blockdaten
- `.litematic` – Litematica mit Region, Palette und gepackten Long-Blockdaten
- `.obj` + `.mtl` – voxelbasierter OBJ-Export; Block-ID/Metadata werden im Objektnamen erhalten
- `.txt` – einfaches, editierbares `SCHEMATIC_TXT 1` Format

Damit kann jede der unterstützten Eingaben über **→ TXT** nach TXT konvertiert werden. Über **Konvertieren** sind alle fünf Zielformate verfügbar.

## TXT-Format

```text
SCHEMATIC_TXT 1
name=MeineSchematic
size=20,10,30
materials=Alpha

0,0,0=1:0
1,0,0=1:0
2,0,0=20:0
```

Leere Blöcke (ID 0) werden standardmäßig nicht geschrieben. Koordinaten beginnen bei `0,0,0`.

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
