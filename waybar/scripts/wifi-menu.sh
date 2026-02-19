#!/bin/bash
# WiFi Menu - macOS style popup
# Beautiful rofi-based network management

THEME="$HOME/.config/rofi/popup.rasi"

# Get WiFi status
get_wifi_status() {
    nmcli radio wifi
}

# Get current connection
get_current_network() {
    nmcli -t -f NAME connection show --active 2>/dev/null | head -1
}

# Get signal strength icon
get_signal_icon() {
    local signal=$1
    if [[ $signal -ge 75 ]]; then echo "󰤨"
    elif [[ $signal -ge 50 ]]; then echo "󰤥"
    elif [[ $signal -ge 25 ]]; then echo "󰤢"
    else echo "󰤟"
    fi
}

# Get available networks
get_networks() {
    nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan auto 2>/dev/null | \
        awk -F: 'NF>=2 && $1!="" && !seen[$1]++ {print $1 "|" $2 "|" $3}' | \
        sort -t'|' -k2 -rn | head -15
}

# Toggle WiFi
toggle_wifi() {
    if [[ "$(get_wifi_status)" == "enabled" ]]; then
        nmcli radio wifi off
        notify-send -i network-wireless-offline "WiFi" "Turned off"
    else
        nmcli radio wifi on
        notify-send -i network-wireless "WiFi" "Turned on"
    fi
}

# Connect to network
connect_network() {
    local ssid="$1"

    # Check if we have saved credentials
    if nmcli connection show "$ssid" &>/dev/null; then
        nmcli connection up "$ssid" 2>/dev/null && \
            notify-send -i network-wireless "WiFi" "Connected to $ssid" || \
            notify-send -u critical "WiFi" "Failed to connect to $ssid"
    else
        # Need password
        local password=$(rofi -dmenu \
            -password \
            -p "󰌾  Password" \
            -theme-str 'window {width: 300px; location: center;}' \
            -theme-str 'listview {enabled: false;}' \
            -theme-str 'inputbar {children: [prompt, entry];}' \
            -theme "$THEME")

        if [[ -n "$password" ]]; then
            nmcli device wifi connect "$ssid" password "$password" 2>/dev/null && \
                notify-send -i network-wireless "WiFi" "Connected to $ssid" || \
                notify-send -u critical "WiFi" "Failed to connect"
        fi
    fi
}

# Build menu
show_menu() {
    local current=$(get_current_network)
    local wifi_status=$(get_wifi_status)
    local options=""

    # Header info via message
    local header="WiFi Networks"

    if [[ "$wifi_status" == "enabled" ]]; then
        # Toggle option
        options+="󰖪  Turn Off WiFi\n"

        # Current connection
        if [[ -n "$current" ]]; then
            options+="󰸞  $current (Connected)\n"
        fi

        # Separator
        options+="─────────────────\n"

        # Available networks
        while IFS='|' read -r ssid signal security; do
            if [[ -n "$ssid" && "$ssid" != "$current" ]]; then
                local icon=$(get_signal_icon "$signal")
                local lock=""
                [[ -n "$security" && "$security" != "--" ]] && lock=" 󰌾"
                options+="$icon  $ssid$lock\n"
            fi
        done <<< "$(get_networks)"

        options+="─────────────────\n"
        options+="󰑓  Refresh\n"
        options+="󰒓  Network Settings"
    else
        options+="󰖩  Turn On WiFi"
    fi

    # Show rofi
    local selected=$(echo -e "$options" | rofi -dmenu \
        -p "󰤨  WiFi" \
        -theme "$THEME" \
        -selected-row 0)

    # Handle selection
    case "$selected" in
        *"Turn Off WiFi"*)
            toggle_wifi ;;
        *"Turn On WiFi"*)
            toggle_wifi ;;
        *"(Connected)"*)
            nmcli connection down "$current"
            notify-send "WiFi" "Disconnected from $current" ;;
        *"Refresh"*)
            nmcli device wifi rescan
            sleep 1
            show_menu ;;
        *"Network Settings"*)
            nm-connection-editor & ;;
        *"─────"*)
            show_menu ;;
        *)
            if [[ -n "$selected" ]]; then
                # Extract SSID (remove icon and lock symbol)
                local ssid=$(echo "$selected" | sed 's/^[^ ]* *//' | sed 's/ 󰌾$//')
                [[ -n "$ssid" ]] && connect_network "$ssid"
            fi ;;
    esac
}

# Main
case "$1" in
    toggle) toggle_wifi ;;
    *) show_menu ;;
esac
