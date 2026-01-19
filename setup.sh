#!/bin/bash
# ==============================================================================
# Fedora 43 Post-Install Setup Script
# Author: Kushagra Kumar
# Automates DevTools + Gaming + Multimedia on Fedora 43
# Version: 3.0
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Configuration & Flags
# ==============================================================================
DRY_RUN=false
BACKUP_DIR="$HOME/.config/fedora-setup-backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/fedora-setup-$(date +%Y%m%d_%H%M%S).log"
SCRIPT_VERSION="3.0"
PROFILE="full"
FORCE_RERUN=false
STATE_FILE="$HOME/.config/fedora-setup/state.txt"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --force|-f)
            FORCE_RERUN=true
            shift
            ;;
        --help|-h)
            echo "Fedora 43 Post-Install Setup Script v${SCRIPT_VERSION}"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run, -n          Preview changes without executing"
            echo "  --profile=PROFILE      Choose setup profile:"
            echo "                           minimal - DNF, fonts, shell only"
            echo "                           dev     - Minimal + dev tools, Docker, Antigravity"
            echo "                           gaming  - Minimal + drivers, packages, MangoHud"
            echo "                           full    - All steps (default)"
            echo "  --force, -f            Re-run completed steps"
            echo "  --help, -h             Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate profile
case "$PROFILE" in
    minimal|dev|gaming|full) ;;
    *) echo "Unknown profile: $PROFILE (use minimal, dev, gaming, or full)"; exit 1 ;;
esac

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Enable logging to file
exec > >(tee -a "$LOG_FILE") 2>&1

# Logging functions
log() { echo -e "${BLUE}[SETUP]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
dry() { echo -e "${MAGENTA}[DRY-RUN]${NC} Would execute: $1"; }

# Progress tracking
COMPLETED_STEPS=0
TOTAL_STEPS=20
START_TIME=$(date +%s)

step_complete() {
    echo -e "\n${GREEN}[${COMPLETED_STEPS}/${TOTAL_STEPS}]${NC} $1"
}

# ==============================================================================
# Enhanced Helper Functions
# ==============================================================================

# Execute command (or dry-run)
run() {
    if $DRY_RUN; then
        dry "$*"
        return 0
    else
        "$@"
    fi
}

# Execute sudo command (or dry-run)
run_sudo() {
    if $DRY_RUN; then
        dry "sudo $*"
        return 0
    else
        sudo "$@"
    fi
}

# Backup a file before modifying
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name=$(basename "$file").backup
        cp "$file" "$BACKUP_DIR/$backup_name"
        info "Backed up: $file → $BACKUP_DIR/$backup_name"
    fi
}

