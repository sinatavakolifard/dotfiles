#!/bin/sh
# Called from hyprland.lua when a monitor is added.
# Waybar and hyprpaper don't always pick up monitors that come back (e.g. dock after resume),
# so reload waybar and restart hyprpaper (only if it was running; its IPC is off).
# Only done when a monitor is actually missing its bar or wallpaper, so that e.g. opening
# the lid (which waybar handles by itself) doesn't make every bar flicker.

# The lock makes monitors added together (e.g. both dock monitors) trigger a single refresh:
# the first call takes it, the others leave a marker (so it starts checking again) and exit.
# That call keeps checking for a while, because after resume the dock monitors return one by
# one and a reload sent too early doesn't stick.
again="$XDG_RUNTIME_DIR/hypr-monitor-refresh.again"
exec 9>"$XDG_RUNTIME_DIR/hypr-monitor-refresh.lock"
flock -n 9 || { touch "$again"; exit 0; }
rm -f "$again"

sleep 1 # let the monitors come up

# Prints the enabled monitors that have no layer with the given namespace
missing() {
    hyprctl layers -j | jq -r --argjson mons "$(hyprctl monitors -j)" --arg ns "$1" \
        '. as $l | $mons[].name | select([$l[.].levels[]?[]?.namespace] | index($ns) | not)'
}

# Monitors that come back after resume can appear a few seconds late (the dock's MST link
# retrains first), and right after resume Hyprland may list no monitors at all. So a check only
# counts as good when monitors are listed, and it has to be good twice in a row, 2s apart.
# 9>&- keeps hyprpaper from inheriting the lock, so it is released when this script ends
# Waybar 0.15 can also deadlock (seen after resume) and then ignores SIGUSR2, so after 3
# reloads that didn't help it is killed; SIGKILL (137) makes waybar.sh start a fresh one.
good=0
reloads=0
for _ in $(seq 15); do
    if [ -e "$again" ]; then
        rm -f "$again"
        good=0
    elif [ -z "$(hyprctl monitors -j | jq -r '.[].name')" ]; then
        good=0
    else
        no_bar=$(missing waybar)
        no_paper=$(missing hyprpaper)
        if [ -z "$no_bar$no_paper" ]; then
            good=$((good + 1))
            [ "$good" -ge 2 ] && exit 0
        else
            good=0
            echo "no bar on: $no_bar; no wallpaper on: $no_paper" | tr '\n' ' ' | systemd-cat -t refresh-bars
            if [ -n "$no_bar" ]; then
                reloads=$((reloads + 1))
                if [ "$reloads" -gt 3 ]; then
                    echo "waybar ignored reloads, killing it" | systemd-cat -t refresh-bars -p warning
                    pkill -KILL -x waybar
                    reloads=0
                else
                    pkill -SIGUSR2 -x waybar
                fi
            fi
            if [ -n "$no_paper" ] && pkill -x hyprpaper; then
                hyprpaper 9>&- &
            fi
        fi
    fi
    sleep 2
done
echo "gave up, still no bar on: $(missing waybar)" | tr '\n' ' ' | systemd-cat -t refresh-bars -p warning
