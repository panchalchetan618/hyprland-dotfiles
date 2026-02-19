#!/bin/bash
#
# Hyprland Dotfiles Installer
# Automatically sets up a complete Hyprland desktop environment
#
# Usage: ./install.sh [--no-packages] [--no-backup]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Config
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"

# Flags
INSTALL_PACKAGES=true
CREATE_BACKUP=true

# Parse arguments
for arg in "$@"; do
    case $arg in
        --no-packages) INSTALL_PACKAGES=false ;;
        --no-backup) CREATE_BACKUP=false ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-packages  Skip package installation"
            echo "  --no-backup    Skip backing up existing configs"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
    esac
done

# Logging
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

info() {
    log "${BLUE}[INFO]${NC} $1"
}

success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    log "${YELLOW}[WARNING]${NC} $1"
}

error() {
    log "${RED}[ERROR]${NC} $1"
}

header() {
    echo ""
    log "${CYAN}${BOLD}=== $1 ===${NC}"
    echo ""
}

# Check if running on Arch-based system
check_system() {
    header "System Check"

    if [ -f /etc/arch-release ]; then
        success "Arch Linux detected"
    elif [ -f /etc/os-release ] && grep -qi "arch" /etc/os-release; then
        success "Arch-based system detected"
    else
        warn "This script is designed for Arch Linux"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Installation cancelled"
            exit 1
        fi
    fi

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root"
        exit 1
    fi
}

# Detect AUR helper
detect_aur_helper() {
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        AUR_HELPER=""
    fi
}

# Install AUR helper if needed
install_aur_helper() {
    if [ -z "$AUR_HELPER" ]; then
        info "Installing yay (AUR helper)..."

        sudo pacman -S --needed --noconfirm git base-devel

        local tmp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
        cd "$tmp_dir/yay"
        makepkg -si --noconfirm
        cd "$DOTFILES_DIR"
        rm -rf "$tmp_dir"

        AUR_HELPER="yay"
        success "yay installed successfully"
    else
        success "Using $AUR_HELPER as AUR helper"
    fi
}

# Install packages
install_packages() {
    header "Installing Packages"

    # Core Hyprland packages
    local core_packages=(
        hyprland
        hyprlock
        hypridle
        hyprpaper
        xdg-desktop-portal-hyprland
    )

    # Wayland essentials
    local wayland_packages=(
        wayland
        wayland-protocols
        wl-clipboard
        wlroots
        xorg-xwayland
    )

    # Bar, notifications, launcher
    local ui_packages=(
        waybar
        swaync
        rofi-wayland
        swww
    )

    # Utilities
    local utility_packages=(
        kitty
        nautilus
        grim
        slurp
        swappy
        wf-recorder
        cliphist
        brightnessctl
        playerctl
        pavucontrol
        blueman
        networkmanager
        network-manager-applet
        polkit-gnome
    )

    # Theming
    local theme_packages=(
        python-pywal
        imagemagick
        jq
        bc
    )

    # Audio
    local audio_packages=(
        pipewire
        pipewire-alsa
        pipewire-pulse
        pipewire-jack
        wireplumber
    )

    # Fonts
    local font_packages=(
        ttf-jetbrains-mono-nerd
        ttf-font-awesome
        noto-fonts
        noto-fonts-emoji
    )

    # GTK theming
    local gtk_packages=(
        gtk3
        gtk4
        gnome-themes-extra
        adwaita-icon-theme
    )

    # Combine all packages
    local all_packages=(
        "${core_packages[@]}"
        "${wayland_packages[@]}"
        "${ui_packages[@]}"
        "${utility_packages[@]}"
        "${theme_packages[@]}"
        "${audio_packages[@]}"
        "${font_packages[@]}"
        "${gtk_packages[@]}"
    )

    info "Installing core packages with pacman..."
    sudo pacman -S --needed --noconfirm "${all_packages[@]}" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Some packages may have failed, continuing..."
    }

    # AUR packages
    local aur_packages=(
        swappy
        avizo
        wlogout
    )

    if [ -n "$AUR_HELPER" ]; then
        info "Installing AUR packages..."
        for pkg in "${aur_packages[@]}"; do
            if ! pacman -Qi "$pkg" &>/dev/null; then
                $AUR_HELPER -S --needed --noconfirm "$pkg" 2>&1 | tee -a "$LOG_FILE" || {
                    warn "Failed to install $pkg from AUR, skipping..."
                }
            fi
        done
    fi

    success "Package installation complete"
}