# Restore backups
restore_backups() {
    local latest_backup=$(ls -td ~/.config/fedora-setup-backups/*/ 2>/dev/null | head -1)
    if [[ -z "$latest_backup" ]]; then
        warn "No backups found"
        return 1
    fi
    
    log "Latest backup: $latest_backup"
    if confirm "Restore all files from this backup?" "N"; then
        for backup_file in "$latest_backup"/*; do
            local filename=$(basename "$backup_file" .backup)
            local original_paths=(
                "$HOME/.zshrc"
                "$HOME/.bashrc"
                "/etc/dnf/dnf.conf"
                "$HOME/.config/MangoHud/MangoHud.conf"
            )
            for orig in "${original_paths[@]}"; do
                if [[ "$(basename "$orig")" == "$filename" ]]; then
                    if $DRY_RUN; then
                        dry "cp $backup_file $orig"
                    else
                        sudo cp "$backup_file" "$orig" 2>/dev/null || cp "$backup_file" "$orig"
                        success "Restored: $orig"
                    fi
                    break
                fi
            done
        done
        # Reset state file after restore to prevent stale state
        if ! $DRY_RUN; then
            rm -f "$STATE_FILE"
            warn "State reset due to restore - all steps will re-run"
        fi
    fi
}

# Check if package is installed and get version
check_version() {
    local pkg="$1"
    if rpm -q "$pkg" &>/dev/null; then
        local ver=$(rpm -q --queryformat '%{VERSION}' "$pkg" 2>/dev/null)
        echo "$ver"
        return 0
    elif command -v "$pkg" &>/dev/null; then
        local ver=$("$pkg" --version 2>/dev/null | head -1 || echo "installed")
        echo "$ver"
        return 0
    fi
    return 1
}

# Validate step completion
validate_step() {
    local step_name="$1"
    local check_cmd="$2"
    
    if eval "$check_cmd" &>/dev/null; then
        success "Validated: $step_name"
        return 0
    else
        warn "Validation failed: $step_name"
        return 1
    fi
}

# ==============================================================================
# State File Functions (Idempotency)
# ==============================================================================
init_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    [[ -f "$STATE_FILE" ]] || touch "$STATE_FILE"
}

is_step_completed() {
    local step="$1"
    [[ -f "$STATE_FILE" ]] && grep -qx "$step" "$STATE_FILE"
}

mark_step_completed() {
    local step="$1"
    if ! is_step_completed "$step"; then
        echo "$step" >> "$STATE_FILE"
    fi
}

reset_state() {
    if confirm "Clear all completed step records?" "N"; then
        rm -f "$STATE_FILE"
        success "State cleared - all steps will re-run"
    fi
}

# Confirmation prompt
confirm() {
    local prompt="$1" default="${2:-N}" yn
    if $DRY_RUN; then
        dry "Prompt: $prompt (auto-yes in dry-run)"
        return 0
    fi
    [[ "$default" == "Y" ]] && read -p "$prompt (Y/n): " -n 1 -r yn || read -p "$prompt (y/N): " -n 1 -r yn
    echo
    [[ "$default" == "Y" ]] && { [[ -z "$yn" ]] || [[ "$yn" =~ ^[Yy]$ ]]; } || [[ "$yn" =~ ^[Yy]$ ]]
}

# Network check
check_network() {
    ping -c 1 -W 2 8.8.8.8 &>/dev/null || ping -c 1 -W 2 1.1.1.1 &>/dev/null
}

# Show installed versions
show_versions() {
    log "Checking installed versions..."
    echo ""
    local packages=("zsh" "brave-browser" "code" "antigravity" "docker" "tlp" "steam" "ffmpeg")
    for pkg in "${packages[@]}"; do
        local ver=$(check_version "$pkg" 2>/dev/null)
        if [[ -n "$ver" ]]; then
            echo "  ✅ $pkg: $ver"
        else
            echo "  ❌ $pkg: not installed"
        fi
    done
    echo ""
}

# Sudo check and keep-alive
if ! $DRY_RUN; then
    sudo -v || { error "Requires sudo"; exit 1; }
    while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
fi


# ==============================================================================
# 1. DNF Configuration
# ==============================================================================
setup_dnf() {
    log "Configuring DNF..."
    
    # Backup config before modifying
    backup_file "/etc/dnf/dnf.conf"
    
    # Use idempotent block markers - remove old block if exists, then add fresh
    if ! $DRY_RUN; then
        sudo sed -i '/^# BEGIN fedora-setup$/,/^# END fedora-setup$/d' /etc/dnf/dnf.conf
        
        local dnf_opts="fastestmirror=True\nmax_parallel_downloads=10\nkeepcache=True"
        confirm "Enable defaultyes (auto-confirm)?" "N" && dnf_opts+="\ndefaultyes=True"
        
        sudo tee -a /etc/dnf/dnf.conf > /dev/null <<EOF
# BEGIN fedora-setup
$(echo -e "$dnf_opts")
# END fedora-setup
EOF
    else
        dry "Add fedora-setup block to dnf.conf (idempotent)"
    fi
    
    log "Enabling RPM Fusion & Flathub..."
    run_sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || warn "Flathub already configured or failed"
    
    run_sudo dnf update -y --refresh
    
    # Validation
    validate_step "DNF config" "grep -q '# BEGIN fedora-setup' /etc/dnf/dnf.conf"
    
    step_complete "DNF configured"
}

# ==============================================================================
# 2. DNS Configuration
# ==============================================================================
setup_dns() {
    # Dry-run safety: DNS changes are interactive and can't be simulated
    if $DRY_RUN; then
        dry "DNS configuration (interactive step skipped in dry-run)"
        step_complete "DNS (dry-run)"
        return 0
    fi
    
    warn "⚠️  DNS Configuration Warning"
    echo "This will override auto DNS for ALL active connections."
    echo "Risks:"
    echo "  • May break corporate/campus networks"
    echo "  • May break VPN split DNS"
    echo "  • May break DNS-over-TLS/DNSSEC setups"
    echo ""
    echo "DNS Options:"
    echo "  1. Google DNS (8.8.8.8, 8.8.4.4)"
    echo "  2. Cloudflare DNS (1.1.1.1, 1.0.0.1)"
    echo "  3. Skip (keep current DNS)"
    echo ""
    
    local dns_choice DNS_IPV4 DNS_IPV6 DNS_NAME
    read -p "Choose DNS provider [1/2/3] (default: 3): " -n 1 dns_choice
    echo ""
    
    case "$dns_choice" in
        1) DNS_IPV4="8.8.8.8 8.8.4.4"; DNS_IPV6="2001:4860:4860::8888 2001:4860:4860::8844"; DNS_NAME="Google" ;;
        2) DNS_IPV4="1.1.1.1 1.0.0.1"; DNS_IPV6="2606:4700:4700::1111 2606:4700:4700::1001"; DNS_NAME="Cloudflare" ;;
        *) info "Keeping current DNS settings"; step_complete "DNS (skipped)"; return 0 ;;
    esac
    
    log "Configuring $DNS_NAME DNS..."
    local conns
    conns=$(nmcli -t -f NAME connection show --active 2>/dev/null || true)
    while IFS= read -r conn; do
        [[ -z "$conn" ]] && continue
        # Skip virtual/bridge interfaces (docker, loopback, libvirt, veth, bridge)
        if [[ "$conn" =~ ^(docker|lo|virbr|veth|br-) ]]; then
            info "Skipping virtual interface: $conn"
            continue
        fi
        log "Setting DNS for: $conn"
        nmcli connection modify "$conn" ipv4.ignore-auto-dns yes ipv4.dns "$DNS_IPV4" 2>/dev/null || warn "Failed to set IPv4 DNS for $conn"
        nmcli connection modify "$conn" ipv6.ignore-auto-dns yes ipv6.dns "$DNS_IPV6" 2>/dev/null || warn "Failed to set IPv6 DNS for $conn"
        nmcli connection down "$conn" 2>/dev/null; sleep 1; nmcli connection up "$conn" 2>/dev/null || warn "Failed to restart $conn"
    done <<< "$conns"
    step_complete "$DNS_NAME DNS configured"
}

# ==============================================================================
# 3. Power Management (TLP)
# ==============================================================================
setup_power() {
    warn "⚠️  TLP vs GNOME Power Profiles"
    echo "TLP provides fine-grained power control but:"
    echo "  • Disables GNOME's built-in power profiles UI"
    echo "  • Some AMD laptops work better with power-profiles-daemon"
    echo "  • Fedora upstream now prefers power-profiles-daemon"
    echo ""
    
    if ! confirm "Use TLP instead of GNOME power profiles?" "N"; then
        info "Keeping GNOME power-profiles-daemon (no changes made)"
        step_complete "Power management (default)"
        return 0
    fi
    
    log "Installing TLP..."
    sudo dnf install -y tlp tlp-rdw
    sudo systemctl enable tlp.service
    sudo systemctl mask power-profiles-daemon.service
    
    sudo tee /etc/systemd/system/tlp-autostart.service > /dev/null <<'EOF'
[Unit]
Description=Force TLP apply after boot
After=multi-user.target
Wants=multi-user.target
[Service]
Type=oneshot
ExecStart=/usr/sbin/tlp start
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload && sudo systemctl enable tlp-autostart.service
    sudo tlp start
    step_complete "TLP configured"
}

# ==============================================================================
# 4. No-Sleep Settings (GDM & User)
# ==============================================================================
setup_nosleep() {
    log "Disabling auto-sleep..."
    sudo mkdir -p /var/lib/gdm/.config/dconf
    sudo chown -R gdm:gdm /var/lib/gdm/.config && sudo chmod 0700 /var/lib/gdm/.config
    
    # GDM settings
    sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || true
    sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0 2>/dev/null || true
    sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' 2>/dev/null || true
    
    # User settings
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' 2>/dev/null || true
    
    step_complete "No-sleep configured"
}

# ==============================================================================
# 5. ZSH + Oh My Zsh + Powerlevel10k
# ==============================================================================
setup_shell() {
    log "Installing ZSH..."
    run_sudo dnf install -y zsh curl git fontconfig
    
    if ! $DRY_RUN; then
        [[ ! -d "$HOME/.oh-my-zsh" ]] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null || true
        run git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
        run git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
    else
        dry "Install Oh My ZSH, Powerlevel10k, plugins"
    fi
    
    # Backup .zshrc using backup system
    backup_file "$HOME/.zshrc"
    
    if ! $DRY_RUN; then
        sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc 2>/dev/null || echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
        sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc 2>/dev/null || echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> ~/.zshrc
        
        cat >> ~/.zshrc <<'EOF'

# --- Custom Configs ---
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a"

# bat alias
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never --style=plain'

# eza alias
command -v eza >/dev/null 2>&1 && alias ls='eza --group-directories-first --classify --icons --git'

EOF
    else
        dry "Configure .zshrc with theme and plugins"
    fi
    
    confirm "Set ZSH as default shell?" "Y" && run chsh -s $(which zsh)
    
    # Validation
    validate_step "ZSH installed" "command -v zsh"
    validate_step "Oh My ZSH" "test -d $HOME/.oh-my-zsh"
    
    step_complete "Shell configured"
}

# ==============================================================================
# 6. Brave Browser + Multimedia
# ==============================================================================
setup_browser_multimedia() {
    log "Installing Brave & multimedia..."
    
    # Validate RPM Fusion is installed (required for multimedia)
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        warn "RPM Fusion may not be installed correctly - multimedia packages may fail"
    fi
    
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo --overwrite 2>/dev/null || true
    sudo dnf install -y brave-browser mozilla-openh264
    
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    sudo dnf group upgrade -y multimedia --setopt=install_weak_deps=False --exclude=PackageKit-gstreamer-plugin
    sudo dnf group upgrade -y sound-and-video
    step_complete "Browser & multimedia ready"
}

# ==============================================================================
# 7. Smart Driver Detection
# ==============================================================================
setup_drivers() {
    log "Detecting Hardware..."
    
    CHASSIS=$(hostnamectl chassis 2>/dev/null || echo "unknown")
    # More specific GPU detection to avoid false positives
    GPU_NVIDIA=$(lspci | grep -Ei 'VGA|3D|Display' | grep -i nvidia || true)
    GPU_AMD=$(lspci | grep -Ei 'VGA|3D|Display' | grep -i amd || true)
    GPU_INTEL=$(lspci | grep -Ei 'VGA|3D|Display' | grep -i intel || true)
    
    log "Detected Chassis: $CHASSIS"
    
    # 4a. Intel Drivers
    if [[ -n "$GPU_INTEL" ]]; then
        log "Intel GPU Detected: Installing intel-media-driver..."
        sudo dnf install -y intel-media-driver
    fi
    
    # 4b. AMD Drivers
    if [[ -n "$GPU_AMD" ]]; then
        log "AMD GPU Detected: Swapping for freeworld drivers..."
        sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
        sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    fi
    
    # 4c. NVIDIA Drivers
    if [[ -n "$GPU_NVIDIA" ]]; then
        log "NVIDIA GPU Detected."
        
        # Common Nvidia Packages
        sudo dnf install -y kmodtool akmods mokutil openssl nvtop akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver
        
        # Force build and verify modules before MOK enrollment
        log "Building NVIDIA kernel modules (this may take a few minutes)..."
        sudo akmods --force
        
        if modinfo nvidia &>/dev/null; then
            success "NVIDIA module built successfully"
        else
            warn "NVIDIA module not yet available - may require reboot after MOK enrollment"
        fi
        
        if [[ "$CHASSIS" == "laptop" || "$CHASSIS" == "notebook" || "$CHASSIS" == "convertible" ]]; then
            log "Laptop detected. Checking for Optimus/Hybrid setup..."
            if [[ -n "$GPU_INTEL" || -n "$GPU_AMD" ]]; then
                 log "Hybrid Graphics (Optimus) detected."
            else
                 log "Dedicated Nvidia only (MUX Switch or Desktop replacement)."
            fi
        fi
        
        log "Generating Secure Boot keys..."
        sudo kmodgenca -a
        
        warn "⚠️  SECURE BOOT ENROLLMENT REQUIRED ⚠️"
        echo "NVIDIA drivers require Secure Boot enrollment."
        echo ""
        echo "PREREQUISITE: Secure Boot must be ENABLED in your BIOS/UEFI."
        echo "If not enabled, stop this script using ctrl+c and do this BEFORE proceeding:"
        echo "1. Enter BIOS/UEFI"
        echo "2. Find Secure Boot option"
        echo "3. Enable it, save, and reboot to Linux"
        echo ""
        
        # Check current Secure Boot state
        SB_STATE=$(sudo mokutil --sb-state 2>/dev/null | grep -i "secureboot" || echo "unknown")
        
        if echo "$SB_STATE" | grep -qi "enabled"; then
            info "Secure Boot is currently ENABLED."
            if confirm "Do you want to enroll the NVIDIA driver key now?" "N"; then
                warn "IMPORTANT: Remember the password you set! You'll need it during next boot!"
                sudo mokutil --import /etc/pki/akmods/certs/public_key.der
                echo ""
                echo "✅ Key enrolled. Next steps after reboot:"
                echo "1. You'll see a BLUE 'MOK Manager' screen"
                echo "2. Select 'Enroll MOK' → 'Continue' → 'Yes'"
                echo "3. Enter the password you just set"
                echo "4. Select 'Reboot'"
                echo ""
                warn "The system will NOT load NVIDIA drivers until MOK enrollment is complete!"
            fi
        else
            warn "Secure Boot appears to be DISABLED or in an unknown state."
            echo "Check with: sudo mokutil --sb-state"
            echo "Enable Secure Boot in BIOS first, then re-run this step or enroll manually."
            echo "Manual enrollment: sudo mokutil --import /etc/pki/akmods/certs/public_key.der"
        fi
    else
        log "No NVIDIA GPU found. Skipping proprietary drivers."
    fi
    
    step_complete "Drivers configured!!"
}

# ==============================================================================
# 8. COPR Packages
# ==============================================================================
setup_copr() {
    log "Installing COPR packages..."
    sudo dnf copr enable -y elxreno/preload && sudo dnf install -y preload || true
    sudo dnf copr enable -y terjeros/eza && sudo dnf install -y eza || true
    sudo dnf copr enable -y zeno/scrcpy && sudo dnf install -y scrcpy || true
    sudo dnf copr enable -y lihaohong/yazi && sudo dnf install -y yazi file ffmpeg 7zip jq poppler fd rg fzf zoxide resvg xclip wl-clipboard xsel ImageMagick || true
    sudo dnf copr enable -y derisis13/ani-cli && sudo dnf install -y mpv ani-cli || true
    step_complete "COPR packages installed"
}

# ==============================================================================
# 9. System Fonts
# ==============================================================================
setup_fonts() {
    log "Installing fonts..."
    sudo dnf install -y --skip-unavailable mscore-fonts mscore-fonts-all dejavu-sans-fonts dejavu-serif-fonts \
        dejavu-sans-mono-fonts liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts \
        google-noto-sans-fonts google-noto-serif-fonts google-noto-mono-fonts google-carlito-fonts google-caladea-fonts \
        curl cabextract xorg-x11-font-utils fontconfig
    
    curl -sLO https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
    sudo rpm -ivh --nodigest --nofiledigest msttcore-fonts-installer-2.6-1.noarch.rpm 2>/dev/null || true
    rm -f msttcore-fonts-installer-2.6-1.noarch.rpm
    
    # Download FiraCode Nerd Font
    log "Downloading FiraCode Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget -qO /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -oq /tmp/FiraCode.zip -d ~/.local/share/fonts/ && rm -f /tmp/FiraCode.zip
    
    fc-cache -fv
    step_complete "Fonts installed"
}

# ==============================================================================
# 10. Cloudflare Warp
# ==============================================================================
setup_warp() {
    log "Installing Cloudflare Warp..."
    sudo dnf install -y sassc glib2-devel libxml2 glibc-devel
    sudo dnf config-manager addrepo --from-repofile=https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo --overwrite 2>/dev/null || true
    sudo dnf install -y cloudflare-warp
    
    # Only register if not already registered
    if ! warp-cli account 2>/dev/null | grep -q "Account type"; then
        check_network && warp-cli registration new 2>/dev/null || warn "Run 'warp-cli registration new' manually"
    else
        info "Warp already registered"
    fi
    step_complete "Warp installed"
}

# ==============================================================================
# 11. GNOME Tools
# ==============================================================================
setup_gnome() {
    log "Installing GNOME tools..."
    sudo dnf install -y gnome-tweaks
    flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || true
    
    info "Recommended GNOME Extensions (install via Extension Manager):"
    info "  • Blur My Shell"
    info "  • Clipboard Indicator"
    info "  • Dash to Dock / Dash2Dock Animated"
    info "  • Coverflow Alt+Tab"
    info "  • GSConnect"
    info "  • Net Speed"
    info "  • Space Bar"
    info "  • User Themes"
    info "  Note: Some extensions (Compiz effects) may not work on GNOME 45+"
    
    step_complete "GNOME tools installed"
}

# ==============================================================================
# 12. Essential Packages
# ==============================================================================
setup_packages() {
    log "Installing essential packages..."
    sudo dnf install -y --skip-unavailable gcc clang fastfetch make cmake perl wmctrl cargo maven bat \
        java-latest-openjdk java-latest-openjdk-devel nodejs python3 python3-pip wget htop unzip unrar \
        p7zip p7zip-plugins ntfs-3g gparted timeshift vlc docker steam mangohud \
        discord telegram-desktop vim nvim gh android-tools libva-utils gstreamer1-plugin-openh264

    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    
    # Steam H264 unlock (fixes some games)
    log "Unlocking Steam H264 codec..."
    if flatpak list 2>/dev/null | grep -q "com.valvesoftware.Steam"; then
        info "Flatpak Steam detected"
        xdg-open steam://unlockh264/ 2>/dev/null &
    else
        steam steam://unlockh264/ 2>/dev/null &
    fi
    sleep 2
    pkill -f "steam://unlockh264" 2>/dev/null || true
    pkill -f "xdg-open" 2>/dev/null || true
    
    info "Steam Settings (configure manually):"
    info "  • Library → Enable 'Show Steam Deck compatibility info'"
    info "  • Downloads → Disable 'Shader Pre-Caching'"
    info "  • Interface → Client Beta Participation → Steam Beta Update"
    
    # Optional Yaru theme
    if confirm "Install Yaru theme (Ubuntu-style)?" "N"; then
        sudo dnf install -y yaru-theme
        info "Yaru installed. Apply in GNOME Tweaks."
    fi
    
    step_complete "Packages installed"
}

# ==============================================================================
# 13. Development Tools
# ==============================================================================
setup_dev() {
    log "Installing dev tools..."
    sudo dnf install -y bc bison ccache curl flex git git-lfs gnupg gperf ImageMagick protobuf-compiler \
        python3-protobuf libxml2 libxslt lzop lz4 pngcrush rsync schedtool squashfs-tools zip \
        openssl-devel zlib-devel elfutils-libelf-devel elfutils-devel gnutls-devel sdl12-compat-devel \
        glibc-devel.i686 libstdc++-devel.i686 zlib-ng-compat-devel.i686 libX11-devel.i686 readline-devel.i686 ncurses-devel.i686 \
        meson ninja-build automake autoconf libtool pkg-config cmake-gui cmake-fedora gdb valgrind strace ltrace clang-tools-extra bear \
        python3-devel python3-virtualenv python3-wheel python3-setuptools
    
    # Configure ccache
    if command -v ccache >/dev/null 2>&1; then
        ccache --set-config=max_size=50G && ccache --set-config=compression=true
        mkdir -p ~/.ccache
        echo "cache_dir = $HOME/.ccache" >> ~/.ccache/ccache.conf 2>/dev/null || true
        info "ccache configured: 50G max, compression enabled"
    fi
    
    confirm "Install Rust toolchain?" "N" && sudo dnf install -y rust cargo rustup rustfmt clippy rust-analyzer
    
    step_complete "Dev tools installed"
}

# ==============================================================================
# 14. MangoHud Config
# ==============================================================================
setup_mangohud() {
    log "Configuring MangoHud..."
    mkdir -p ~/.config/MangoHud
    cat > ~/.config/MangoHud/MangoHud.conf <<'EOF'
legacy_layout=false
position=top-left
font_size=32
fps
frametime
frametime_color_change
gpu_stats
gpu_temp
cpu_stats
cpu_temp
ram
vram
EOF
    step_complete "MangoHud configured"
}

# ==============================================================================
# 15. Antigravity
# ==============================================================================
setup_antigravity() {
    log "Installing Antigravity..."
    sudo tee /etc/yum.repos.d/antigravity.repo > /dev/null <<'EOL'
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL
    sudo dnf makecache && sudo dnf install -y antigravity 2>/dev/null || true
    
    # Install all extensions
    if command -v antigravity >/dev/null; then
        log "Installing Antigravity extensions..."
        antigravity --install-extension bradlc.vscode-tailwindcss --install-extension catppuccin.catppuccin-vsc --install-extension christian-kohler.npm-intellisense --install-extension dbaeumer.vscode-eslint --install-extension devsense.composer-php-vscode --install-extension devsense.intelli-php-vscode --install-extension devsense.phptools-vscode --install-extension devsense.profiler-php-vscode --install-extension dsznajder.es7-react-js-snippets --install-extension eamodio.gitlens --install-extension esbenp.prettier-vscode --install-extension formulahendry.code-runner --install-extension golang.go --install-extension hbenl.vscode-mocha-test-adapter --install-extension hbenl.vscode-test-explorer --install-extension llvm-vs-code-extensions.vscode-clangd --install-extension meta.pyrefly --install-extension ms-azuretools.vscode-containers --install-extension ms-azuretools.vscode-docker --install-extension ms-pyright.pyright --install-extension ms-python.debugpy --install-extension ms-python.python --install-extension ms-python.vscode-python-envs --install-extension ms-vscode.cmake-tools --install-extension ms-vscode.cpptools-themes --install-extension ms-vscode.live-server --install-extension ms-vscode.test-adapter-converter --install-extension ms-vscode.vscode-typescript-next --install-extension redhat.java --install-extension shopify.ruby-lsp --install-extension vscjava.vscode-gradle --install-extension vscjava.vscode-java-debug --install-extension vscjava.vscode-java-dependency --install-extension vscjava.vscode-java-pack --install-extension vscjava.vscode-java-test --install-extension vscjava.vscode-maven --install-extension vscode-icons-team.vscode-icons 2>/dev/null || warn "Some extensions failed"
        
        # Create Antigravity settings file
        log "Creating Antigravity settings..."
        mkdir -p "$HOME/.config/Antigravity/User"
        cat > "$HOME/.config/Antigravity/User/settings.json" <<'SETTINGS'
{
    "editor.fontFamily": "FiraCode Nerd Font, monospace",
    "editor.fontWeight": "600",
    "editor.fontLigatures": true,
    "editor.fontSize": 14,
    "editor.lineHeight": 1.6,
    "terminal.integrated.fontFamily": "FiraCode Nerd Font",
    "terminal.integrated.fontWeight": "600",
    "terminal.integrated.lineHeight": 1.2,
    "files.autoSave": "afterDelay"
}
SETTINGS
        success "Antigravity settings created"
    fi
    step_complete "Antigravity configured"
}

# ==============================================================================
# 16. OnlyOffice
# ==============================================================================
setup_office() {
    log "Installing OnlyOffice..."
    sudo dnf install -y https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm
    sudo dnf install -y onlyoffice-desktopeditors
    step_complete "OnlyOffice installed"
}

# ==============================================================================
# 17. Flatpaks
# ==============================================================================
setup_flatpaks() {
    log "Installing Flatpaks..."
    flatpak install -y flathub org.localsend.localsend_app io.missioncenter.MissionCenter com.vysp3r.ProtonPlus 2>/dev/null || true
    
    info "ProtonPlus installed - Use for Proton GE:"
    info "  • Only use if a game has issues with default Proton"
    info "  • Install latest Proton GE version from ProtonPlus"
    info "  • Set per-game in Steam: Properties → Compatibility"
    
    step_complete "Flatpaks installed"
}

# ==============================================================================
# 18. Docker Setup
# ==============================================================================
setup_docker() {
    log "Configuring Docker..."
    
    # Check if docker is installed first
    if ! rpm -q moby-engine &>/dev/null && ! rpm -q docker-ce &>/dev/null; then
        warn "Docker (moby-engine/docker-ce) not installed - skipping configuration"
        step_complete "Docker (not installed)"
        return 0
    fi
    
    sudo usermod -aG docker $USER
    
    # Enable and start docker with proper error handling
    sudo systemctl enable docker 2>/dev/null || true
    
    # Check if docker socket/service conflicts exist
    if sudo systemctl is-failed docker &>/dev/null; then
        warn "Docker service in failed state - attempting reset"
        sudo systemctl reset-failed docker 2>/dev/null || true
    fi
    
    # Start docker if not already running
    if ! sudo systemctl is-active --quiet docker; then
        sudo systemctl start docker 2>/dev/null || true
        sleep 2
    fi
    
    if sudo systemctl is-active --quiet docker; then
        success "Docker running"
        # Note: docker test requires logout/login for group membership
        info "After reboot, verify with: docker run --rm hello-world"
    else
        warn "Docker failed to start - check: sudo systemctl status docker"
        info "Common fixes:"
        info "  • Reboot and try again"
        info "  • Check: sudo journalctl -u docker --no-pager -n 20"
    fi
    
    # Corepack setup
    if command -v npm >/dev/null; then
        sudo npm install -g corepack 2>/dev/null || true
        sudo corepack enable 2>/dev/null || true
        info "Corepack enabled. After reboot verify:"
        info "  npm --version && yarn --version && pnpm --version"
    fi
    
    step_complete "Docker configured"
}

# ==============================================================================
# 19. LM Studio
# ==============================================================================
setup_lmstudio() {
    log "Setting up LM Studio..."
    sudo dnf install -y fuse-libs
    
    local LMS=$(find ~/Downloads -maxdepth 1 -name "LM-Studio*.AppImage" 2>/dev/null | head -1)
    [[ -z "$LMS" ]] && confirm "Download LM Studio?" "N" && { wget -P ~/Downloads "https://releases.lmstudio.ai/linux/x64/latest/LM-Studio-latest-x64.AppImage"; LMS=$(find ~/Downloads -name "LM-Studio*.AppImage" | head -1); }
    
    if [[ -n "$LMS" ]]; then
        mkdir -p ~/Applications ~/.local/share/applications ~/.local/share/icons/hicolor/512x512/apps
        mv "$LMS" ~/Applications/ 2>/dev/null || true
        chmod +x ~/Applications/LM-Studio*.AppImage
        local APP=$(ls ~/Applications/LM-Studio*.AppImage 2>/dev/null | head -1)
        
        # Extract icon
        "$APP" --appimage-extract 2>/dev/null || true
        [[ -d squashfs-root ]] && { find squashfs-root -name "*.png" -exec cp {} ~/.local/share/icons/hicolor/512x512/apps/lmstudio.png \; 2>/dev/null || true; rm -rf squashfs-root; }
        
        cat > ~/.local/share/applications/lmstudio.desktop <<EOF
[Desktop Entry]
Name=LM Studio
Comment=Local LLM runner
Type=Application
Exec=$APP --no-sandbox
Icon=lmstudio
Terminal=false
Categories=Development;AI;
EOF
        update-desktop-database ~/.local/share/applications 2>/dev/null || true
        gtk-update-icon-cache ~/.local/share/icons/hicolor 2>/dev/null || true
        success "LM Studio installed"
        
        info "LM Studio Model Settings (for optimal performance):"
        info "  • Context Length: 6144-32768 (based on VRAM)"
        info "  • GPU Offload: Max layers"
        info "  • CPU Thread Pool: 6"
        info "  • Evaluation Batch Size: 512"
        info "  • Offload KV Cache to GPU: On"
        info "  • Keep Model in Memory: On"
        info "  • Flash Attention: On"
        info "  • K/V Cache Quantization: F16"
    fi
    step_complete "LM Studio configured"
}

# ==============================================================================
# 20. Gemini CLI
# ==============================================================================
setup_gemini() {
    log "Installing Gemini CLI..."
    command -v npm >/dev/null && sudo npm install -g @google/gemini-cli
    step_complete "Gemini CLI installed"
}

# ==============================================================================
# Summary
# ==============================================================================
show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local mins=$((duration / 60)) secs=$((duration % 60))
    
    echo -e "\n${GREEN}=== INSTALLATION SUMMARY ===${NC}"
    echo "Time: ${mins}m ${secs}s | Steps: ${COMPLETED_STEPS}/${TOTAL_STEPS}"
    echo ""
    
    echo "Service Status:"
    systemctl is-active --quiet tlp && echo "  ✅ TLP" || echo "  ❌ TLP"
    sudo systemctl is-active --quiet docker && echo "  ✅ Docker" || echo "  ❌ Docker"
    command -v nvidia-smi &>/dev/null && echo "  ✅ NVIDIA drivers"
    command -v warp-cli &>/dev/null && { warp-cli account 2>/dev/null | grep -q "Account" && echo "  ✅ Warp registered" || echo "  ⚠️  Warp: not registered"; }
    [[ "$SHELL" == "$(which zsh)" ]] && echo "  ✅ ZSH default" || echo "  ⚠️  ZSH: not default shell"
    
    # Hardware acceleration verification
    if confirm "Verify hardware video acceleration?" "N"; then
        log "Checking hardware acceleration..."
        echo ""
        echo "H.264 Encoders:"
        command -v ffmpeg >/dev/null && ffmpeg -encoders 2>/dev/null | grep -i "264" | head -5 || echo "  ffmpeg not found"
        echo ""
        echo "VA-API Profiles:"
        command -v vainfo >/dev/null && vainfo 2>/dev/null | grep -i "VAProfileH264" | head -3 || echo "  vainfo not found"
        echo ""
    fi
    
    echo ""
    echo "Next Steps:"
    echo "1. Reboot (for driver/docker changes)"
    echo "2. p10k configure (Powerlevel10k theme)"
    echo "3. warp-cli connect"
    echo "4. docker run hello-world"
    echo ""
    echo -e "${GREEN}System ready! 🚀${NC}"
}

# ==============================================================================
# Cleanup
# ==============================================================================
cleanup() {
    log "Cleaning up..."
    rm -f msttcore-fonts-installer*.rpm FiraCode.zip 2>/dev/null || true
    rm -rf squashfs-root 2>/dev/null || true
    confirm "Clear DNF cache?" "N" && sudo dnf clean all
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    # Show mode indicator
    if $DRY_RUN; then
        echo -e "${MAGENTA}========================================${NC}"
        echo -e "${MAGENTA}   DRY-RUN MODE - No changes will be made${NC}"
        echo -e "${MAGENTA}========================================${NC}"
        echo ""
    fi
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Fedora 43 Post-Install Setup v${SCRIPT_VERSION}${NC}"
    echo -e "${GREEN}========================================${NC}"
    info "Started at $(date)"
    info "Log file: $LOG_FILE"
    echo ""
    
    # Pre-flight menu
    if confirm "Show currently installed versions?" "N"; then
        show_versions
    fi
    
    if confirm "Restore from previous backup?" "N"; then
        restore_backups
        return 0
    fi
    
    if ! $DRY_RUN && ! check_network; then
        error "No internet connection. Exiting."
        exit 1
    fi
    
    local steps=(
        "setup_dnf:DNF Configuration"
        "setup_dns:DNS Configuration"
        "setup_power:Power Management"
        "setup_nosleep:No-Sleep Settings"
        "setup_fonts:System Fonts"
        "setup_shell:ZSH + Powerlevel10k"
        "setup_browser_multimedia:Brave + Multimedia"
        "setup_drivers:GPU Drivers"
        "setup_copr:COPR Packages"
        "setup_warp:Cloudflare Warp"
        "setup_gnome:GNOME Tools"
        "setup_packages:Essential Packages"
        "setup_dev:Development Tools"
        "setup_mangohud:MangoHud Config"
        "setup_antigravity:Antigravity"
        "setup_office:OnlyOffice"
        "setup_flatpaks:Flatpak Apps"
        "setup_docker:Docker Setup"
        "setup_lmstudio:LM Studio"
        "setup_gemini:Gemini CLI"
    )
    
    # Define profile step filters
    local -A PROFILE_STEPS
    PROFILE_STEPS[minimal]="setup_dnf setup_fonts setup_shell"
    PROFILE_STEPS[dev]="setup_dnf setup_fonts setup_shell setup_dev setup_docker setup_antigravity setup_gemini"
    PROFILE_STEPS[gaming]="setup_dnf setup_fonts setup_shell setup_drivers setup_packages setup_mangohud setup_flatpaks setup_browser_multimedia"
    PROFILE_STEPS[full]=""  # Empty means all steps
    
    info "Profile: $PROFILE"
    [[ -n "${PROFILE_STEPS[$PROFILE]}" ]] && info "Running steps: ${PROFILE_STEPS[$PROFILE]}"
    echo ""
    
    # Initialize state file
    init_state
    
    # Calculate TOTAL_STEPS dynamically based on profile
    TOTAL_STEPS=0
    for step in "${steps[@]}"; do
        IFS=':' read -r func _ <<< "$step"
        [[ -n "${PROFILE_STEPS[$PROFILE]}" ]] && [[ ! " ${PROFILE_STEPS[$PROFILE]} " =~ " $func " ]] && continue
        TOTAL_STEPS=$((TOTAL_STEPS + 1))
    done
    
    for step in "${steps[@]}"; do
        IFS=':' read -r func name <<< "$step"
        
        # Check if step is in profile (skip if not in filtered profile)
        if [[ -n "${PROFILE_STEPS[$PROFILE]}" ]] && [[ ! " ${PROFILE_STEPS[$PROFILE]} " =~ " $func " ]]; then
            continue  # Skip step not in profile
        fi
        
        # Check if step was already completed (idempotency)
        if is_step_completed "$func" && ! $FORCE_RERUN; then
            info "Already completed: $name (use --force to re-run)"
            COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
            continue
        fi
        
        echo ""
        echo -e "${BLUE}Step: $name${NC}"
        if confirm "Run this step?" "Y"; then
            if $func; then
                success "$name completed"
                # Only update state and increment counter in non-dry-run mode
                if ! $DRY_RUN; then
                    mark_step_completed "$func"
                    COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
                fi
            else
                warn "$name had issues"
                $DRY_RUN || COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
            fi
        else
            warn "Skipped: $name"
            $DRY_RUN || COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
        fi
    done
    
    # Cleanup respects profile (only run for full profile)
    if ! $DRY_RUN && [[ "$PROFILE" == "full" ]]; then
        cleanup
    fi
    
    show_summary
    
    # Final info
    echo ""
    info "Full log saved to: $LOG_FILE"
    if [[ -d "$BACKUP_DIR" ]]; then
        info "Config backups saved to: $BACKUP_DIR"
    fi
}

trap 'echo -e "\n${RED}Interrupted${NC}"; exit 1' INT
main "$@"
