#!/bin/bash
set -e

echo "[INFO] Starting Gemini CLI for Home Assistant..."

# 1. Read configuration
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

# 2. API Key Info
if [ -z "$API_KEY" ]; then
    echo "[WARNING] No Gemini API key found. Use 'gemini auth login' later."
else
    echo "[INFO] Gemini API key configured."
fi

# 3. Persistent storage
PERSIST_DIR="/homeassistant/.gemini-cli"
mkdir -p "$PERSIST_DIR"
if [ ! -L /root/.gemini ]; then
    rm -rf /root/.gemini
    ln -s "$PERSIST_DIR" /root/.gemini
fi

# 4. Environment for Bash/Gemini
GEMINI_FLAGS=""
[ "$YOLO_MODE" = "true" ] && GEMINI_FLAGS="--yolo"
[ "$MODEL" != "auto" ] && GEMINI_FLAGS="$GEMINI_FLAGS -m $MODEL"

# Increase Node.js memory limit and set environment
cat >> /root/.bashrc << EOF
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS="$GEMINI_FLAGS"
export NODE_OPTIONS="--max-old-space-size=2048"
EOF

export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS
export NODE_OPTIONS="--max-old-space-size=2048"

# 5. Create GEMINI.md for context
cat > "$WORKING_DIR/GEMINI.md" << EOF
# Home Assistant Add-on Environment

## CRITICAL: Reading Logs
**NEVER** attempt to read files in \`/var/log/\` or \`/var/log/journal\` directly. These are binary or restricted files and WILL cause a system crash.
**ALWAYS** use the following command to read Home Assistant logs:
\`\`\`bash
ha core logs
\`\`\`

## Path Mapping
- /homeassistant = HA config (equivalent to /config in HA Core)
- Always translate /config/... to /homeassistant/...

## Available Paths
| Path | Description | Access |
|------|-------------|--------|
| /homeassistant | HA config | read-write |
| /share | Shared folder | read-write |
| /media | Media files | read-write |
| /ssl | SSL certs | read-only |
| /backup | Backups | read-only |
EOF

# 6. MCP Config
if [ "$ENABLE_MCP" = "true" ]; then
    echo "[INFO] Configuring MCP..."
    gemini mcp remove homeassistant 2>/dev/null || true
    gemini mcp add homeassistant hass-mcp --env "HA_URL=http://supervisor/core" --env "HA_TOKEN=$SUPERVISOR_TOKEN" 2>/dev/null || true
fi

# 7. Terminal Theme
COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
[ "$THEME" != "dark" ] && COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"

# 8. Start ttyd
SHELL_CMD="bash --login"
[ "$SESSION_PERSIST" = "true" ] && SHELL_CMD="tmux new-session -A -s gemini"

echo "[INFO] Launching terminal..."
cd "$WORKING_DIR"
exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 \
    -t "fontSize=$FONT_SIZE" \
    -t "theme=$COLORS" \
    $SHELL_CMD
