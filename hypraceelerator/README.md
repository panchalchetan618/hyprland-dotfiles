# Hypraceelerator

Minimal, clean Hyprland theme + automations.

## Automations
- Downloads organizer (real-time)
- Downloads archive (daily)
- Screenshot organizer (weekly)
- Clipboard cleanup (daily)
- System alerts (30 min)
- Dotfiles backup (weekly)
- Tasks sync (15 min)

## Install & Enable
```
make -C ~/.config/hypraceelerator install
make -C ~/.config/hypraceelerator enable
```

## Tasks & Reminders (CalDAV)
Install: `vdirsyncer`, `khal`, `todoman`

Configure:
- `~/.config/vdirsyncer/config`
- `~/.config/khal/config`
- `~/.config/todoman/config.py`

Quick add:
- `~/.config/hypraceelerator/scripts/tasks-quickadd.sh`
