#!/bin/bash

pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth
systemctl start bluetooth
