# Gemini CLI for Home Assistant

> **EXPERIMENTAL** - This add-on is in early development. Expect breaking changes, bugs, and incomplete features. Use at your own risk.

A Home Assistant add-on that runs [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google's open-source CLI coding assistant) inside your Home Assistant instance with a web terminal and full smart home integration via MCP.

## Features

- Web-based terminal accessible from the HA sidebar (Ingress)
- Full read/write access to Home Assistant configuration files
- Home Assistant MCP integration via hass-mcp (entity control, service calls, automations)
- YOLO mode for auto-approving all tool executions
- Session persistence via tmux
- Configurable terminal (dark/light theme, font size)
- Auto-update on startup
- GEMINI.md with HA path mapping included

## Installation

1. Add this repository to Home Assistant:
   **Settings > Add-ons > Add-on Store > ... (top right) > Repositories**
   ```
   https://github.com/dktzde/ha_gemini_cli
   ```
2. Install the **Gemini CLI** add-on
3. Set your Gemini API key in the add-on configuration (get one at https://aistudio.google.com/apikey)
4. Start the add-on and open the web UI from the sidebar

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | *(required)* | Your Gemini API key |
| `model` | `auto` | Model: auto (gemini-2.5-pro), pro, flash, flash-lite |
| `yolo_mode` | `false` | Auto-approve all tool executions |
| `enable_mcp` | `true` | Enable Home Assistant MCP integration |
| `terminal_font_size` | `14` | Font size (10-24) |
| `terminal_theme` | `dark` | Terminal color theme (dark/light) |
| `session_persistence` | `true` | Enable tmux session persistence |
| `auto_update_gemini` | `true` | Auto-update Gemini CLI on startup |

## File Locations

| Path | Description | Access |
|------|-------------|--------|
| `/homeassistant` | HA configuration directory | read-write |
| `/share` | Shared folder | read-write |
| `/media` | Media files | read-write |
| `/ssl` | SSL certificates | read-only |
| `/backup` | Backups | read-only |

## Quick Commands

```bash
g              # Start Gemini CLI (with model + yolo flags if configured)
gr             # Resume last session
ha-config      # cd to HA config directory
ha-logs        # View HA logs
```

## Session Persistence (tmux)

With session persistence enabled (default), your terminal session survives browser refreshes.

- Scroll: mouse wheel or `Ctrl+B [` then arrow keys
- Detach: `Ctrl+B d`
- New window: `Ctrl+B c`

## Requirements

- Home Assistant OS or Supervised installation
- Google AI Studio account with API key (https://aistudio.google.com/apikey)
- amd64 or aarch64 architecture

## License

MIT
