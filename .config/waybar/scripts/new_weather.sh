#!/usr/bin/env bash

# Load .env file
if [ -f "$HOME/.env" ]; then
  source $HOME/.env
fi

for i in {1..5}
do
  weather_json=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LATITUDE&longitude=$LONGITUDE&daily=temperature_2m_max,temperature_2m_min,weather_code&current=weather_code,temperature_2m,wind_speed_10m,is_day&timezone=Europe%2FBerlin") 
  if [[ $? == 0 ]]
  then
    is_day=$(echo $weather_json | jq .current.is_day)
    weather_code=$(echo $weather_json | jq .current.weather_code)
    temp=$(echo $weather_json | jq '.current.temperature_2m | round')

    if [ "$is_day" -eq 1 ]; then
      icon=$(jq -r --arg c "$weather_code" '.[$c].day.icon' ~/.config/waybar/scripts/weather_codes.json)
    else
      icon=$(jq -r --arg c "$weather_code" '.[$c].night.icon' ~/.config/waybar/scripts/weather_codes.json)
    fi

    tooltip=""
    for i in $(jq 'range(0; .daily.time | length)' <<< "$weather_json"); do
      date=$(jq -r ".daily.time[$i]" <<< "$weather_json")
      code=$(jq -r ".daily.weather_code[$i]" <<< "$weather_json")
      icon=$(jq -r --arg c "$code" '.[$c].day.icon' ~/.config/waybar/scripts/weather_codes.json)
      min=$(jq -r ".daily.temperature_2m_min[$i] | round" <<< "$weather_json")
      max=$(jq -r ".daily.temperature_2m_max[$i] | round" <<< "$weather_json")
      tooltip+="$date    $icon   $min°C,  $max°C"$'\n'
    done

    # tooltip_escaped=$(printf '%s' "$tooltip" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    # icon_temp_escaped=$(printf '%s' "$icon  $temp°C" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

    # echo "{\"text\":$icon_temp_escaped, \"tooltip\":$tooltip_escaped}"

    json_escape() {
      local str="$1"
      printf '%s' "$str" | sed \
        -e 's/\\/\\\\/g' \
        -e 's/"/\\"/g' \
        -e ':a;N;$!ba;s/\n/\\n/g'
    }

    # Escape for JSON
    text_escaped=$(json_escape "$icon  $temp°C")
    tooltip_escaped=$(json_escape "$tooltip")

    # Output Waybar-safe JSON
    echo "{\"text\":\"$text_escaped\", \"tooltip\":\"$tooltip_escaped\"}"
    exit
  fi
  sleep 2
done