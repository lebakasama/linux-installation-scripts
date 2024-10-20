#!/bin/bash

sudo pacman -S --noconfirm \
	fcitx5-mozc \
	fcitx5-configtool \
	gnome-shell \
	gdm \
	gnome-backgrounds \
    gnome-browser-connector \
	gnome-control-center \
	gnome-firmware \
	gnome-keyring \
    gnome-system-monitor \
    loupe \
	nautilus \
    sane-airscan \
    simple-scan \
	xdg-user-dirs \
    xorg-server

yay -S --noconfirm \
    gnome-terminal-transparency

systemctl enable gdm

