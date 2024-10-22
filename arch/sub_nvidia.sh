#!/bin/bash

sudo pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime

# Add kernel parameter to activate KMS
sed -i '6s/"$/ nvidia_drm.modeset=1"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Nvidia modules early loading. Assumes we are using the standard linux kernel.
sed -i '7s/)$/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Setup power management
# https://download.nvidia.com/XFree86/Linux-x86_64/435.17/README/dynamicpowermanagement.html#AutomatedSetup803b0
sudo cp config_files/80-nvidia-pm.rules /etc/udev/rules.d/
sudo cp config_files/nvidia_module.conf /etc/modprobe.d/nvidia.conf

sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service
# sudo systemctl enable nvidia-powerd.service
sudo systemctl enable nvidia-persistenced.service

echo Hopefully the Nvidia drivers is installed. Time to reboot.
