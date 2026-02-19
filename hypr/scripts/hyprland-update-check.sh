#!/bin/bash
# Hyprland Update Safety Checker
# Checks for breaking changes before updating Hyprland
# Usage: hyprland-update-check.sh [--update]

set -e

BACKUP_DIR="$HOME/.config/hypr/backups"
CHANGELOG_CACHE="$HOME/.cache/hyprland-changelog"
CONFIG_DIR="$HOME/.config/hypr"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

mkdir -p "$BACKUP_DIR" "$CHANGELOG_CACHE"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }

# Get current Hyprland version
get_current_version() {
    hyprctl version 2>/dev/null | grep -oP 'Tag: v?\K[\d.]+' | head -1 || echo "unknown"
}

# Get available version from repos
get_available_version() {
    pacman -Si hyprland 2>/dev/null | grep Version | awk '{print $3}' | cut -d'-' -f1
}

# Create config backup
backup_config() {
    local backup_name="hypr-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    log_info "Creating backup at $backup_path"

    mkdir -p "$backup_path"
    cp -r "$CONFIG_DIR"/*.conf "$backup_path/" 2>/dev/null || true
    cp -r "$CONFIG_DIR"/scripts "$backup_path/" 2>/dev/null || true

    # Save current version
    echo "$(get_current_version)" > "$backup_path/version.txt"

    # Save installed hyprland packages
    pacman -Qs hypr | grep -E "^local" > "$backup_path/hypr-packages.txt"

    log_success "Backup created: $backup_name"
    echo "$backup_path"
}

# Check for deprecated config options
check_deprecated_options() {
    log_info "Checking for deprecated configuration options..."

    local issues=0
    local deprecated_patterns=(
        # Add known deprecated options here
        "gaps_in=:Use 'gaps { in = }' block instead"
        "gaps_out=:Use 'gaps { out = }' block instead"
        "sensitivity=.*input:Move sensitivity inside input { } block"
        "enabled=true:Remove 'enabled=true', it's default"
        "no_gaps_when_only:Use 'gaps { smart_gaps = }' instead"
        "cursor_inactive_timeout:Moved to 'cursor { inactive_timeout = }'"
        "layout=dwindle:general:Move layout to 'general { layout = }'"
        "col.active_border=.*general:Border colors go inside general { } block"
    )

    for pattern_msg in "${deprecated_patterns[@]}"; do
        local pattern="${pattern_msg%%:*}"
        local msg="${pattern_msg#*:}"

        if grep -rqE "$pattern" "$CONFIG_DIR"/*.conf 2>/dev/null; then
            log_warn "Deprecated: $msg"
            grep -rn "$pattern" "$CONFIG_DIR"/*.conf 2>/dev/null | head -3
            ((issues++))
        fi
    done

    if [[ $issues -eq 0 ]]; then
        log_success "No deprecated options found"
    else
        log_warn "Found $issues potential issues"
    fi

    return $issues
}

# Check for syntax errors in config
check_config_syntax() {
    log_info "Validating configuration syntax..."

    # Try to parse with hyprctl
    if hyprctl reload 2>&1 | grep -qi "error\|failed"; then
        log_error "Configuration has syntax errors!"
        hyprctl reload 2>&1 | grep -i "error\|failed"
        return 1
    fi

    log_success "Configuration syntax OK"
    return 0
}

# Check plugin compatibility
check_plugins() {
    log_info "Checking Hyprland plugins..."

    local plugins=$(hyprctl plugins list 2>/dev/null)

    if [[ -z "$plugins" || "$plugins" == *"No plugins"* ]]; then
        log_info "No plugins installed"
        return 0
    fi

    echo "$plugins"
    log_warn "Plugins may need recompilation after update!"
    return 0
}

# Fetch and parse changelog for breaking changes
check_breaking_changes() {
    local current="$1"
    local available="$2"

    log_info "Checking for breaking changes between v$current and v$available..."

    # Fetch latest release notes from GitHub
    local releases=$(curl -sf "https://api.github.com/repos/hyprwm/Hyprland/releases?per_page=10" \
        --connect-timeout 5 --max-time 15)

    if [[ -z "$releases" ]]; then
        log_warn "Could not fetch release notes (offline or API limit)"
        return 0
    fi

    # Look for breaking changes keywords
    local breaking_keywords="BREAKING|breaking change|deprecated|removed|migration|incompatible"

    echo "$releases" | jq -r '.[].body // empty' | while read -r body; do
        if echo "$body" | grep -qiE "$breaking_keywords"; then
            log_warn "Potential breaking changes found in release notes:"
            echo "$body" | grep -iE "$breaking_keywords" | head -10
        fi
    done

    # Check Hyprland wiki migration guides
    log_info "Check the migration guide: https://wiki.hypr.land/Configuring/Upgrading/"

    return 0
}

# Check hyprland ecosystem packages
check_ecosystem() {
    log_info "Checking Hyprland ecosystem packages..."

    local packages=(
        "hyprland"
        "hyprlock"
        "hypridle"
        "hyprpaper"
        "hyprpicker"
        "hyprcursor"
        "xdg-desktop-portal-hyprland"
    )

    echo "Package versions:"
    for pkg in "${packages[@]}"; do
        local installed=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
        local available=$(pacman -Si "$pkg" 2>/dev/null | grep Version | awk '{print $3}')

        if [[ -n "$installed" ]]; then
            if [[ "$installed" != "$available" ]]; then
                echo "  $pkg: $installed -> $available (update available)"
            else
                echo "  $pkg: $installed (up to date)"
            fi
        fi
    done
}

# Main update check
run_check() {
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           Hyprland Update Safety Check                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo

    local current=$(get_current_version)
    local available=$(get_available_version)

    echo "Current version:   $current"
    echo "Available version: $available"
    echo

    if [[ "$current" == "$available" ]]; then
        log_success "Hyprland is up to date!"
        echo
    fi

    # Run all checks
    local issues=0

    check_deprecated_options || ((issues++))
    echo

    check_plugins
    echo

    check_ecosystem
    echo

    if [[ "$current" != "$available" ]]; then
        check_breaking_changes "$current" "$available"
        echo
    fi

    # Summary
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                     SUMMARY                              ║"
    echo "╚══════════════════════════════════════════════════════════╝"

    if [[ $issues -gt 0 ]]; then
        log_warn "Found $issues potential issues. Review before updating."
    else
        log_success "No issues found. Safe to update."
    fi

    echo
    echo "Recommendations:"
    echo "  1. Run: $(basename "$0") --backup    # Create config backup"
    echo "  2. Run: sudo pacman -Syu hyprland    # Update Hyprland"
    echo "  3. Check: hyprctl reload             # Test new config"
    echo "  4. Review: https://wiki.hypr.land/Configuring/Upgrading/"
    echo
}

# Perform safe update
safe_update() {
    log_info "Starting safe Hyprland update..."

    # Create backup first
    local backup_path=$(backup_config)

    echo
    log_info "Updating Hyprland ecosystem..."

    # Show what will be updated
    echo "The following packages will be updated:"
    pacman -Qu 2>/dev/null | grep -E "^hypr" || echo "  (no hyprland updates available)"
    echo

    read -p "Proceed with update? [y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -Syu --needed hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland

        echo
        log_info "Testing configuration..."

        if hyprctl reload 2>&1 | grep -qi "error"; then
            log_error "Configuration errors after update!"
            log_info "Restoring backup from $backup_path"

            # Restore backup
            cp "$backup_path"/*.conf "$CONFIG_DIR/"
            hyprctl reload

            log_warn "Backup restored. Check the changelog for required changes."
        else
            log_success "Update completed successfully!"
        fi
    else
        log_info "Update cancelled"
    fi
}

# Restore from backup
restore_backup() {
    log_info "Available backups:"

    local backups=($(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r))

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "No backups found in $BACKUP_DIR"
        return 1
    fi

    select backup in "${backups[@]}"; do
        if [[ -n "$backup" ]]; then
            log_info "Restoring from $backup..."
            cp "$BACKUP_DIR/$backup"/*.conf "$CONFIG_DIR/"
            hyprctl reload
            log_success "Restored from $backup"
            break
        fi
    done
}

# Main
case "$1" in
    --backup|-b)
        backup_config
        ;;
    --update|-u)
        run_check
        echo
        safe_update
        ;;
    --restore|-r)
        restore_backup
        ;;
    --help|-h)
        echo "Hyprland Update Safety Checker"
        echo
        echo "Usage: $(basename "$0") [OPTIONS]"
        echo
        echo "Options:"
        echo "  (none)       Run safety check only"
        echo "  --backup     Create configuration backup"
        echo "  --update     Check and perform safe update"
        echo "  --restore    Restore from backup"
        echo "  --help       Show this help"
        ;;
    *)
        run_check
        ;;
esac
