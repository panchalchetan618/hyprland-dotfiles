# Hyprland Dotfiles

A modern, feature-rich Hyprland desktop configuration with dynamic theming based on wallpaper colors.

![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-blue)
![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1)

## Features

- **Dynamic Theming** - Colors automatically generated from wallpaper using pywal
- **Modern UI** - Clean waybar with rounded corners and blur effects
- **Notification Center** - Feature-rich swaync with power menu and quick toggles
- **Screenshot Tools** - Region, window, and fullscreen capture with clipboard support
- **Screen Recording** - Multiple modes with audio options
- **Clipboard Manager** - History with rofi picker

## Preview

| Component | Description |
|-----------|-------------|
| Waybar | Minimal top bar with workspaces, clock, system info |
| SwayNC | Notification panel with power menu, volume, brightness |
| Rofi | Application launcher and clipboard picker |

## Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Install Options

```bash
./install.sh              # Full installation
./install.sh --no-packages    # Skip package installation
./install.sh --no-backup      # Skip config backup
```

## Manual Installation

1. Install required packages (Arch Linux):

```bash
sudo pacman -S hyprland hyprlock hypridle xdg-desktop-portal-hyprland \
    waybar swaync rofi-wayland swww kitty nautilus \
    grim slurp swappy wf-recorder cliphist wl-clipboard \
    python-pywal brightnessctl playerctl pavucontrol \
    pipewire pipewire-pulse wireplumber \
    ttf-jetbrains-mono-nerd ttf-font-awesome
```

2. Copy configurations:

```bash
cp -r hypr ~/.config/
cp -r waybar ~/.config/
cp -r swaync ~/.config/
cp -r gtk-3.0 ~/.config/
cp -r gtk-4.0 ~/.config/
cp -r xdg-desktop-portal ~/.config/
```

3. Make scripts executable:

```bash
chmod +x ~/.config/hypr/scripts/*.sh
chmod +x ~/.config/waybar/scripts/*.sh
```

## Key Bindings

### General
| Binding | Action |
|---------|--------|
| `Super + T` | Terminal (kitty) |
| `Super + E` | File Manager (nautilus) |
| `Super + D` | Application Launcher |
| `Super + B` | Browser |
| `Super + Q` | Close Window |
| `Super + M` | Exit Hyprland |
| `Super + L` | Lock Screen |

### Workspaces
| Binding | Action |
|---------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Scroll` | Cycle workspaces |

### Windows
| Binding | Action |
|---------|--------|
| `Super + F` | Fullscreen |
| `Super + Space` | Toggle floating |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |

### Screenshots
| Binding | Action |
|---------|--------|
| `Print` | Region screenshot |
| `Super + Print` | Monitor screenshot |
| `Super + Shift + Print` | Window screenshot |
| `Super + Ctrl + Print` | Region + edit (swappy) |

### Screen Recording
| Binding | Action |
|---------|--------|
| `Super + Shift + R` | Toggle recording |
| `Super + Ctrl + R` | Recording menu |
| `Super + Shift + Q` | Stop recording |

### Utilities
| Binding | Action |
|---------|--------|
| `Super + N` | Notification panel |
| `Super + V` | Clipboard history |
| `Super + W` | Wallpaper picker |

## Theming

### Apply Wallpaper Theme

The theme system extracts colors from your wallpaper and applies them across:
- Hyprland window borders
- Waybar
- SwayNC notification panel

```bash
~/.config/hypr/scripts/wallpaper-theme.sh ~/Pictures/Wallpapers/your-wallpaper.jpg
```

### Supported Transition Effects

```bash
# Available transitions: grow, wave, wipe, center, random
~/.config/hypr/scripts/wallpaper-theme.sh ~/Pictures/wallpaper.jpg wave
```

## Directory Structure

```
dotfiles/
├── hypr/
│   ├── hyprland.conf       # Main config
│   ├── keybindings.conf    # Key bindings
│   ├── autostart.conf      # Startup applications
│   ├── design.conf         # Visual settings
│   ├── monitors.conf       # Display configuration
│   └── scripts/
│       ├── wallpaper-theme.sh
│       ├── screenshot.sh
│       ├── screenrecord.sh
│       ├── clipboard.sh
│       └── powermenu.sh
├── waybar/
│   ├── config.jsonc
│   ├── style.css
│   └── colors.css          # Dynamic colors
├── swaync/
│   ├── config.json
│   ├── style.css
│   └── colors.css          # Dynamic colors
├── gtk-3.0/
│   └── settings.ini
├── gtk-4.0/
│   └── settings.ini
└── xdg-desktop-portal/
    └── hyprland-portals.conf
```

## Customization

### Adding Custom Keybindings

Edit `~/.config/hypr/keybindings.conf`:

```conf
bind = $mod, KEY, exec, command
```

### Changing Default Applications

Edit the variables in `~/.config/hypr/keybindings.conf`:

```conf
$terminal = kitty
$browser = firefox
$file_manager = nautilus
```

### Waybar Modules

Edit `~/.config/waybar/config.jsonc` to add/remove modules.

## Troubleshooting

### Screen sharing not working

1. Ensure `xdg-desktop-portal-hyprland` is installed
2. Restart the portal: `systemctl --user restart xdg-desktop-portal`

### No sound

1. Check PipeWire is running: `systemctl --user status pipewire`
2. Restart PipeWire: `systemctl --user restart pipewire wireplumber`

### Waybar not starting

Check for CSS errors: `waybar` in terminal to see error output.

## Dependencies

### Required
- hyprland, hyprlock, hypridle
- waybar, swaync, rofi-wayland
- swww (wallpaper daemon)
- pipewire, wireplumber

### Optional
- python-pywal (dynamic theming)
- grim, slurp, swappy (screenshots)
- wf-recorder (screen recording)
- cliphist (clipboard history)

## Credits

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- [SwayNC](https://github.com/ErikReider/SwayNotificationCenter)
- [pywal](https://github.com/dylanaraps/pywal)

## License

MIT License - Feel free to use and modify!
