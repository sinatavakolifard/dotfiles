#!/bin/bash
{
    passwords=$(pass)
    # echo $passwords
    echo $(python3 ~/.config/hypr/scripts/pass_path_generator.py "$passwords")
    selection=$(python3 ~/.config/hypr/scripts/pass_path_generator.py $passwords | /usr/bin/wofi --dmenu -p "Password")
    [ -n "$selection" ] && pass -c "$selection"
} &>> /tmp/passmenu_debug.log