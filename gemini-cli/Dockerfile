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
    util-linux \
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

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/bin/bash", "/run.sh"]
