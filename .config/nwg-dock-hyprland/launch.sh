#!/usr/bin/env bash

pkill -x nwg-dock-hyprland 2>/dev/null
sleep 0.3

exec nwg-dock-hyprland \
    -p bottom \
    -i 44 \
    -l bottom \
    -x \
    -lp start \
    -c "rofi -show drun" \
    -s style.css
