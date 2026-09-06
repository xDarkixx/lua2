# BULDACITY / 2 – echter OpenComputers-Installer

Der Installer installiert die lauffähigen BULDACITY-Dateien direkt in das OpenComputers-`/home`-Verzeichnis.

## Voraussetzungen

- Minecraft 1.7.10
- OpenComputers
- Tier-3-Festplatte/Filesystem
- Internet Card für die Erstinstallation und Reparaturen
- Für das BULDACITY-Netzwerk: Modem/Wireless Network Card

Der Download erfolgt direkt aus dem öffentlichen GitHub-Repository. OpenComputers kann mit einer Internet Card HTTP-Anfragen ausführen; der Installer nutzt deshalb die Raw-Dateien des Repositories. citeturn0search1turn0search8

## Installation

1. `install.lua` auf den Computer bringen.
2. Starten:

```text
install.lua
```

3. Im Menü auswählen:

```text
1) Kern installieren/reparieren
2) Alles installieren (Kern + Mod-Clients)
3) Installation prüfen
4) Netzwerk/Hardware prüfen
0) Beenden
```

## Was automatisch passiert

- `/home` wird geprüft/angelegt.
- Vorhandene gleichnamige Dateien werden nach `/home/buldacity-backup/` gesichert.
- Der BULDACITY-Kern wird aus `xDarkixx/lua2` geladen.
- Die Lua-Dateien werden nach dem Download mit `loadfile` auf Syntaxfehler geprüft.
- `autorun.lua` wird in `/home` angelegt.
- `/home/buldacity-install.cfg` wird geschrieben.
- Modem und Wireless-Fähigkeit werden geprüft.
- Der Netzwerkport `4242` wird geöffnet.
- Das Protokoll `BULDACITY/2` bleibt erhalten.

## Warum `/home`?

Die vorhandene BULDACITY-Runtime erwartet die Programme im OpenComputers-Dateisystem. Die Repository-Ordner (`server/`, `network/`, `clients/`, `ui/`, `setup/`, `boot/`) dienen der übersichtlichen Entwicklung. Der Installer legt deshalb die kompatiblen Runtime-Dateien zusätzlich direkt in `/home` ab.

Die alten Root-Dateien im Repository werden nicht gelöscht oder umbenannt.

## Netzwerk

Standardwerte:

- Protokoll: `BULDACITY/2`
- Port: `4242`
- Wireless-Stärke: bis `400`

Nach der Installation kann der grafische Netzwerk-Assistent verwendet werden.

## Reparatur

Wenn eine Installation beschädigt wurde, `install.lua` erneut starten und **1) Kern installieren/reparieren** wählen. Die vorherige Datei wird vor dem Überschreiben gesichert.

## Kosten

Der Installer benötigt keinen bezahlten API-Dienst und keinen eigenen kostenpflichtigen Server. Für den Download wird lediglich die vorhandene Internet-Verbindung der OpenComputers-Internet Card verwendet. Es können natürlich die normalen Minecraft-/Hardware-/Stromkosten anfallen.
