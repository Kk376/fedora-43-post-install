# Changelog

All notable changes to this project will be documented in this file.

This project follows semantic versioning: **MAJOR.MINOR.PATCH**

---

## [v2.0.0] – 2026-01-16

### Added
- Backup functionality for existing system and user configuration files before modification
- Restore mode to roll back changes using saved backups
- Dry-run mode to preview all actions without making any system changes
- Logging to file for easier debugging and auditing
- Post-step validation to verify successful configuration after each major step
- Version and state checks to avoid unnecessary re-installation or overwrites

### Improved
- Overall script safety and predictability
- Idempotency of installation steps
- Error visibility and troubleshooting experience
- Script usability for advanced and cautious users

### Notes
- v2.0 is a **breaking change** internally due to new execution flow
- Existing users are recommended to review dry-run output before upgrading

---

## [v1.0.0] – Initial Release

### Added
- Interactive Fedora 43 post-install automation script
- DNF optimizations and repository setup
- Power management (TLP) with boot-time fix
- GPU driver detection (Intel / AMD / NVIDIA with Secure Boot support)
- ZSH + Powerlevel10k setup
- Multimedia, gaming, and development environment configuration
- Cloudflare Warp, Docker, Antigravity, LM Studio integration
