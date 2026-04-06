# Changelog

## [0.3.5] - 2026-04-06

### Changed
- Updated `GEMINI.md` with strict instructions for YAML indentation and syntax.
- Added requirement to follow the latest Home Assistant documentation standards.
- Included a reference to `CLAUDE.md` in `GEMINI.md` for cross-assistant context.

## [0.3.4] - 2026-04-06

### Improved
- Fixed `Permission denied` error for environment variables by properly writing to `.bashrc` only.
- Enhanced terminal stability by using a more robust `tmux` attachment strategy.
- Reduced WebSocket timeouts by decreasing the ping interval to 10 seconds.
- Backgrounded MCP configuration to speed up startup.
- Prevented duplicate environment exports in `.bashrc`.

## [0.3.3] - 2026-04-06

### Improved
- Increased Node.js memory limit to `2048MB` to prevent crashes when reading large or binary files.
- Updated `GEMINI.md` with critical instructions to avoid binary log files in `/var/log` and use `ha core logs` instead.
- Switched back to a cleaner `ENTRYPOINT` in the `Dockerfile`.
- Optimized addon privileges for better stability.

## [0.3.2] - 2026-04-06

### Changed
- Reverted to using a dedicated `run.sh` script for startup (now compatible with `full_access` mode).
- Improved environment variable handling by writing to `/root/.bashrc` instead of `/etc/profile.d`.
- Fixed potential crashes when reading/writing `GEMINI.md` by using more robust script logic.

## [0.3.1] - 2026-04-06

### Added
- Automatically create `GEMINI.md` in the working directory on startup to provide context for the AI about Home Assistant paths and environment.

## [0.3.0] - 2026-04-06

### Changed
- Adopted "full_access" mode for maximum compatibility and to resolve persistent permission issues.
- Moved startup logic directly into `Dockerfile` `CMD` to eliminate `Permission denied` errors on external scripts.
- Disabled AppArmor and enabled privileged mode (`SYS_ADMIN`).
- Enabled host network and Docker API access.

## [0.2.2] - 2026-04-06

### Changed
- Make API key optional at startup. The terminal will now start even if no key is provided in the configuration.
- Added instructions on how to set the API key manually using `gemini auth login` within the terminal.

## [0.2.1] - 2026-04-06

### Fixed
- Correct AppArmor profile naming convention to `addon_gemini_cli`.
- Explicitly enable `apparmor: true` in configuration.
- Use explicit `bash` call for `run.sh` in Dockerfile to ensure execution.

## [0.2.0] - 2026-04-06

### Fixed
- Resolve `Permission denied` error for `run.sh` by adding execution bit in git index.
- Update AppArmor profile to explicitly allow execution of `/run.sh`.

## [0.1.0] - 2026-03-28

### Added
- Initial release
- Web-based terminal via ttyd with Home Assistant Ingress
- Google Gemini CLI integration with configurable model selection (auto, pro, flash, flash-lite)
- Home Assistant MCP integration via hass-mcp (entity control, service calls)
- YOLO mode for auto-approving all tool executions
- Session persistence via tmux
- Configurable terminal theme (dark/light) and font size
- Auto-update option for Gemini CLI
- Persistent configuration storage in /homeassistant/.gemini-cli
- Home Assistant CLI (`ha` command) included
- GEMINI.md with HA path mapping instructions
- Bash aliases for quick access (g, gr, ha-config, ha-logs)
- Support for amd64 and aarch64 architectures
