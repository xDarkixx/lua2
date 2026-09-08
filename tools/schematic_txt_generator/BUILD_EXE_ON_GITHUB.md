# Windows-EXE automatisch bauen

Der SchematicTxtGenerator kann als **eine einzelne Windows-EXE** gebaut werden. Minecraft, Java und Python sind auf dem Ziel-PC nicht erforderlich.

## Automatischer Build

GitHub Actions baut die EXE bei Änderungen unter `tools/schematic_txt_generator/` und kann zusätzlich manuell gestartet werden.

Workflow:

`.github/workflows/schematic-converter.yml`

Der Build:

1. startet auf `windows-latest`
2. installiert Python und PyInstaller nur auf dem Build-Runner
3. führt die Tests aus
4. erstellt `SchematicTxtGenerator.exe` mit `console=False`
5. prüft, ob die EXE wirklich vorhanden und plausibel groß ist
6. lädt nur die fertige EXE als GitHub-Artifact hoch

## EXE herunterladen

Im Repository unter **Actions** den Workflow `SchematicTxtGenerator Windows EXE` öffnen, einen erfolgreichen Lauf auswählen und unter **Artifacts** `SchematicTxtGenerator-Windows` herunterladen.

## Lokaler Build

Auf einem Windows-PC mit Python 3:

```bat
Build_EXE.bat
```

Danach liegt die fertige Datei hier:

```text
dist\SchematicTxtGenerator.exe
```

## Unterstützte Formate

- `.schematic` – klassisches MCEdit/Schematica-Format
- `.schem` – Sponge Schematic
- `.litematic` – Litematica
- `.obj` – Voxel-OBJ des Projekts
- `.txt` – neutrales, Minecraft-versionsunabhängiges Textformat

Das interne Modell ist voxelbasiert. Dadurch kann zwischen den Formaten konvertiert werden, ohne Minecraft selbst zu starten.

## Wichtig bei alten Minecraft-Versionen

Für Minecraft 1.7.10 ist `.schematic` der relevante Zieltyp. Moderne Blockzustände können jedoch nicht immer 1:1 in alte numerische Block-IDs übersetzt werden. Eine Konvertierung kann deshalb Informationen verlieren, wenn der Zielstandard weniger Blocktypen kennt.
