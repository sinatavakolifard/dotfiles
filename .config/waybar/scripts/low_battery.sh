#!/bin/bash

# LOW_BATTERY_LEVEL=15
CRITICAL_BATTERY_LEVEL=9
BATTERY_PATH=$(upower -e | grep 'battery')

BATTERY_PERCENT=$(upower -i "$BATTERY_PATH" | awk '/percentage/ {print $2}' | tr -d '%')
BATTERY_STATE=$(upower -i "$BATTERY_PATH" | awk '/state/ {print $2}')

if [[ "$BATTERY_STATE" == "discharging" ]]; then
    if (( BATTERY_PERCENT <= CRITICAL_BATTERY_LEVEL )); then
        notify-send -u critical --hint=boolean:transient:true "Battery Critically Low" "Battery at ${BATTERY_PERCENT}%! Plug in your charger now!"
    # elif (( BATTERY_PERCENT <= LOW_BATTERY_LEVEL )); then
    #     notify-send -u normal "Low Battery Warning" "Battery at ${BATTERY_PERCENT}%"
    fi
fi