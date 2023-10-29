#!/bin/sh

# Set up monitor
xrandr --output "$(xrandr | grep " connected " | awk '{ print$1 }')" --mode 3440x1440  --rate 144.00
# Remap Menu to compose key
setxkbmap -option compose:menu
# Wallpaper
nitrogen --restore &
# Start lxsession
lxsession & disown
# Start picom
picom -b --config ~/.config/picom/picom.conf

