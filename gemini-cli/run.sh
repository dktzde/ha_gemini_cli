#!/bin/bash
# Aktiviert Shell-Debugging, um jeden Schritt im HA-Log zu sehen
set -x

echo "[INFO] Starting Gemini CLI Debug Mode (v0.3.7)..."

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

# 2. Persistent storage
PERSIST_DIR="/homeassistant/.gemini-cli"
mkdir -p "$PERSIST_DIR"
DEBUG_LOG="$PERSIST_DIR/debug.log"
echo "--- New Debug Session $(date) ---" >> "$DEBUG_LOG"

if [ ! -L /root/.gemini ]; then
    rm -rf /root/.gemini
    ln -s "$PERSIST_DIR" /root/.gemini
fi

# 3. Environment & Debug Flags
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
# Maximale Diagnose-Flags für Node.js und Gemini
export NODE_OPTIONS="--max-old-space-size=4096 --trace-uncaught --trace-warnings"
export DEBUG="*" 

# Prepare .bashrc (mit Alias für Log-Analyse)
sed -i '/export/d' /root/.bashrc
cat >> /root/.bashrc << EOF
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export NODE_OPTIONS="$NODE_OPTIONS"
export DEBUG="*"
alias debuglog='cat $DEBUG_LOG'
alias halogs='ha core logs --tail 200'
EOF

# 4. Create GEMINI.md
cat > "$WORKING_DIR/GEMINI.md" << EOF
# Home Assistant Add-on Environment (DEBUG MODE)
- Log File: $DEBUG_LOG
- Node Options: $NODE_OPTIONS
EOF

# 5. MCP Config
if [ "$ENABLE_MCP" = "true" ]; then
    (
        gemini mcp remove homeassistant 2>/dev/null || true
        gemini mcp add homeassistant hass-mcp --env "HA_URL=http://supervisor/core" --env "HA_TOKEN=$SUPERVISOR_TOKEN" 2>&1 >> "$DEBUG_LOG" || true
    ) &
fi

# 6. Start ttyd
COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
[ "$THEME" != "dark" ] && COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"

# Der Befehl fängt jetzt ALLES ab und schreibt es in die debug.log
RUN_CMD="bash --login"
if [ "$SESSION_PERSIST" = "true" ]; then
    tmux has-session -t gemini 2>/dev/null || tmux new-session -d -s gemini
    RUN_CMD="tmux attach-session -t gemini"
fi

echo "[INFO] Launching terminal with full logging to $DEBUG_LOG"
cd "$WORKING_DIR"

# Wir loggen die gesamte Terminal-Sitzung in die Datei
exec ttyd --port 7681 --writable --ping-interval 10 --max-clients 5 \
    -t "fontSize=$FONT_SIZE" \
    -t "theme=$COLORS" \
    sh -c "script -f -q -c '$RUN_CMD' $DEBUG_LOG"
