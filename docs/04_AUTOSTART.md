# ▶️ BULDACITY – Autostart

Autostart kommt **ganz am Ende**, wenn Server und Clients manuell funktionieren.

## Zentrale

Die Datei `BuldacityAutoStart.lua` wird als `/home/autorun.lua` verwendet.

## Client

Ein Client kann seinen passenden Network-Controller beim Start automatisch laden.

## Empfohlene Reihenfolge

```text
1. Manuell starten
2. Netzwerk testen
3. Geräte testen
4. Neustart testen
5. Erst jetzt Autostart aktivieren
```

Wenn nach einem Neustart etwas fehlt, Autostart wieder entfernen und zuerst den manuellen Start prüfen.
