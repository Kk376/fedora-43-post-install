# Fedora 43 Post-Install Setup Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **fully interactive, modular, and safe** post-installation automation script for  
**Fedora 43 Workstation (GNOME)**.

This script is built from **years of real-world Fedora usage**, focusing on:

- Performance & stability
- Battery life (laptops)
- Proper multimedia & hardware acceleration
- Developer tooling
- Gaming (Steam, Proton, MangoHud)
- Secure NVIDIA driver handling (including Secure Boot)
- GNOME usability
- ZSH + Powerlevel10k
- Cloudflare Warp
- Docker & modern dev workflows
- Local AI tooling (LM Studio, Gemini CLI)
- **KVM/QEMU virtualization** (new in v4.0)

---

## Key Features

- 🔹 **Fully interactive** – every step asks before running
- 🔹 **Safe by design** – disk space checks, network validation, emergency rollback
- 🔹 **Hardware-aware**
  - Intel / AMD / NVIDIA GPU detection
  - Hybrid (Optimus) awareness
  - CPU virtualization detection (VT-x/AMD-V)
- 🔹 **Secure Boot–aware NVIDIA setup**
- 🔹 **Idempotent**
  - State file tracks completed steps
  - Resume after interruption
  - `--force` to re-run steps
- 🔹 **Profile-based installation** (6 profiles)
- 🔹 **Emergency rollback** on errors
- 🔹 **Clean logging & progress tracking**
- 🔹 **Modular** – each task is isolated and readable

---

## What's New in v4.0.0

### New Features

- **KVM/QEMU Virtualization** – Complete Type 1 hypervisor setup with modern socket activation
- **New Profiles** – `workstation` and `creator` for specialized workflows
- **Emergency Rollback** – Automatic service stopping and recovery guidance on failure
- **Disk Space Protection** – Warns if <20GB available before installation
- **Atomic DNF Operations** – Version pinning (`best=True`) for predictable updates

### Improved Safety

- Network validation before remote operations
- Better error recovery with state preservation
- Service isolation (Docker, libvirt, TLP)
- Proper user group management

---

## Usage

```bash
# Basic usage (full profile, interactive)
./setup.sh

# Preview without changes
./setup.sh --dry-run

# Minimal install (DNF, fonts, shell only)
./setup.sh --profile=minimal

# Developer setup
./setup.sh --profile=dev

# Gaming setup
./setup.sh --profile=gaming

# Workstation (Dev + Office + Virtualization)
./setup.sh --profile=workstation

# Content Creator (Gaming + Multimedia + AI tools)
./setup.sh --profile=creator

# Re-run completed steps
./setup.sh --force
```

### Available Profiles

| Profile       | Steps Included                                            |
| ------------- | --------------------------------------------------------- |
| `minimal`     | DNF, fonts, shell                                         |
| `dev`         | Minimal + dev tools, Docker, Antigravity, Gemini CLI, KVM |
| `gaming`      | Minimal + drivers, packages, MangoHud, Flatpaks           |
| `workstation` | Dev + DNS, Office, KVM/QEMU virtualization                |
| `creator`     | Gaming + Multimedia, COPR tools, LM Studio, Gemini CLI    |
| `full`        | All 22 steps (default)                                    |

---

## Who This Script Is For

✅ Fedora power users  
✅ Developers  
✅ Gamers  
✅ Content creators & AI enthusiasts  
✅ Laptop users who care about battery life  
✅ Virtualization / homelab users  
❌ Beginners who don't want to read prompts  
❌ Blind "one-click" installers

This script **assumes you understand Fedora** and want a **clean, correct setup**, not magic.

---

## Supported System

- **OS:** Fedora 43 Workstation
- **Desktop:** GNOME
- **Shell:** Bash (script), ZSH (optional install)
- **Tested on:** Intel, AMD, NVIDIA systems (desktop & laptop)

---

## Important Warnings

- Some steps **require reboot** (drivers, Docker, Secure Boot, KVM)
- NVIDIA users **must read Secure Boot prompts carefully**
- ZSH default shell change requires **logout/login**
- Docker/libvirt group changes require **reboot or re-login**
- LM Studio AppImage must be available in `~/Downloads` (optional auto-download)
- Minimum **20GB disk space** recommended

---

## What the Script Installs & Configures

### Core System

- DNF optimizations (parallel downloads, version pinning, fastest mirror)
- RPM Fusion & Flathub
- DNS (optional: Google/Cloudflare)
- No-random-sleep (GDM + user)
- System fonts + Nerd Fonts

### Power & Performance

- TLP (optional, with GNOME PPD warning)
- preload
- ccache (50GB, compressed)
- tuned virtual-host profile (for KVM)

### Shell & UX

- ZSH + Oh My Zsh + Powerlevel10k
- zsh-autosuggestions / zsh-syntax-highlighting
- eza, bat aliases

### Multimedia & Browsers

- Brave Browser
- FFmpeg (freeworld)
- VA-API / NVENC support
- OpenH264

### GPU Drivers

- Intel media driver
- AMD freeworld VA/VDPAU
- NVIDIA proprietary drivers
  - `akmods --force` before MOK enrollment
  - Secure Boot key generation
  - Interactive MOK enrollment guidance

### Development

- GCC / Clang / LLVM
- Java, Node.js, Python
- Docker + Corepack
- Rust (optional)
- Android tools
- Debuggers, profilers, build systems

### Gaming

- Steam + H.264 unlock
- MangoHud (preconfigured)
- ProtonPlus

### Cloud & AI

- Cloudflare Warp
- LM Studio (AppImage integration)
- Gemini CLI

### Virtualization (New!)

- KVM/QEMU with modern socket activation
- libvirt, virt-manager, virt-install
- VirtIO drivers for Windows VMs
- Firewall and network configuration
- Storage pool setup guidance

### GNOME Tools

- GNOME Tweaks
- Extension Manager
- Extension recommendations (manual install)

---

## Troubleshooting

### Script failed mid-installation

The script preserves state on failure. Simply re-run it to continue from the last successful step.

### Low disk space warning

Ensure at least 20GB free space. The script will warn but allow you to continue.

### Docker not working after install

Reboot or re-login to apply group membership changes:

```bash
sudo systemctl reboot
docker run --rm hello-world
```

### KVM/QEMU permission denied

After installation, run the post-reboot commands shown by the script, or:

```bash
sudo usermod -aG libvirt $USER
# Then reboot
```

### NVIDIA drivers not loading

Complete the MOK enrollment during boot (blue MOK Manager screen).

---

## How to Use

### 1️⃣ Clone the repository

```bash
git clone https://github.com/Kk376/fedora-43-post-install.git
cd fedora-43-post-install
```

### 2️⃣ Make the script executable

```bash
chmod +x setup.sh
```

### 3️⃣ Run the script

```bash
./setup.sh
```

You will be prompted before each major step.

---

Built and maintained by **Kushagra Kumar**.

---

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.