# Backup existing configs
backup_configs() {
    header "Backing Up Existing Configs"

    local configs_to_backup=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
        "$HOME/.config/swaync"
        "$HOME/.config/rofi"
        "$HOME/.config/gtk-3.0"
        "$HOME/.config/gtk-4.0"
        "$HOME/.config/xdg-desktop-portal"
    )

    mkdir -p "$BACKUP_DIR"

    for config in "${configs_to_backup[@]}"; do
        if [ -e "$config" ]; then
            local name=$(basename "$config")
            info "Backing up $name..."
            cp -r "$config" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done

    success "Backup created at $BACKUP_DIR"
}

# Install dotfiles
install_dotfiles() {
    header "Installing Dotfiles"

    # Create config directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/Videos/Recordings"

    # Copy configurations
    local configs=(
        "hypr:$HOME/.config/hypr"
        "waybar:$HOME/.config/waybar"
        "swaync:$HOME/.config/swaync"
        "rofi:$HOME/.config/rofi"
        "gtk-3.0:$HOME/.config/gtk-3.0"
        "gtk-4.0:$HOME/.config/gtk-4.0"
        "xdg-desktop-portal:$HOME/.config/xdg-desktop-portal"
    )

    for config in "${configs[@]}"; do
        local src="${config%%:*}"
        local dest="${config##*:}"

        if [ -d "$DOTFILES_DIR/$src" ]; then
            info "Installing $src..."
            rm -rf "$dest"
            cp -r "$DOTFILES_DIR/$src" "$dest"
            success "$src installed"
        else
            warn "$src not found in dotfiles, skipping..."
        fi
    done

    # Make scripts executable
    if [ -d "$HOME/.config/hypr/scripts" ]; then
        chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
        success "Scripts made executable"
    fi

    if [ -d "$HOME/.config/waybar/scripts" ]; then
        chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
    fi

    # Create initial color files if they don't exist
    create_initial_colors
}

# Create default color files for first run
create_initial_colors() {
    info "Creating initial color files..."

    # Default colors (dark theme)
    local BG="#1e1e2e"
    local BG_LIGHT="#313244"
    local FG="#cdd6f4"
    local FG_DIM="#6c7086"
    local ACCENT="#89b4fa"
    local ACCENT2="#a6e3a1"

    # Hyprland colors
    if [ ! -f "$HOME/.config/hypr/colors-dynamic.conf" ]; then
        cat > "$HOME/.config/hypr/colors-dynamic.conf" << EOF
# Default colors - will be updated by wallpaper-theme.sh
\$accent1 = ${ACCENT}
\$accent2 = ${ACCENT2}

general {
    col.active_border = rgba(${ACCENT:1}ff) rgba(${ACCENT2:1}ff) 45deg
    col.inactive_border = rgba(${FG_DIM:1}40)
}
EOF
    fi

    # Waybar colors
    if [ ! -f "$HOME/.config/waybar/colors.css" ]; then
        cat > "$HOME/.config/waybar/colors.css" << EOF
/* Default colors - will be updated by wallpaper-theme.sh */
@define-color bg-base rgba(30, 30, 46, 0.75);
@define-color bg-surface rgba(49, 50, 68, 0.9);
@define-color bg-hover rgba(255, 255, 255, 0.1);
@define-color bg-active rgba(137, 180, 250, 0.2);

@define-color text-primary ${FG};
@define-color text-secondary ${FG_DIM};

@define-color accent-primary ${ACCENT};
@define-color accent-secondary ${ACCENT2};
@define-color accent-tertiary #f9e2af;

@define-color warning #f9e2af;
@define-color critical #f38ba8;
@define-color success #a6e3a1;
EOF
    fi

    # SwayNC colors
    if [ ! -f "$HOME/.config/swaync/colors.css" ]; then
        cat > "$HOME/.config/swaync/colors.css" << EOF
/* Default colors - will be updated by wallpaper-theme.sh */
@define-color bg rgba(30, 30, 46, 0.95);
@define-color bg-solid ${BG};
@define-color bg-hover rgba(49, 50, 68, 0.95);
@define-color bg-focus rgba(69, 71, 90, 0.95);
@define-color bg-widget rgba(49, 50, 68, 0.9);

@define-color text ${FG};
@define-color text-secondary ${FG_DIM};
@define-color text-dim #585b70;

@define-color accent ${ACCENT};
@define-color accent-light rgba(137, 180, 250, 0.2);
@define-color accent2 ${ACCENT2};

@define-color border rgba(255, 255, 255, 0.08);
@define-color border-light rgba(255, 255, 255, 0.12);

@define-color green #4ade80;
@define-color yellow #facc15;
@define-color red #ef4444;
EOF
    fi

    success "Initial color files created"
}

