#!/bin/bash

sudo pacman -S --noconfirm \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    kitty \
    waybar \
    wofi \
    otf-font-awesome ttf-arimo=nerd noto-fonts

# Screen brightness control
yay -S --noconfirm bc brightnessctl 

# Sound control panel
pacman -S --noconfirm pavucontrol
