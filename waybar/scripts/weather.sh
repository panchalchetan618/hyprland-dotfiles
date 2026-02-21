#!/bin/bash
# Weather Module - macOS style popup
# Beautiful rofi-based weather display

CACHE_DIR="$HOME/.cache/weather"
CACHE_FILE="$CACHE_DIR/current.json"
CACHE_EXPIRY=3600
THEME="$HOME/.config/rofi/weather.rasi"

mkdir -p "$CACHE_DIR"

# Weather icons
get_icon() {
    case "$1" in
        113) echo "󰖙" ;; # clear
        116) echo "󰖕" ;; # partly cloudy
        119|122) echo "󰖐" ;; # cloudy
        143|248) echo "󰖑" ;; # fog
        176|263|266|293|296|353) echo "󰖗" ;; # light rain
        179|182|281|311|320|323|326) echo "󰖘" ;; # sleet/snow mix
        200|386|389) echo "󰙾" ;; # thunder
        227|230|329|332|338|392|395) echo "󰖘" ;; # snow
        299|302|305|308|356|359) echo "󰖖" ;; # heavy rain
        350) echo "󰖘" ;; # ice pellets
        *) echo "󰖐" ;; # default
    esac
}

# Check cache
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    [[ $age -lt $CACHE_EXPIRY ]]
}

# Fetch weather
fetch_weather() {
    local data=$(curl -sf "wttr.in/?format=j1" --connect-timeout 5 --max-time 10)
    [[ -n "$data" ]] && echo "$data" > "$CACHE_FILE"
    echo "$data"
}

get_weather() {
    if is_cache_valid; then
        cat "$CACHE_FILE"
    else
        fetch_weather
    fi
}

# Format for waybar
format_waybar() {
    local data=$(get_weather)

    if [[ -z "$data" ]]; then
        echo '{"text": "󰅤", "tooltip": "Weather unavailable", "class": "disconnected"}'
        return
    fi

    local temp=$(echo "$data" | jq -r '.current_condition[0].temp_C // "?"')
    local code=$(echo "$data" | jq -r '.current_condition[0].weatherCode // "116"')
    local condition=$(echo "$data" | jq -r '.current_condition[0].weatherDesc[0].value // "Unknown"')
    local feels=$(echo "$data" | jq -r '.current_condition[0].FeelsLikeC // "?"')
    local humidity=$(echo "$data" | jq -r '.current_condition[0].humidity // "?"')
    local location=$(echo "$data" | jq -r '.nearest_area[0].areaName[0].value // "Unknown"')

    local icon=$(get_icon "$code")

    local tooltip="$location\n$condition\n───────────\n󰔏 Temp: ${temp}°C\n󰔄 Feels: ${feels}°C\n󰖎 Humidity: ${humidity}%"

    local class="normal"
    [[ $temp -gt 30 ]] && class="hot"
    [[ $temp -lt 10 ]] && class="cold"

    printf '{"text": "%s %s°", "tooltip": "%s", "class": "%s"}\n' "$icon" "$temp" "$tooltip" "$class"
}

# Show forecast popup
show_forecast() {
    local data=$(get_weather)

    if [[ -z "$data" ]]; then
        notify-send "Weather" "Unable to fetch weather data" -u warning
        return
    fi

    local location=$(echo "$data" | jq -r '.nearest_area[0].areaName[0].value')
    local country=$(echo "$data" | jq -r '.nearest_area[0].country[0].value')
    local temp=$(echo "$data" | jq -r '.current_condition[0].temp_C')
    local feels=$(echo "$data" | jq -r '.current_condition[0].FeelsLikeC')
    local condition=$(echo "$data" | jq -r '.current_condition[0].weatherDesc[0].value')
    local code=$(echo "$data" | jq -r '.current_condition[0].weatherCode')
    local humidity=$(echo "$data" | jq -r '.current_condition[0].humidity')
    local wind=$(echo "$data" | jq -r '.current_condition[0].windspeedKmph')
    local uv=$(echo "$data" | jq -r '.current_condition[0].uvIndex')

    local icon=$(get_icon "$code")

    # Build display
    local display=""
    display+="<span size='x-large' weight='bold'>$icon  ${temp}°C</span>\n"
    display+="<span color='#a6adc8'>$condition</span>\n\n"
    display+="<span weight='bold'>$location</span>, $country\n\n"
    display+="<span color='#6c7086'>━━━━━━━━━━━━━━━━━━━━━━</span>\n\n"
    display+="󰔄  Feels like <span weight='bold'>${feels}°C</span>\n"
    display+="󰖎  Humidity <span weight='bold'>${humidity}%</span>\n"
    display+="󰖝  Wind <span weight='bold'>${wind} km/h</span>\n"
    display+="󰖙  UV Index <span weight='bold'>$uv</span>\n\n"
    display+="<span color='#6c7086'>━━━━━━━━━━━━━━━━━━━━━━</span>\n\n"
    display+="<span weight='bold'>3-Day Forecast</span>\n\n"

    # Forecast
    for i in 0 1 2; do
        local date=$(echo "$data" | jq -r ".weather[$i].date")
        local max=$(echo "$data" | jq -r ".weather[$i].maxtempC")
        local min=$(echo "$data" | jq -r ".weather[$i].mintempC")
        local fcode=$(echo "$data" | jq -r ".weather[$i].hourly[4].weatherCode")
        local ficon=$(get_icon "$fcode")

        local day_name
        case $i in
            0) day_name="Today    " ;;
            1) day_name="Tomorrow " ;;
            *) day_name=$(date -d "$date" +"%a      ") ;;
        esac

        display+="$ficon  $day_name<span weight='bold'>${max}°</span> / ${min}°\n"
    done

    # Show in rofi
    echo -e "$display" | rofi -dmenu \
        -mesg "$(echo -e "$display")" \
        -markup \
        -p "" \
        -theme "$THEME" \
        -theme-str 'listview { enabled: false; }' \
        -theme-str 'inputbar { enabled: false; }' \
        -theme-str 'message { padding: 20px; }' \
        -theme-str 'window { width: 320px; }'
}

# Main
case "$1" in
    forecast) show_forecast ;;
    refresh) rm -f "$CACHE_FILE"; format_waybar ;;
    *) format_waybar ;;
esac
