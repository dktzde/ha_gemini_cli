ARG BUILD_FROM
FROM ${BUILD_FROM}

# Labels
LABEL maintainer="dktzde"
LABEL org.opencontainers.image.title="Gemini CLI for Home Assistant"
LABEL org.opencontainers.image.description="Google Gemini CLI with web terminal and HA integration"
LABEL org.opencontainers.image.source="https://github.com/dktzde/ha_gemini_cli"
LABEL org.opencontainers.image.licenses="MIT"

# Environment setup
ENV \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Install system dependencies (Node.js >= 20 required for Gemini CLI)
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nodejs \
    npm \
    openssh-client \
    ncurses \
    vim \
    nano \
    tmux \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    ca-certificates \
    openssl \
    ripgrep \
    && update-ca-certificates

# Install ttyd static binary (web terminal)
ARG BUILD_ARCH
RUN case "${BUILD_ARCH}" in \
        amd64) TTYD_ARCH="x86_64" ;; \
        aarch64) TTYD_ARCH="aarch64" ;; \
        *) TTYD_ARCH="x86_64" ;; \
    esac && \
    curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${TTYD_ARCH}" -o /usr/bin/ttyd && \
    chmod +x /usr/bin/ttyd

# Install Gemini CLI via npm
RUN npm install -g @google/gemini-cli

# Install hass-mcp for Home Assistant MCP integration
RUN pip3 install --no-cache-dir --break-system-packages hass-mcp

# Install Home Assistant CLI
RUN case "${BUILD_ARCH}" in \
        amd64) HA_ARCH="amd64" ;; \
        aarch64) HA_ARCH="aarch64" ;; \
        *) HA_ARCH="amd64" ;; \
    esac && \
    curl -fsSL "https://github.com/home-assistant/cli/releases/latest/download/ha_${HA_ARCH}" -o /usr/local/bin/ha && \
    chmod +x /usr/local/bin/ha

# Create necessary directories
RUN mkdir -p \
    /homeassistant \
    /root/.config \
    /root/.local/bin \
    /etc/profile.d

# Configure tmux
RUN cat > /root/.tmux.conf << 'EOF'
set -g history-limit 20000
set -ga terminal-overrides ',xterm*:smcup@:rmcup@'
set -g mouse on
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M
EOF

# Configure bash with aliases and prompt
RUN cat > /root/.bashrc << 'BASHEOF'
export TERM=xterm-256color
export LANG=C.UTF-8

# Source runtime environment (written by startup script)
[ -f /etc/profile.d/gemini-env.sh ] && source /etc/profile.d/gemini-env.sh

PS1='\[\033[1;34m\]gemini-cli\[\033[0m\]:\[\033[1;36m\]\w\[\033[0m\]\$ '

# Aliases (yolo mode handled via CLI flag in alias if enabled)
alias ll='ls -la'
alias g='gemini $GEMINI_FLAGS'
alias gr='gemini -r "latest" $GEMINI_FLAGS'
alias ha-config='cd /homeassistant'
alias ha-logs='cat /homeassistant/home-assistant.log 2>/dev/null || echo "Log not found"'
BASHEOF

# Ensure .bashrc is sourced for login shells
RUN echo 'source ~/.bashrc' > /root/.profile

# Set up PATH
ENV PATH="/root/.local/bin:${PATH}"

# Set working directory
WORKDIR /homeassistant

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:7681/ || exit 1

