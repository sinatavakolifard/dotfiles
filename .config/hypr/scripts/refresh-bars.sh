#!/bin/sh
# Called from hyprland.lua when a monitor is added.
# Waybar and hyprpaper don't always pick up monitors that come back (e.g. dock after resume),
# so reload waybar and restart hyprpaper (only if it was running; its IPC is off).
# Only done when a monitor is actually missing its bar or wallpaper, so that e.g. opening
# the lid (which waybar handles by itself) doesn't make every bar flicker.

# The lock makes monitors added together (e.g. both dock monitors) trigger a single refresh:
# the first call takes it, the others exit.
exec 9>"$XDG_RUNTIME_DIR/hypr-monitor-refresh.lock"
flock -n 9 || exit 0

sleep 1 # let the monitors come up

# Prints the enabled monitors that have no layer with the given namespace
missing() {
    hyprctl layers -j | jq -r --argjson mons "$(hyprctl monitors -j)" --arg ns "$1" \
        '. as $l | $mons[].name | select([$l[.].levels[]?[]?.namespace] | index($ns) | not)'
}

if [ -n "$(missing waybar)" ]; then
    pkill -SIGUSR2 -x waybar
fi
# 9>&- keeps hyprpaper from inheriting the lock, so it is released when this script ends
if [ -n "$(missing hyprpaper)" ] && pkill -x hyprpaper; then
    hyprpaper 9>&- &
fi
