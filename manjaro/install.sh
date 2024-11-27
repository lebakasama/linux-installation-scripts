#!/bin/bash

PACMAN_INSTALL=sudo pacman -S --no-confirm
YAY_INSTALL=yay -S --no-confirm

# Install base packages and packages required for later stages
$PACMAN_INSTALL \
    base-devel \
    git \
    linux-headers-meta \
    vim

# Install yay
mkdir ~/tmp
cd ~/tmp
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si
cd
rm -rm tmp/yay-git

# DisplayLink hub drivers
$YAY_INSTALL evdi displaylink

# Power management
$PACMAN_INSTALL tlp thermald libsmbios
sudo systemctl start tlp
sudo systemctl enable tlp
sudo systemctl start thermald
sudo systemctl enable thermald
sudo smbios-thermal-ctl --set-thermal-mode=Balanced

# Set kernel parameters to enable suspend
sudo sed -i '6s/"$/ acpi_rev_override=1 acpi_osi=Linux mem_sleep_default=deep"/' /etc/default/grub

# Extra software
$YAY_INSTALL
    visual-studio-code-bin \
    input-remapper \
    rustup

# Regenerate grub settings
sudo grub-mkconfig -o /boot/grub/grub.cfg

