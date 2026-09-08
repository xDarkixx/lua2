# SchematicTxtGenerator – Windows

Windows-only GUI for converting classic Minecraft 1.7.10 `.schematic` files to editable TXT and back.

## Start

Run `Installieren.bat`, then `Start_Generator.bat`.

## Build EXE

The GUI has an **EXE kompilieren** button. It creates a virtual environment, installs PyInstaller and builds:

`dist\SchematicTxtGenerator.exe`

There is also `Build_EXE.bat` as a direct fallback.

## Supported

- Minecraft 1.7.10 / classic Schematica/WorldEdit `.schematic`
- gzip NBT
- Width / Height / Length
- Blocks / Data / AddBlocks
- block IDs up to 4095
- metadata 0–15
- X/Y/Z coordinates
- TXT -> schematic round trip

TXT example:

```text
SCHEMATIC_TXT 1
name=MeineSchematic
size=20,10,30
materials=Alpha

0,0,0=1:0
1,0,0=1:0
2,0,0=20:0
```

The final OneFile EXE does not require Python on the target PC.
