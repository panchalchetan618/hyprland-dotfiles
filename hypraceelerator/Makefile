PREFIX=$(HOME)/.config
SYSUSER=$(HOME)/.config/systemd/user

install:
	mkdir -p $(SYSUSER)
	cp -f $(PREFIX)/hypraceelerator/systemd/*.service $(SYSUSER)/
	cp -f $(PREFIX)/hypraceelerator/systemd/*.timer $(SYSUSER)/
	@echo "Installed systemd user units."

enable:
	systemctl --user daemon-reload
	systemctl --user enable --now downloads-organizer.service
	systemctl --user enable --now downloads-archive.timer
	systemctl --user enable --now screenshots-organizer.timer
	systemctl --user enable --now clipboard-cleanup.timer
	systemctl --user enable --now system-alerts.timer
	systemctl --user enable --now dotfiles-backup.timer
	systemctl --user enable --now tasks-sync.timer
	@echo "Enabled automations."

status:
	systemctl --user list-timers | rg 'downloads|screenshots|clipboard|system-alerts|dotfiles|tasks'

