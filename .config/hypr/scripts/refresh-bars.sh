#!/bin/sh
# Called from hyprland.lua when a monitor is added.
# Reloads the Hyprland config so the workspace rules find the monitor (they look monitors up
# by EDID serial on config load). The reload waits until the monitors have settled: after
# resume the dock monitors come and go for a few seconds, some without a mode (0x0), and
# reloading then crashed Hyprland 0.57.1 (std::bad_any_cast in CMonitorResources::initFB).
# Waybar and hyprpaper don't always pick up monitors that come back (e.g. dock after resume),
# so reload waybar and restart hyprpaper (only if it was running; its IPC is off).
# Only done when a monitor is actually missing its bar or wallpaper, so that e.g. opening
# the lid (which waybar handles by itself) doesn't make every bar flicker.

# The lock makes monitors added together (e.g. both dock monitors) trigger a single refresh:
# the first call takes it, the others leave a marker (so it starts checking again) and exit.
# That call keeps checking for a while, because after resume the dock monitors return one by
# one and a reload sent too early doesn't stick.
again="$XDG_RUNTIME_DIR/hypr-monitor-refresh.again"
hibernated="$XDG_RUNTIME_DIR/hypr-hibernated"
exec 9>"$XDG_RUNTIME_DIR/hypr-monitor-refresh.lock"
flock -n 9 || { touch "$again"; exit 0; }
rm -f "$again"

sleep 1 # let the monitors come up

# Prints the enabled monitors that have no layer with the given namespace
missing() {
    hyprctl layers -j | jq -r --argjson mons "$(hyprctl monitors -j)" --arg ns "$1" \
        '. as $l | $mons[].name | select([$l[.].levels[]?[]?.namespace] | index($ns) | not)'
}

# Prints the monitors that are listed with a 0x0 size (connected but without a mode)
modeless() {
    hyprctl monitors -j | jq -r '.[] | select(.width == 0 or .height == 0) | .name'
}

# Monitors that come back after resume can appear a few seconds late (the dock's MST link
# retrains first), and right after resume Hyprland may list no monitors at all. So the monitors
# only count as settled when some are listed and none is 0x0, twice in a row, 2s apart. Then the
# config is reloaded once. The bars count as fine after two good checks in a row as well.
# A monitor added meanwhile (the marker) starts everything over, including the reload.
# 9>&- keeps hyprpaper from inheriting the lock, so it is released when this script ends
# Waybar 0.15 can also deadlock (seen after resume) and then ignores SIGUSR2, so after 3
# reloads that didn't help it is killed; SIGKILL (137) makes waybar.sh start a fresh one.
settled=0
reloaded=0
good=0
reloads=0
for _ in $(seq 15); do
    if [ -e "$again" ]; then
        rm -f "$again"
        settled=0
        reloaded=0
        good=0
    elif [ -z "$(hyprctl monitors -j | jq -r '.[].name')" ] || [ -n "$(modeless)" ]; then
        settled=0
        good=0
    else
        settled=$((settled + 1))
        if [ "$settled" -ge 2 ] && [ "$reloaded" = 0 ]; then
            if [ -e "$hibernated" ] && [ $(($(date +%s) - $(stat -c %Y "$hibernated"))) -lt 20 ]; then
                : # too early after a hibernation, see below; check again on the next round
            elif [ -e "$hibernated" ]; then
                # First reload after a hibernation (marker from the dock-redetect sleep hook):
                # the dock monitors may be listed but black (DP link failed during resume).
                # Turning them off and on trains the link again; the full reload turns them
                # back on from the monitor rules. Done 4 s after resume it didn't help, 20 s
                # after resume it did. The settled check above made sure no monitor is 0x0,
                # since a reload with a 0x0 monitor crashes Hyprland 0.57.1.
                rm -f "$hibernated"
                externals=$(hyprctl monitors -j | jq -r '.[].name | select(startswith("eDP") | not)')
                echo "after hibernation, turning off and on: $externals" | tr '\n' ' ' | systemd-cat -t refresh-bars
                for m in $externals; do
                    hyprctl eval "hl.monitor({ output = \"$m\", disabled = true })" >/dev/null
                done
                sleep 2
                hyprctl reload >/dev/null
                reloaded=1
            else
                hyprctl reload config-only >/dev/null
                reloaded=1
            fi
        fi
        no_bar=$(missing waybar)
        no_paper=$(missing hyprpaper)
        if [ -z "$no_bar$no_paper" ]; then
            good=$((good + 1))
            [ "$good" -ge 2 ] && [ "$reloaded" = 1 ] && exit 0
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
[ "$reloaded" = 0 ] && echo "monitors never settled, config not reloaded; modeless: $(modeless)" | tr '\n' ' ' | systemd-cat -t refresh-bars -p warning
echo "gave up, still no bar on: $(missing waybar)" | tr '\n' ' ' | systemd-cat -t refresh-bars -p warning