# Setup GTK theme
setup_gtk() {
    header "Setting Up GTK Theme"

    # Set dark theme
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true

    # Link GTK4 theme if WhiteSur is available
    if [ -d "/usr/share/themes/WhiteSur-Dark/gtk-4.0" ]; then
        ln -sf /usr/share/themes/WhiteSur-Dark/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true
        ln -sf /usr/share/themes/WhiteSur-Dark/gtk-4.0/gtk-dark.css "$HOME/.config/gtk-4.0/gtk-dark.css" 2>/dev/null || true
        info "WhiteSur GTK4 theme linked"
    fi

    success "GTK theme configured"
}

# Setup default applications
setup_defaults() {
    header "Setting Up Default Applications"

    # Set nautilus as default file manager
    xdg-mime default org.gnome.Nautilus.desktop inode/directory 2>/dev/null || true

    success "Default applications configured"
}

# Enable services
enable_services() {
    header "Enabling Services"

    # Enable PipeWire
    systemctl --user enable --now pipewire.socket 2>/dev/null || true
    systemctl --user enable --now pipewire-pulse.socket 2>/dev/null || true
    systemctl --user enable --now wireplumber.service 2>/dev/null || true

    # Enable Bluetooth
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true

    # Enable NetworkManager
    sudo systemctl enable --now NetworkManager.service 2>/dev/null || true

    success "Services enabled"
}

# Copy sample wallpaper
setup_wallpaper() {
    header "Setting Up Wallpaper"

    if [ -d "$DOTFILES_DIR/wallpapers" ]; then
        cp -r "$DOTFILES_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
        success "Sample wallpapers copied"
    else
        info "No wallpapers in dotfiles, you can add your own to ~/Pictures/Wallpapers/"
    fi
}

# Generate initial pywal colors
setup_colors() {
    header "Setting Up Colors"

    if command -v wal &>/dev/null; then
        # Find a wallpaper to use
        local wallpaper=$(find "$HOME/Pictures/Wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | head -1)

        if [ -n "$wallpaper" ]; then
            info "Generating colors from $wallpaper..."
            wal -i "$wallpaper" -n -q -e 2>/dev/null || true
            success "Colors generated"
        else
            warn "No wallpapers found. Add images to ~/Pictures/Wallpapers/ and run:"
            info "  ~/.config/hypr/scripts/wallpaper-theme.sh <wallpaper-path>"
        fi
    else
        warn "pywal not installed, skipping color generation"
    fi
}

# Print completion message
print_completion() {
    header "Installation Complete!"

    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║   Hyprland Dotfiles Installed Successfully   ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${CYAN}Next steps:${NC}"
    echo ""
    echo "  1. Log out and select Hyprland from your display manager"
    echo "  2. Add wallpapers to ~/Pictures/Wallpapers/"
    echo "  3. Apply a wallpaper theme:"
    echo "     ${YELLOW}~/.config/hypr/scripts/wallpaper-theme.sh ~/Pictures/Wallpapers/your-wallpaper.jpg${NC}"
    echo ""
    echo -e "${CYAN}Key bindings:${NC}"
    echo "  Super + T        Terminal (kitty)"
    echo "  Super + E        File Manager (nautilus)"
    echo "  Super + D        App Launcher (rofi)"
    echo "  Super + Q        Close window"
    echo "  Super + N        Notification panel"
    echo "  Super + V        Clipboard history"
    echo "  Print            Screenshot (region)"
    echo "  Super + Shift+R  Screen recording"
    echo ""
    echo -e "${CYAN}Backup location:${NC} $BACKUP_DIR"
    echo -e "${CYAN}Install log:${NC} $LOG_FILE"
    echo ""
}

# Main installation
main() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║        Hyprland Dotfiles Installer           ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    check_system

    if [ "$INSTALL_PACKAGES" = true ]; then
        detect_aur_helper
        install_aur_helper
        install_packages
    else
        info "Skipping package installation (--no-packages)"
    fi

    if [ "$CREATE_BACKUP" = true ]; then
        backup_configs
    else
        info "Skipping backup (--no-backup)"
    fi

    install_dotfiles
    setup_gtk
    setup_defaults
    enable_services
    setup_wallpaper
    setup_colors

    print_completion
}

# Run main function
main "$@"
