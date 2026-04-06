#!/bin/bash
set -e

echo "[INFO] Starting Gemini CLI for Home Assistant (v0.3.6)..."

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
if [ ! -L /root/.gemini ]; then
    rm -rf /root/.gemini
    ln -s "$PERSIST_DIR" /root/.gemini
fi

# 3. Environment
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export NODE_OPTIONS="--max-old-space-size=4096" # Increased to 4GB if available

# Prepare .bashrc (clean and set aliases)
sed -i '/export GEMINI_API_KEY/d' /root/.bashrc
sed -i '/export HA_TOKEN/d' /root/.bashrc
sed -i '/export HA_URL/d' /root/.bashrc
sed -i '/export NODE_OPTIONS/d' /root/.bashrc
sed -i "/alias halogs/d" /root/.bashrc

cat >> /root/.bashrc << EOF
export GEMINI_API_KEY="$API_KEY"
export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"
export NODE_OPTIONS="--max-old-space-size=4096"
alias halogs='ha core logs --tail 200'
EOF

# 4. Create GEMINI.md (with safety hints)
cat > "$WORKING_DIR/GEMINI.md" << EOF
# Home Assistant Add-on Environment

## STABILITY WARNING
- **LOGS:** NEVER run \`ha core logs\` without filtering or tailing. It can be massive.
- **USE:** \`halogs | grep ...\` instead of the full command.
- **FILES:** Avoid reading binary files or very large directories.

## Path Mapping
- /homeassistant = HA config directory
- Always translate /config/... to /homeassistant/...
EOF

# 5. MCP Config
if [ "$ENABLE_MCP" = "true" ]; then
    (
        gemini mcp remove homeassistant 2>/dev/null || true
        gemini mcp add homeassistant hass-mcp --env "HA_URL=http://supervisor/core" --env "HA_TOKEN=$SUPERVISOR_TOKEN" 2>/dev/null || true
    ) &
fi

# 6. Theme & Start
COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
[ "$THEME" != "dark" ] && COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"

# Safety Loop: If the shell/tmux crashes, restart it immediately
# This prevents the whole addon from dying
RUN_CMD="bash --login"
if [ "$SESSION_PERSIST" = "true" ]; then
    tmux has-session -t gemini 2>/dev/null || tmux new-session -d -s gemini
    RUN_CMD="tmux attach-session -t gemini"
fi

echo "[INFO] Launching terminal with crash-protection..."
cd "$WORKING_DIR"

# The inner loop keeps the terminal open even if the command crashes
exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 \
    -t "fontSize=$FONT_SIZE" \
    -t "theme=$COLORS" \
    -t "disableLeaveAlert=true" \
    sh -c "while true; do $RUN_CMD; echo 'Session crashed/exited. Restarting in 2s...'; sleep 2; done"
