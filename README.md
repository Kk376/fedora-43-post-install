# Fedora 43 Post-Install Setup Script

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

---

## Key Features

- 🔹 **Fully interactive** – every step asks before running
- 🔹 **Safe by design** – no blind execution
- 🔹 **Hardware-aware**
  - Intel / AMD / NVIDIA GPU detection
  - Hybrid (Optimus) awareness
- 🔹 **Secure Boot–aware NVIDIA setup**
- 🔹 **Idempotent**
  - Prevents duplicate configs
  - Skips already-installed components
- 🔹 **Clean logging & progress tracking**
- 🔹 **Modular** – each task is isolated and readable

## What’s New in v2.0

Version 2.0 introduces safety, predictability, and reversibility.

### New Capabilities
- **Backup & Restore** – Automatically backs up existing configurations and allows rollback
- **Dry-Run Mode** – Preview all actions without modifying the system
- **Logging** – Full execution log written to file for debugging
- **Version Awareness** – Skips already-installed or correctly configured components
- **Validation** – Verifies system state after each major step

These changes make the script suitable for cautious users and repeat executions.


---

## Who This Script Is For

✅ Fedora power users  
✅ Developers  
✅ Gamers  
✅ Laptop users who care about battery life  
❌ Beginners who don’t want to read prompts  
❌ Blind “one-click” installers  

This script **assumes you understand Fedora** and want a **clean, correct setup**, not magic.

---

## Supported System

- **OS:** Fedora 43 Workstation
- **Desktop:** GNOME
- **Shell:** Bash (script), ZSH (optional install)
- **Tested on:** Intel, AMD, NVIDIA systems (desktop & laptop)

---

## Important Warnings

- Some steps **require reboot** (drivers, Docker, Secure Boot)
- NVIDIA users **must read Secure Boot prompts carefully**
- ZSH default shell change requires **logout/login**
- Docker group changes require **reboot or re-login**
- LM Studio AppImage must be available in `~/Downloads` (optional auto-download)

---

## What the Script Installs & Configures

### Core System
- DNF optimizations
- RPM Fusion & Flathub
- Google DNS (IPv4 + IPv6)
- No-random-sleep (GDM + user)
- System fonts + Nerd Fonts

### Power & Performance
- TLP (with delayed boot fix)
- preload
- ccache (50GB, compressed)

### Shell & UX
- ZSH
- Oh My Zsh
- Powerlevel10k
- zsh-autosuggestions
- zsh-syntax-highlighting
- eza, bat aliases

### Multimedia & Browsers
- Brave Browser
- FFmpeg (freeworld)
- VA-API / NVENC support
- OpenH264

### GPU Drivers
- Intel media driver
- AMD freeworld VA/VDAU
- NVIDIA proprietary drivers
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

### GNOME Tools
- GNOME Tweaks
- Extension Manager
- Extension recommendations (manual install)

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

