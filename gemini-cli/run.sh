#!/bin/bash
set -e

echo "[INFO] Starting Gemini CLI for Home Assistant..."

# =============================================================================
# 1. Read configuration from Home Assistant
# =============================================================================
OPTIONS_FILE="/data/options.json"

API_KEY=$(jq -r '.api_key // ""' "$OPTIONS_FILE")
MODEL=$(jq -r '.model // "auto"' "$OPTIONS_FILE")
YOLO_MODE=$(jq -r '.yolo_mode // false' "$OPTIONS_FILE")
ENABLE_MCP=$(jq -r '.enable_mcp // true' "$OPTIONS_FILE")
FONT_SIZE=$(jq -r '.terminal_font_size // 14' "$OPTIONS_FILE")
THEME=$(jq -r '.terminal_theme // "dark"' "$OPTIONS_FILE")
SESSION_PERSIST=$(jq -r '.session_persistence // true' "$OPTIONS_FILE")
AUTO_UPDATE=$(jq -r '.auto_update_gemini // true' "$OPTIONS_FILE")
WORKING_DIR=$(jq -r '.working_directory // "/homeassistant"' "$OPTIONS_FILE")

# =============================================================================
# 2. Validate API key
# =============================================================================
if [ -z "$API_KEY" ]; then
    echo "[WARNING] No Gemini API key found in configuration."
    echo "[INFO] You can still use the terminal and set your key later."
    echo "[INFO] To set your key in the terminal, run: gemini auth login"
    echo "[INFO] Get your API key at https://aistudio.google.com/apikey"
    # Proceed anyway to allow terminal access
else
    echo "[INFO] Gemini API key found. Configuration complete."
fi

# =============================================================================
# 3. Set up persistent storage
# =============================================================================
PERSIST_DIR="/homeassistant/.gemini-cli"
mkdir -p "$PERSIST_DIR"

# Symlink ~/.gemini to persistent directory
if [ ! -L /root/.gemini ]; then
    rm -rf /root/.gemini
    ln -s "$PERSIST_DIR" /root/.gemini
fi

echo "[INFO] Persistent storage: $PERSIST_DIR"

# =============================================================================
# 4. Write runtime environment file (sourced by .bashrc)
# =============================================================================
GEMINI_FLAGS=""
if [ "$YOLO_MODE" = "true" ]; then
    GEMINI_FLAGS="--yolo"
    echo "[INFO] YOLO mode enabled (auto-approve all tools)"
fi

# Set model flag if not auto
if [ "$MODEL" != "auto" ]; then
    GEMINI_FLAGS="$GEMINI_FLAGS -m $MODEL"
    echo "[INFO] Model set to: $MODEL"
else
    echo "[INFO] Using default model (auto)"
fi

cat > /etc/profile.d/gemini-env.sh << ENVEOF
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS="$GEMINI_FLAGS"
ENVEOF

# Also export for the current process (inherited by ttyd -> tmux -> bash)
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS

# =============================================================================
# 5. Auto-update Gemini CLI (if enabled)
# =============================================================================
if [ "$AUTO_UPDATE" = "true" ]; then
    echo "[INFO] Checking for Gemini CLI updates..."
    npm update -g @google/gemini-cli 2>/dev/null \
        && echo "[INFO] Gemini CLI updated successfully" \
        || echo "[WARN] Update check failed, continuing with installed version"
fi

# =============================================================================
# 6. Configure MCP server for Home Assistant
# =============================================================================
# Remove existing MCP config to ensure clean state
gemini mcp remove homeassistant 2>/dev/null || true

if [ "$ENABLE_MCP" = "true" ]; then
    gemini mcp add homeassistant hass-mcp \
        --env "HA_URL=http://supervisor/core" \
        --env "HA_TOKEN=$SUPERVISOR_TOKEN" \
        2>/dev/null && \
    echo "[INFO] MCP configured with Home Assistant integration" || \
    echo "[WARN] MCP configuration failed, trying settings.json fallback..."

    # Fallback: write settings.json directly if gemini mcp add fails
    SETTINGS_FILE="$PERSIST_DIR/settings.json"
    if [ ! -f "$SETTINGS_FILE" ] || ! jq -e '.mcpServers.homeassistant' "$SETTINGS_FILE" >/dev/null 2>&1; then
        jq -n '{
            "mcpServers": {
                "homeassistant": {
                    "command": "hass-mcp",
                    "env": {
                        "HA_URL": "http://supervisor/core",
                        "HA_TOKEN": "'"$SUPERVISOR_TOKEN"'"
                    }
                }
            }
        }' > "$SETTINGS_FILE"
        echo "[INFO] MCP configured via settings.json fallback"
    fi
else
    echo "[INFO] MCP disabled"
fi

# =============================================================================
# 7. Write GEMINI.md for HA path instructions (only if not exists)
# =============================================================================
if [ ! -f "$WORKING_DIR/GEMINI.md" ]; then
cat > "$WORKING_DIR/GEMINI.md" << 'GEMINIEOF'
# Home Assistant Add-on Environment

## Path Mapping

In this add-on container, paths differ from HA Core:
- `/homeassistant` = HA config directory (equivalent to `/config` in HA Core)
- When users mention `/config/...`, translate to `/homeassistant/...`

## Available Paths

| Path | Description | Access |
|------|-------------|--------|
| `/homeassistant` | HA configuration | read-write |
| `/share` | Shared folder | read-write |
| `/media` | Media files | read-write |
| `/ssl` | SSL certificates | read-only |
| `/backup` | Backups | read-only |

## Home Assistant Integration

Use the `homeassistant` MCP server to query entities and call services.

## Reading Home Assistant Logs

```bash
# View recent logs
ha core logs 2>&1 | tail -100

# Filter by keyword
ha core logs 2>&1 | grep -i keyword

# Read log file directly
tail -100 /homeassistant/home-assistant.log
```
GEMINIEOF
    echo "[INFO] Created GEMINI.md with HA path instructions"
else
    echo "[INFO] GEMINI.md already exists, skipping"
fi

# =============================================================================
# 8. Configure terminal theme
# =============================================================================
if [ "$THEME" = "dark" ]; then
    COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
else
    COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"
fi

# =============================================================================
# 9. Configure session persistence
# =============================================================================
if [ "$SESSION_PERSIST" = "true" ]; then
    SHELL_CMD="tmux new-session -A -s gemini"
    echo "[INFO] Session persistence enabled (tmux)"
else
    SHELL_CMD="bash --login"
fi

# =============================================================================
# 10. Launch web terminal
# =============================================================================
echo "[INFO] Starting web terminal on port 7681..."

cd "$WORKING_DIR"

exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 \
    -t "fontSize=$FONT_SIZE" \
    -t "fontFamily=Monaco,Consolas,monospace" \
    -t "scrollback=20000" \
    -t "theme=$COLORS" \
    $SHELL_CMD
