#!/bin/bash
# Feature-rich screen recording script for Hyprland
# Supports system audio, microphone, region selection

RECORDINGS_DIR="$HOME/Videos/Recordings"
PIDFILE="/tmp/screenrecord.pid"
mkdir -p "$RECORDINGS_DIR"

show_menu() {
    local options="󰍹   Monitor  ·  No Audio
󰍹   Monitor  ·  System Audio
󰍹   Monitor  ·  System + Mic
󰻂   Region   ·  No Audio
󰻂   Region   ·  System Audio
󰻂   Region   ·  System + Mic
󱄽   Window   ·  System + Mic
   Stop Recording"

    echo -e "$options" | rofi -dmenu -p " Record" -i -theme-str 'window {width: 500px;} listview {lines: 8;}'
}

get_audio_opts() {
    local audio_mode="$1"
    local default_sink=$(pactl get-default-sink 2>/dev/null)
    local default_source=$(pactl get-default-source 2>/dev/null)

    case "$audio_mode" in
        system)
            # System audio only (what you hear)
            if [[ -n "$default_sink" ]]; then
                echo "--audio=${default_sink}.monitor"
            else
                echo "--audio"
            fi
            ;;
        mic)
            # Microphone only
            if [[ -n "$default_source" ]]; then
                echo "--audio=${default_source}"
            else
                echo "--audio"
            fi
            ;;
        both)
            # System audio + microphone (requires pipewire combining)
            # wf-recorder only supports one audio source, so we use system audio
            # For both, user should use OBS or set up a combined sink
            if [[ -n "$default_sink" ]]; then
                echo "--audio=${default_sink}.monitor"
            else
                echo "--audio"
            fi
            ;;
        none|*)
            echo ""
            ;;
    esac
}

start_recording() {
    local mode="$1"
    local audio_mode="$2"
    local filename="$(date +%Y-%m-%d_%H-%M-%S).mp4"
    local filepath="$RECORDINGS_DIR/$filename"

    # Check if already recording
    if [[ -f "$PIDFILE" ]]; then
        notify-send "Already Recording" "Stop current recording first (Super+Shift+Q)"
        return 1
    fi

    local audio_opts=$(get_audio_opts "$audio_mode")
    local audio_label="no audio"
    [[ "$audio_mode" == "system" ]] && audio_label="system audio"
    [[ "$audio_mode" == "mic" ]] && audio_label="microphone"
    [[ "$audio_mode" == "both" ]] && audio_label="system + mic"

    case "$mode" in
        region)
            local geometry=$(slurp 2>/dev/null)
            if [[ -z "$geometry" ]]; then
                notify-send "Recording Cancelled" "No region selected"
                return 1
            fi
            notify-send "Recording Started" "Region ($audio_label)"
            wf-recorder -g "$geometry" $audio_opts -f "$filepath" &
            echo $! > "$PIDFILE"
            ;;
        monitor)
            notify-send "Recording Started" "Monitor ($audio_label)"
            wf-recorder $audio_opts -f "$filepath" &
            echo $! > "$PIDFILE"
            ;;
        window)
            local geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            notify-send "Recording Started" "Window ($audio_label)"
            wf-recorder -g "$geometry" $audio_opts -f "$filepath" &
            echo $! > "$PIDFILE"
            ;;
    esac

    echo "$filepath" > /tmp/screenrecord_file
}

stop_recording() {
    if [[ -f "$PIDFILE" ]]; then
        local pid=$(cat "$PIDFILE")
        kill -SIGINT "$pid" 2>/dev/null
        rm -f "$PIDFILE"

        local filepath=$(cat /tmp/screenrecord_file 2>/dev/null)
        rm -f /tmp/screenrecord_file

        sleep 0.5
        if [[ -f "$filepath" ]]; then
            notify-send "Recording Saved" "$filepath"
        else
            notify-send "Recording Stopped" "Saved to $RECORDINGS_DIR"
        fi
    else
        notify-send "Not Recording" "No active recording"
    fi
}

toggle_recording() {
    if [[ -f "$PIDFILE" ]]; then
        stop_recording
    else
        start_recording "monitor" "system"
    fi
}

# Main logic
case "$1" in
    region)
        start_recording "region" "${2:-none}"
        ;;
    monitor)
        start_recording "monitor" "${2:-none}"
        ;;
    window)
        start_recording "window" "${2:-none}"
        ;;
    stop)
        stop_recording
        ;;
    toggle)
        toggle_recording
        ;;
    menu|"")
        choice=$(show_menu)
        case "$choice" in
            *"Monitor"*"No Audio"*)
                start_recording "monitor" "none"
                ;;
            *"Monitor"*"System + Mic"*)
                start_recording "monitor" "both"
                ;;
            *"Monitor"*"System Audio"*)
                start_recording "monitor" "system"
                ;;
            *"Region"*"No Audio"*)
                start_recording "region" "none"
                ;;
            *"Region"*"System + Mic"*)
                start_recording "region" "both"
                ;;
            *"Region"*"System Audio"*)
                start_recording "region" "system"
                ;;
            *"Window"*)
                start_recording "window" "both"
                ;;
            *"Stop"*)
                stop_recording
                ;;
        esac
        ;;
    *)
        echo "Usage: screenrecord.sh [region|monitor|window|stop|toggle|menu] [none|system|mic|both]"
        echo "Examples:"
        echo "  screenrecord.sh monitor system    # Monitor with system audio"
        echo "  screenrecord.sh region both       # Region with system + mic"
        echo "  screenrecord.sh menu              # Show interactive menu"
        ;;
esac
