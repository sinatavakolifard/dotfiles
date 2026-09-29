#!/bin/sh
# Started from hyprland.lua instead of plain `waybar`.
# Waybar 0.15 sometimes crashes (SIGABRT/SIGSEGV) while monitors or Bluetooth
# devices appear, e.g. at login with the dock attached, so restart it after a crash.
# A normal exit or `pkill waybar` (SIGTERM, 143) ends the loop, so a manual
# `pkill waybar; waybar &` doesn't leave two bars.
while :; do
    waybar
    status=$?
    case $status in
        0|143) exit 0 ;;
    esac
    # Compositor is gone (logout): don't keep respawning. Checks the socket rather than
    # `hyprctl version`, which can fail while Hyprland reconfigures monitors after resume
    # (exactly when waybar tends to crash), which ended the loop and left no bar.
    if [ ! -S "$XDG_RUNTIME_DIR/${WAYLAND_DISPLAY:-wayland-1}" ]; then
        echo "waybar exited with $status, compositor gone, not restarting" | systemd-cat -t waybar-wrapper -p notice
        exit 0
    fi
    echo "waybar exited with $status, restarting" | systemd-cat -t waybar-wrapper -p warning
    sleep 1
done
