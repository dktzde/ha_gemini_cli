# Gemini CLI fuer Home Assistant

> **EXPERIMENTELL** - Dieses Add-on befindet sich in einer fruehen Entwicklungsphase. Erwarten Sie Breaking Changes, Bugs und unvollstaendige Funktionen. Nutzung auf eigene Gefahr.

Ein Home Assistant Add-on, das [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Googles Open-Source CLI-Coding-Assistent) in Ihrer Home Assistant Instanz mit Web-Terminal und vollstaendiger Smart-Home-Integration via MCP ausfuehrt.

## Funktionen

- Web-basiertes Terminal ueber die HA-Seitenleiste (Ingress)
- Voller Lese-/Schreibzugriff auf Home Assistant Konfigurationsdateien
- Home Assistant MCP-Integration via hass-mcp (Entity-Steuerung, Service-Aufrufe, Automationen)
- YOLO-Modus fuer automatische Genehmigung aller Tool-Ausfuehrungen
- Session-Persistenz via tmux
- Konfigurierbares Terminal (Dark/Light-Theme, Schriftgroesse)
- Automatische Updates beim Start
- GEMINI.md mit HA-Pfad-Mapping enthalten

## Installation

1. Dieses Repository in Home Assistant hinzufuegen:
   **Einstellungen > Add-ons > Add-on Store > ... (oben rechts) > Repositories**
   ```
   https://github.com/dktzde/ha_gemini_cli
   ```
2. Das **Gemini CLI** Add-on installieren
3. Gemini API-Key in der Add-on-Konfiguration eintragen (erhalten Sie einen unter https://aistudio.google.com/apikey)
4. Add-on starten und Web-UI ueber die Seitenleiste oeffnen

## Konfiguration

| Option | Standard | Beschreibung |
|--------|----------|--------------|
| `api_key` | *(erforderlich)* | Ihr Gemini API-Key |
| `model` | `auto` | Modell: auto (gemini-2.5-pro), pro, flash, flash-lite |
| `yolo_mode` | `false` | Alle Tool-Ausfuehrungen automatisch genehmigen |
| `enable_mcp` | `true` | Home Assistant MCP-Integration aktivieren |
| `terminal_font_size` | `14` | Schriftgroesse (10-24) |
| `terminal_theme` | `dark` | Terminal-Farbschema (dark/light) |
| `session_persistence` | `true` | tmux Session-Persistenz aktivieren |
| `auto_update_gemini` | `true` | Gemini CLI automatisch beim Start aktualisieren |

## Dateipfade

| Pfad | Beschreibung | Zugriff |
|------|--------------|---------|
| `/homeassistant` | HA-Konfigurationsverzeichnis | Lesen/Schreiben |
| `/share` | Geteilter Ordner | Lesen/Schreiben |
| `/media` | Mediendateien | Lesen/Schreiben |
| `/ssl` | SSL-Zertifikate | Nur Lesen |
| `/backup` | Backups | Nur Lesen |

## Schnellbefehle

```bash
g              # Gemini CLI starten
gr             # Letzte Session fortsetzen
ha-config      # Zum HA-Konfigurationsverzeichnis wechseln
ha-logs        # HA-Logs anzeigen
```

## Session-Persistenz (tmux)

Bei aktivierter Session-Persistenz (Standard) ueberlebt die Terminal-Session Browser-Aktualisierungen.

- Scrollen: Mausrad oder `Ctrl+B [` dann Pfeiltasten
- Trennen: `Ctrl+B d`
- Neues Fenster: `Ctrl+B c`

## Voraussetzungen

- Home Assistant OS oder Supervised Installation
- Google AI Studio Konto mit API-Key (https://aistudio.google.com/apikey)
- amd64 oder aarch64 Architektur

## Lizenz

MIT
