# Changelog

All notable changes to this project will be documented in this file.

This project follows semantic versioning: **MAJOR.MINOR.PATCH**

---

## [v4.0.0] – 2026-01-21

### Added

- **New profiles** – `workstation` (Dev + Virtualization + Office) and `creator` (Gaming + Multimedia + AI tools)
- **Emergency rollback system** – Automatic service stopping and recovery guidance on script failure
- **Disk space protection** – Checks for minimum 20GB before installation, with interactive warning
- **KVM/QEMU Virtualization** – Complete setup module with modern socket activation (`virtqemud.socket`)
- **Atomic DNF operations** – Version pinning (`best=True`) and safer repository installation
- **Enhanced safety** – Network checks, disk space validation, emergency traps

### Improved

- **DNF configuration** – Added `best=True` for version pinning, atomic RPM Fusion installation
- **Profile system** – More logical segmentation with workstation/creator profiles
- **Error handling** – State file preserved on error for resumption
- **User experience** – Better progress tracking and validation messages
- **Virtualization setup** – Modern libvirt socket activation instead of legacy service
- **Documentation** – Updated README with new features and troubleshooting guide

### Fixed

- **Dry-run state counting** – Progress counter now works correctly in dry-run mode
- **Service management** – Proper stopping of services during emergency rollback
- **Permission handling** – Better user group management for Docker and libvirt
- **Profile step filters** – Correct step inclusion for new profiles

### Security

- **Rollback protection** – Stops potentially dangerous services on failure
- **Resource validation** – Prevents installation on low disk space
- **Network dependency** – Validates internet before remote operations
- **Service isolation** – Proper firewall and NetworkManager configuration

---

## [v3.0.0] – 2026-01-17

### Added

- **Profile system** – `--profile=minimal|dev|gaming|full` for targeted installations
- **State file** – `~/.config/fedora-setup/state.txt` tracks completed steps for idempotency
- **`--force` flag** – Re-run already-completed steps
- **DNS provider choice** – Google, Cloudflare, or skip (default: skip)
- **TLP opt-in** – User choice with warning about GNOME power profiles
- **RPM Fusion validation** – Warns before multimedia if not installed
- **Dynamic step counting** – TOTAL_STEPS calculated based on profile

### Improved

- **NVIDIA Secure Boot flow** – `akmods --force` + `modinfo` check before MOK enrollment
- **DNF config** – Uses `# BEGIN/END fedora-setup` block markers for true idempotency
- **GPU detection** – More specific pattern (`VGA|3D|Display`) to avoid false positives
- **Dry-run mode** – DNS step skipped, progress counters only increment in real runs
- **Restore safety** – State file reset after backup restore
- **Cleanup** – Only runs for `full` profile

### Removed

- Unused `check_existing_config()` function
- `alsa-plugins-pulseaudio` (unnecessary on PipeWire)

---

## [v2.0.2] – 2026-01-16

### Added

- Explicitly enabled `fedora-cisco-openh264` repository to ensure OpenH264 availability

---

## [v2.0.1] – 2026-01-16

### Fixed

- Fix typo: keepcache in dnf.conf

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
