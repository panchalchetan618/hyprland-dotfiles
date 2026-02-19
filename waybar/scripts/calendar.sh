#!/bin/bash
# Calendar Popup - macOS style
# Beautiful rofi-based calendar display

THEME="$HOME/.config/rofi/calendar.rasi"

# Get formatted calendar
get_calendar() {
    local month_year=$(date "+%B %Y")
    local today=$(date +%-d)

    # Header
    echo "<span size='large' weight='bold'>$month_year</span>"
    echo ""

    # Calendar with highlighted today
    cal | tail -n +2 | while read -r line; do
        # Highlight today's date
        if [[ -n "$line" ]]; then
            # Use pango markup for highlighting
            highlighted=$(echo "$line" | sed "s/\b$today\b/<span color='#a6e3a1' weight='bold'>$today<\/span>/g")
            echo "$highlighted"
        fi
    done

    echo ""
    echo "<span color='#6c7086'>$(date '+%A, %B %d, %Y')</span>"
}

# Show calendar popup
show_calendar() {
    local cal_display=$(get_calendar)

    rofi -e "$cal_display" \
        -markup \
        -theme "$THEME" \
        -theme-str 'textbox { font: "JetBrainsMono Nerd Font 11"; }'
}

# Alternative: Show with navigation
show_calendar_interactive() {
    local current_month=$(date +%m)
    local current_year=$(date +%Y)
    local offset=0

    while true; do
        local target_date=$(date -d "$current_year-$current_month-01 +${offset} months" +%Y-%m-%d)
        local month_year=$(date -d "$target_date" "+%B %Y")
        local cal_output=$(cal $(date -d "$target_date" "+%m %Y"))

        local display="<span size='large' weight='bold'>    $month_year</span>\n\n"
        display+="<span font='JetBrainsMono Nerd Font 10'>"
        display+=$(echo "$cal_output" | tail -n +2)
        display+="</span>\n\n"
        display+="<span color='#6c7086'>󰁍 Previous    Today    Next 󰁔</span>"

        local options="󰁍  Previous Month\n󰃭  Today\n󰁔  Next Month\n─────────────────\n󰅖  Close"

        local selected=$(echo -e "$options" | rofi -dmenu \
            -mesg "$display" \
            -markup \
            -p "📅" \
            -theme "$THEME" \
            -theme-str 'listview { lines: 5; }' \
            -theme-str 'window { width: 320px; }')

        case "$selected" in
            *"Previous"*)
                ((offset--)) ;;
            *"Today"*)
                offset=0 ;;
            *"Next"*)
                ((offset++)) ;;
            *)
                break ;;
        esac
    done
}

# Quick display (just show current month)
show_quick() {
    local month_year=$(date "+%B %Y")
    local cal_text=$(cal | tail -n +2)
    local today_info=$(date '+%A, %B %d, %Y')

    local display="<span size='x-large' weight='bold'>$month_year</span>\n\n"
    display+="<span font='JetBrainsMono Nerd Font 11'><tt>$cal_text</tt></span>\n\n"
    display+="<span color='#a6adc8'>$today_info</span>"

    echo -e "$display" | rofi -dmenu \
        -mesg "$(echo -e "$display")" \
        -markup \
        -p "" \
        -theme "$THEME" \
        -theme-str 'listview { enabled: false; }' \
        -theme-str 'inputbar { enabled: false; }' \
        -theme-str 'message { padding: 24px; }' \
        -theme-str 'textbox { horizontal-align: 0.5; }'
}

# Main
case "$1" in
    interactive) show_calendar_interactive ;;
    *) show_quick ;;
esac
