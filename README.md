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
  - State file tracks completed steps
  - Resume after interruption
  - `--force` to re-run steps
- 🔹 **Profile-based installation**
- 🔹 **Clean logging & progress tracking**
- 🔹 **Modular** – each task is isolated and readable

---

## What's New in v3.0

- **Profile System** – `--profile=minimal|dev|gaming|full`
- **State File** – Tracks completed steps, enables resume
- **Force Flag** – `--force` to re-run completed steps
- **DNS Choice** – Google, Cloudflare, or skip (default: skip)
- **TLP Opt-in** – Clear warning about GNOME power profiles impact

### Improved Safety

- **NVIDIA flow** – `akmods --force` before MOK enrollment
- **DNF config** – Idempotent block markers
- **Dry-run mode** – Skips interactive steps, no state changes
- **GPU detection** – More specific pattern avoids false positives

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

# Re-run completed steps
./setup.sh --force
```

### Available Profiles

| Profile   | Steps Included                                       |
| --------- | ---------------------------------------------------- |
| `minimal` | DNF, fonts, shell                                    |
| `dev`     | Minimal + dev tools, Docker, Antigravity, Gemini CLI |
| `gaming`  | Minimal + drivers, packages, MangoHud, Flatpaks      |
| `full`    | All 20 steps (default)                               |

---

## Who This Script Is For

✅ Fedora power users  
✅ Developers  
✅ Gamers  
✅ Laptop users who care about battery life  
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

- Some steps **require reboot** (drivers, Docker, Secure Boot)
- NVIDIA users **must read Secure Boot prompts carefully**
- ZSH default shell change requires **logout/login**
- Docker group changes require **reboot or re-login**
- LM Studio AppImage must be available in `~/Downloads` (optional auto-download)

---

## What the Script Installs & Configures

### Core System

- DNF optimizations (idempotent block markers)
- RPM Fusion & Flathub
- DNS (optional: Google/Cloudflare)
- No-random-sleep (GDM + user)
- System fonts + Nerd Fonts

### Power & Performance

- TLP (optional, with GNOME PPD warning)
- preload
- ccache (50GB, compressed)

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
