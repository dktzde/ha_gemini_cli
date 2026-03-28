# Gemini CLI pour Home Assistant

> **EXPERIMENTAL** - Ce module complementaire est en developpement precoce. Attendez-vous a des changements majeurs, des bugs et des fonctionnalites incompletes. Utilisez-le a vos propres risques.

Un module complementaire Home Assistant qui execute [Gemini CLI](https://github.com/google-gemini/gemini-cli) (l'assistant de codage CLI open-source de Google) dans votre instance Home Assistant avec un terminal web et une integration complete de la maison connectee via MCP.

## Fonctionnalites

- Terminal web accessible depuis la barre laterale HA (Ingress)
- Acces complet en lecture/ecriture aux fichiers de configuration Home Assistant
- Integration MCP Home Assistant via hass-mcp (controle d'entites, appels de services, automatisations)
- Mode YOLO pour approuver automatiquement toutes les executions d'outils
- Persistance de session via tmux
- Terminal configurable (theme sombre/clair, taille de police)
- Mise a jour automatique au demarrage

## Installation

1. Ajoutez ce depot a Home Assistant :
   **Parametres > Modules complementaires > Boutique > ... (en haut a droite) > Depots**
   ```
   https://github.com/dktzde/ha_gemini_cli
   ```
2. Installez le module **Gemini CLI**
3. Configurez votre cle API Gemini (obtenez-en une sur https://aistudio.google.com/apikey)
4. Demarrez le module et ouvrez l'interface web depuis la barre laterale

## Configuration

| Option | Par defaut | Description |
|--------|------------|-------------|
| `api_key` | *(requis)* | Votre cle API Gemini |
| `model` | `auto` | Modele : auto (gemini-2.5-pro), pro, flash, flash-lite |
| `yolo_mode` | `false` | Approuver automatiquement toutes les executions d'outils |
| `enable_mcp` | `true` | Activer l'integration MCP Home Assistant |
| `terminal_font_size` | `14` | Taille de police (10-24) |
| `terminal_theme` | `dark` | Theme du terminal (dark/light) |
| `session_persistence` | `true` | Activer la persistance de session tmux |
| `auto_update_gemini` | `true` | Mise a jour automatique au demarrage |

## Commandes rapides

```bash
g              # Demarrer Gemini CLI
gr             # Reprendre la derniere session
ha-config      # Aller au repertoire de configuration HA
ha-logs        # Voir les logs HA
```

## Prerequis

- Installation Home Assistant OS ou Supervised
- Compte Google AI Studio avec cle API (https://aistudio.google.com/apikey)
- Architecture amd64 ou aarch64

## Licence

MIT
