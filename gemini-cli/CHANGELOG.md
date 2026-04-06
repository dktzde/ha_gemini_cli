# Changelog

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