# Copy startup script (kept for reference but not as entrypoint)
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT []
CMD ["/bin/bash", "-c", "\
  OPTIONS_FILE='/data/options.json' && \
  API_KEY=$(jq -r '.api_key // \"\"' \"$OPTIONS_FILE\") && \
  MODEL=$(jq -r '.model // \"auto\"' \"$OPTIONS_FILE\") && \
  YOLO_MODE=$(jq -r '.yolo_mode // false' \"$OPTIONS_FILE\") && \
  ENABLE_MCP=$(jq -r '.enable_mcp // true' \"$OPTIONS_FILE\") && \
  FONT_SIZE=$(jq -r '.terminal_font_size // 14' \"$OPTIONS_FILE\") && \
  THEME=$(jq -r '.terminal_theme // \"dark\"' \"$OPTIONS_FILE\") && \
  SESSION_PERSIST=$(jq -r '.session_persistence // true' \"$OPTIONS_FILE\") && \
  AUTO_UPDATE=$(jq -r '.auto_update_gemini // true' \"$OPTIONS_FILE\") && \
  WORKING_DIR=$(jq -r '.working_directory // \"/homeassistant\"' \"$OPTIONS_FILE\") && \
  if [ -z \"$API_KEY\" ]; then \
    echo '[WARNING] No Gemini API key found in configuration.'; \
    echo '[INFO] You can still use the terminal and set your key later.'; \
    echo '[INFO] To set your key in the terminal, run: gemini auth login'; \
    echo '[INFO] Get your API key at https://aistudio.google.com/apikey'; \
  else \
    echo '[INFO] Gemini API key found. Configuration complete.'; \
  fi && \
  PERSIST_DIR='/homeassistant/.gemini-cli' && \
  mkdir -p \"$PERSIST_DIR\" && \
  if [ ! -L /root/.gemini ]; then rm -rf /root/.gemini; ln -s \"$PERSIST_DIR\" /root/.gemini; fi && \
  printf \"# Home Assistant Add-on Environment\\n\\n## Path Mapping\\n\\nIn this container:\\n- /homeassistant = HA config (equivalent to /config in HA Core)\\n- Always translate /config/... to /homeassistant/...\\n\\n## Available Paths\\n\\n| Path | Description | Access |\\n|------|-------------|--------|\\n| /homeassistant | HA config | read-write |\\n| /share | Shared folder | read-write |\\n| /media | Media files | read-write |\\n| /ssl | SSL certs | read-only |\\n| /backup | Backups | read-only |\\n\" > \"$WORKING_DIR/GEMINI.md\" && \
  GEMINI_FLAGS='' && \
  if [ \"$YOLO_MODE\" = \"true\" ]; then GEMINI_FLAGS='--yolo'; echo '[INFO] YOLO mode enabled'; fi && \
  if [ \"$MODEL\" != \"auto\" ]; then GEMINI_FLAGS=\"$GEMINI_FLAGS -m $MODEL\"; echo \"[INFO] Model set to: $MODEL\"; fi && \
  printf \"export GEMINI_API_KEY='%s'\\nexport HA_TOKEN='%s'\\nexport HA_URL='http://supervisor/core'\\nexport GEMINI_FLAGS='%s'\\n\" \"$API_KEY\" \"$SUPERVISOR_TOKEN\" \"$GEMINI_FLAGS\" > /etc/profile.d/gemini-env.sh && \
  export GEMINI_API_KEY=\"$API_KEY\" && \
  export HA_TOKEN=\"$SUPERVISOR_TOKEN\" && \
  export HA_URL=\"http://supervisor/core\" && \
  export GEMINI_FLAGS && \
  if [ \"$AUTO_UPDATE\" = \"true\" ]; then \
    echo '[INFO] Checking for Gemini CLI updates...'; \
    npm update -g @google/gemini-cli 2>/dev/null || echo '[WARN] Update check failed'; \
  fi && \
  gemini mcp remove homeassistant 2>/dev/null || true && \
  if [ \"$ENABLE_MCP\" = \"true\" ]; then \
    gemini mcp add homeassistant hass-mcp --env \"HA_URL=http://supervisor/core\" --env \"HA_TOKEN=$SUPERVISOR_TOKEN\" 2>/dev/null || \
    jq -n \"{\\\"mcpServers\\\":{\\\"homeassistant\\\":{\\\"command\\\":\\\"hass-mcp\\\",\\\"env\\\":{\\\"HA_URL\\\":\\\"http://supervisor/core\\\",\\\"HA_TOKEN\\\":\\\"$SUPERVISOR_TOKEN\\\"}}}}\" > \"$PERSIST_DIR/settings.json\"; \
    echo '[INFO] MCP configured'; \
  fi && \
  if [ \"$THEME\" = \"dark\" ]; then COLORS='background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc'; else COLORS='background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78'; fi && \
  if [ \"$SESSION_PERSIST\" = \"true\" ]; then SHELL_CMD='tmux new-session -A -s gemini'; else SHELL_CMD='bash --login'; fi && \
  cd \"$WORKING_DIR\" && \
  exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 -t \"fontSize=$FONT_SIZE\" -t \"fontFamily=Monaco,Consolas,monospace\" -t \"scrollback=20000\" -t \"theme=$COLORS\" $SHELL_CMD \
"]
