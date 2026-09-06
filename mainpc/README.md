# BULDACITY / 2 – Main PC

Der Main-PC-Installer lädt **das komplette Repository** `xDarkixx/lua2` direkt von GitHub. Git muss auf dem PC nicht installiert sein.

## Voraussetzungen

- Windows 10/11, Linux oder macOS
- Python 3.9 oder neuer
- Internetzugang

## Windows

1. `mainpc/install.py` starten, z. B. mit `py mainpc\install.py`.
2. Einen Zielordner auswählen oder den Standard `~/BULDACITY` verwenden.
3. Nach der Installation `BULDACITY.bat` starten.

## Linux / macOS

```text
python3 mainpc/install.py
./mainpc
```

## Update

Der gleiche Installer kann jederzeit erneut ausgeführt werden. Mit `--update` wird ohne Rückfrage aktualisiert. Vorhandene Dateien werden vorher in `backup/YYYYMMDD-HHMMSS/` gesichert.

```text
python3 mainpc/install.py --update
```

## Was wird installiert?

Nicht nur eine feste Liste: Der Installer übernimmt den **gesamten Inhalt des `main`-Branches**, inklusive Lua-Programmen, `clients/`, `network/`, `server/`, `setup/`, `ui/`, `boot/`, `tools/` und `docs/`. Dadurch werden neue Dateien beim nächsten Update automatisch mitgenommen.

## Architektur

Der Main PC ist die Verwaltungs-/Download-Seite. Die eigentliche OpenComputers-Ausführung bleibt auf dem Minecraft-Computer. Der Main-PC-Installer verändert keine Minecraft-Installation und benötigt keine GitHub-Anmeldedaten.
