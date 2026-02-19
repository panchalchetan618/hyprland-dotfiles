#!/bin/bash
# Power menu script with confirmation dialogs

ACTION="$1"

confirm_action() {
    local action="$1"
    local icon="$2"
    local message="$3"

    local choice=$(echo -e "  Yes, $action\n  Cancel" | rofi -dmenu -p "$icon $message" -i -theme-str 'window {width: 350px;} listview {lines: 2;}')

    if [[ "$choice" == *"Yes"* ]]; then
        return 0
    fi
    return 1
}

case "$ACTION" in
    lock)
        hyprlock
        ;;
    suspend)
        systemctl suspend
        ;;
    reboot)
        if confirm_action "reboot" "󰜉" "Reboot system?"; then
            systemctl reboot
        fi
        ;;
    shutdown)
        if confirm_action "shutdown" "󰐥" "Shut down system?"; then
            systemctl poweroff
        fi
        ;;
    logout)
        if confirm_action "logout" "󰍃" "Log out?"; then
            hyprctl dispatch exit
        fi
        ;;
    menu)
        options="󰌾   Lock
󰤄   Suspend
󰍃   Logout
󰜉   Reboot
󰐥   Shut Down"

        choice=$(echo -e "$options" | rofi -dmenu -p "󰐦  Power" -i -theme-str 'window {width: 400px;} listview {lines: 5;}')

        case "$choice" in
            *"Lock"*)
                hyprlock
                ;;
            *"Suspend"*)
                systemctl suspend
                ;;
            *"Logout"*)
                $0 logout
                ;;
            *"Reboot"*)
                $0 reboot
                ;;
            *"Shut Down"*)
                $0 shutdown
                ;;
        esac
        ;;
    *)
        echo "Usage: powermenu.sh [lock|suspend|reboot|shutdown|logout|menu]"
        ;;
esac
