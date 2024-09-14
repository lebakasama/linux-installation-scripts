#!/bin/bash

sudo pacman -S --noconfirm \
	gnome-shell \
	gdm \
	gnome-backgrounds \
    gnome-browser-connector \
	gnome-control-center \
	gnome-keyring \
    gnome-system-monitor \
    loupe \
	nautilus \
	xdg-user-dirs \
    xorg-server

yay -S --noconfirm \
    gnome-terminal-transparency

systemctl enable gdm

