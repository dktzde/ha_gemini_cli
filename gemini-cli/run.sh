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

# 2. Persistent storage setup
PERSIST_DIR="/homeassistant/.gemini-cli"
mkdir -p "$PERSIST_DIR"
if [ ! -L /root/.gemini ]; then
    rm -rf /root/.gemini
    ln -s "$PERSIST_DIR" /root/.gemini
fi

# 3. Environment for Bash/Gemini
GEMINI_FLAGS=""
[ "$YOLO_MODE" = "true" ] && GEMINI_FLAGS="--yolo"
[ "$MODEL" != "auto" ] && GEMINI_FLAGS="$GEMINI_FLAGS -m $MODEL"

# Export variables for current and future shells
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS
export NODE_OPTIONS="--max-old-space-size=2048"

# Write to .bashrc for persistence in interactive shells
# Remove old exports first to avoid duplicates
sed -i '/export GEMINI_API_KEY/d' /root/.bashrc
sed -i '/export HA_TOKEN/d' /root/.bashrc
sed -i '/export HA_URL/d' /root/.bashrc
sed -i '/export GEMINI_FLAGS/d' /root/.bashrc
sed -i '/export NODE_OPTIONS/d' /root/.bashrc

cat >> /root/.bashrc << EOF
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS="$GEMINI_FLAGS"
export NODE_OPTIONS="--max-old-space-size=2048"
EOF

# 4. Create GEMINI.md for context
cat > "$WORKING_DIR/GEMINI.md" << EOF
# Home Assistant Add-on Environment

## CRITICAL: Reading Logs
**NEVER** attempt to read files in \`/var/log/\` or \`/var/log/journal\` directly.
**ALWAYS** use: \`ha core logs\`

## Path Mapping
- /homeassistant = HA config directory
- Always translate /config/... to /homeassistant/...
EOF

# 5. MCP Config (Backgrounded to avoid startup delay)
if [ "$ENABLE_MCP" = "true" ]; then
    (
        gemini mcp remove homeassistant 2>/dev/null || true
        gemini mcp add homeassistant hass-mcp --env "HA_URL=http://supervisor/core" --env "HA_TOKEN=$SUPERVISOR_TOKEN" 2>/dev/null || true
    ) &
fi

# 6. Terminal Theme
COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
[ "$THEME" != "dark" ] && COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"

# 7. Start ttyd
# Use tmux with -A to ensure we always attach to the same session
# and it doesn't die when the web client disconnects
SHELL_CMD="bash --login"
if [ "$SESSION_PERSIST" = "true" ]; then
    # Ensure a session exists
    tmux has-session -t gemini 2>/dev/null || tmux new-session -d -s gemini
    SHELL_CMD="tmux attach-session -t gemini"
fi

echo "[INFO] Launching terminal on port 7681..."
cd "$WORKING_DIR"
exec ttyd --port 7681 --writable --ping-interval 10 --max-clients 5 \
    -t "fontSize=$FONT_SIZE" \
    -t "theme=$COLORS" \
    -t "disableLeaveAlert=true" \
    $SHELL_CMD
