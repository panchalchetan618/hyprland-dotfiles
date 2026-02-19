#!/bin/bash
# System Monitor - macOS style popup
# Beautiful rofi-based system stats

THEME="$HOME/.config/rofi/sysmon.rasi"

# CPU usage
get_cpu() {
    top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}'
}

# Memory
get_memory() {
    free -m | awk '/^Mem:/ {printf "%d|%d|%d", $3, $2, int($3*100/$2)}'
}

# Disk
get_disk() {
    df -h / | awk 'NR==2 {print $3 "|" $2 "|" $5}' | tr -d '%'
}

# Temperature
get_temp() {
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        echo $(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    else
        echo "?"
    fi
}

# GPU (Intel)
get_gpu() {
    if command -v intel_gpu_top &>/dev/null; then
        timeout 1 intel_gpu_top -s 500 -o - 2>/dev/null | grep -oP '\d+' | head -1 || echo "0"
    else
        echo "N/A"
    fi
}

# Progress bar
progress_bar() {
    local percent=$1
    local width=${2:-20}
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="━"; done
    for ((i=0; i<empty; i++)); do bar+="─"; done

    # Color based on usage
    local color="#a6e3a1"  # green
    [[ $percent -gt 60 ]] && color="#f9e2af"  # yellow
    [[ $percent -gt 85 ]] && color="#f38ba8"  # red

    echo "<span color='$color'>$bar</span>"
}

# Format for waybar
format_waybar() {
    local cpu=$(get_cpu)
    local mem_info=$(get_memory)
    local mem_percent=$(echo "$mem_info" | cut -d'|' -f3)

    local icon="󰍛"
    [[ $cpu -gt 50 ]] && icon="󰊚"
    [[ $cpu -gt 80 ]] && icon="󰀪"

    local class="normal"
    [[ $cpu -gt 80 || $mem_percent -gt 80 ]] && class="warning"
    [[ $cpu -gt 95 || $mem_percent -gt 95 ]] && class="critical"

    local tooltip="System Monitor\n───────────\n󰻠 CPU: ${cpu}%\n󰍛 RAM: ${mem_percent}%"

    printf '{"text": "%s %s%%", "tooltip": "%s", "class": "%s"}\n' "$icon" "$cpu" "$tooltip" "$class"
}

# Show detailed popup
show_popup() {
    local cpu=$(get_cpu)
    local temp=$(get_temp)

    local mem_info=$(get_memory)
    local mem_used=$(echo "$mem_info" | cut -d'|' -f1)
    local mem_total=$(echo "$mem_info" | cut -d'|' -f2)
    local mem_percent=$(echo "$mem_info" | cut -d'|' -f3)

    local disk_info=$(get_disk)
    local disk_used=$(echo "$disk_info" | cut -d'|' -f1)
    local disk_total=$(echo "$disk_info" | cut -d'|' -f2)
    local disk_percent=$(echo "$disk_info" | cut -d'|' -f3)

    local uptime=$(uptime -p | sed 's/up //')

    # Build display
    local display=""
    display+="<span size='large' weight='bold'>System Monitor</span>\n\n"

    # CPU
    display+="<span weight='bold'>󰻠  CPU</span>                    ${cpu}%\n"
    display+="   $(progress_bar $cpu 24)\n\n"

    # Memory
    display+="<span weight='bold'>󰍛  Memory</span>              ${mem_percent}%\n"
    display+="   $(progress_bar $mem_percent 24)\n"
    display+="   <span color='#6c7086'>${mem_used}M / ${mem_total}M</span>\n\n"

    # Disk
    display+="<span weight='bold'>󰋊  Disk</span>                  ${disk_percent}%\n"
    display+="   $(progress_bar $disk_percent 24)\n"
    display+="   <span color='#6c7086'>${disk_used} / ${disk_total}</span>\n\n"

    # Temperature
    display+="<span weight='bold'>󰔏  Temperature</span>       ${temp}°C\n\n"

    # Uptime
    display+="<span weight='bold'>󰅐  Uptime</span>              $uptime\n\n"

    display+="<span color='#6c7086'>━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>\n\n"

    # Top processes
    display+="<span weight='bold'>󰓩  Top Processes</span>\n\n"

    ps aux --sort=-%cpu | head -6 | tail -5 | while read -r user pid cpu mem vsz rss tty stat start time cmd; do
        local proc_name=$(echo "$cmd" | awk '{print $1}' | xargs basename 2>/dev/null | cut -c1-18)
        printf "   %-18s <span color='#89b4fa'>%5s%%</span>  %5s%%\n" "$proc_name" "$cpu" "$mem"
    done

    local procs=$(ps aux --sort=-%cpu | head -6 | tail -5 | while read -r user pid cpu mem vsz rss tty stat start time cmd; do
        local proc_name=$(echo "$cmd" | awk '{print $1}' | xargs basename 2>/dev/null | cut -c1-18)
        printf "   %-18s <span color='#89b4fa'>%5s%%</span>  %5s%%\n" "$proc_name" "$cpu" "$mem"
    done)

    display+="$procs"

    # Show in rofi
    local options="󰑓  Refresh\n󰍹  Open System Monitor\n󰅖  Close"

    local selected=$(echo -e "$options" | rofi -dmenu \
        -mesg "$(echo -e "$display")" \
        -markup \
        -p "󰍛" \
        -theme "$THEME" \
        -theme-str 'listview { lines: 3; }' \
        -theme-str 'window { width: 380px; }')

    case "$selected" in
        *"Refresh"*)
            show_popup ;;
        *"System Monitor"*)
            kitty --class floating-sysmon btop & ;;
    esac
}

# Main
case "$1" in
    popup|details) show_popup ;;
    live) kitty --class floating-sysmon --title "System Monitor" btop ;;
    *) format_waybar ;;
esac
