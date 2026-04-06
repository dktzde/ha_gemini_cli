#!/bin/bash
set -e

echo "[INFO] Starting Gemini CLI Recovery Mode (v0.3.9)..."

# 1. Read configuration
OPTIONS_FILE="/data/options.json"
API_KEY=$(jq -r '.api_key // ""' "$OPTIONS_FILE")
MODEL=$(jq -r '.model // "auto"' "$OPTIONS_FILE")
YOLO_MODE=$(jq -r '.yolo_mode // false' "$OPTIONS_FILE")
ENABLE_MCP=$(jq -r '.enable_mcp // true' "$OPTIONS_FILE")
FONT_SIZE=$(jq -r '.terminal_font_size // 14' "$OPTIONS_FILE")
THEME=$(jq -r '.terminal_theme // "dark"' "$OPTIONS_FILE")
SESSION_PERSIST=$(jq -r '.session_persistence // true' "$OPTIONS_FILE")
WORKING_DIR=$(jq -r '.working_directory // "/homeassistant"' "$OPTIONS_FILE")

# 2. Persistent storage
PERSIST_DIR="/homeassistant/.gemini-cli"
mkdir -p "$PERSIST_DIR"
if [ ! -L /root/.gemini ]; then
    rm -rf /root/.gemini
    ln -s "$PERSIST_DIR" /root/.gemini
fi

# 3. Environment (Reduced Memory Limit for Stability)
GEMINI_FLAGS=""
[ "$YOLO_MODE" = "true" ] && GEMINI_FLAGS="--yolo"
[ "$MODEL" != "auto" ] && GEMINI_FLAGS="$GEMINI_FLAGS -m $MODEL"

export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS
export NODE_OPTIONS="--max-old-space-size=1024" # Safe 1GB limit

# Clean .bashrc
sed -i '/export/d' /root/.bashrc
cat >> /root/.bashrc << EOF
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export GEMINI_FLAGS="$GEMINI_FLAGS"
export NODE_OPTIONS="--max-old-space-size=1024"
alias halogs='ha core logs --tail 200'
EOF

# 4. MCP Config
if [ "$ENABLE_MCP" = "true" ]; then
    (
        gemini mcp remove homeassistant 2>/dev/null || true
        gemini mcp add homeassistant hass-mcp --env "HA_URL=http://supervisor/core" --env "HA_TOKEN=$SUPERVISOR_TOKEN" 2>/dev/null || true
    ) &
fi

# 5. Start ttyd
COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
[ "$THEME" != "dark" ] && COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"

SHELL_CMD="bash --login"
if [ "$SESSION_PERSIST" = "true" ]; then
    tmux has-session -t gemini 2>/dev/null || tmux new-session -d -s gemini
    SHELL_CMD="tmux attach-session -t gemini"
fi

echo "[INFO] Launching stable terminal..."
cd "$WORKING_DIR"
exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 \
    -t "fontSize=$FONT_SIZE" \
    -t "theme=$COLORS" \
    -t "disableLeaveAlert=true" \
    $SHELL_CMD
