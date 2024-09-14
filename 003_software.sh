#!/bin/bash

sudo pacman -S --noconfirm \
	firefox noto-fonts-cjk noto-fonts-emoji noto-fonts

yay -S --noconfirm \
	chrome-gnome-shell \
	kopia-bin \
	kopia-ui-bin \
	surfshark-client networkmanager-openvpn \
	input-remapper-git \
    vlc

