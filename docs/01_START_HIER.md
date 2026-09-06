# 🟢 BULDACITY – START HIER

Diese Anleitung ist für den Einstieg gedacht. Du musst **kein Lua können** und musst normalerweise keine Netzwerkadressen von Hand eintragen.

## 1. Was bauen wir?

```text
                    ┌──────────────────────┐
                    │ BULDACITY TIER-3     │
                    │ Hauptcomputer        │
                    └──────────┬───────────┘
                               │
                    BULDACITY/2 Netzwerk
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
   Big Reactors-PC       SGCraft-PC          weitere PCs
```

Der Tier-3-Computer ist die Zentrale. Die anderen Computer sind Clients.

## 2. Reihenfolge – genau so machen

- [ ] Minecraft 1.7.10 + Forge installieren
- [ ] OpenComputers installieren
- [ ] benötigte Mods installieren
- [ ] Tier-3-Zentrale bauen
- [ ] Modem anschließen
- [ ] `Network.lua` auf die Computer kopieren
- [ ] Zentrale starten
- [ ] Client starten
- [ ] Netzwerk-Assistent prüfen
- [ ] erst danach Autostart einschalten

## 3. Wichtig

**Nicht alles gleichzeitig ändern.** Erst die Zentrale zum Laufen bringen, dann einen Client testen.

Wenn im Netzwerk etwas nicht funktioniert, starte zuerst:

```text
BuldacityNetworkSetup.lua
```

Der Assistent prüft Modem, Port 4242, Funk/Wired, Clients, Ping und Komponenten.

## 4. Die wichtigsten Ordner

| Ordner | Inhalt |
|---|---|
| `docs/` | Anleitungen – hier zuerst schauen |
| `server/` | Zentrale / Server |
| `network/` | Netzwerkfunktionen |
| `clients/` | Geräte-Controller |
| `boot/` | Autostart |
| `tools/` | Diagnose und Hilfsprogramme |

Die vorhandenen Dateien im Hauptordner bleiben zunächst erhalten, damit ältere Installationen weiter funktionieren.

## 5. Wenn du nur eine Sache merken willst

**START → ZENTRALE → CLIENT → TESTEN → AUTOSTART**

Du musst keine UUID-Whitelist pflegen und normalerweise keine Adressen abtippen.
