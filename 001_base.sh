#!/bin/bash

# MAKE SURE THAT THIS IS CORRECT BEFORE RUNNING !!
DEFAULT_USER=franck
DEFAULT_PASSWORD=password    # Used for root and default user
ENCRYPTED_DEVICE=nvme1n1p3
ENCRYPTED_MAPPER_DEVICE=cryptroot
 
# System time config
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

# Locale config
sed -i '171s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Basic network config
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost"  >> /etc/hosts
echo "::1       localhost"  >> /etc/hosts
echo "127.0.1.1 arch.localdomain.arch" >> /etc/hosts

# Set default root password and create user
echo root:$DEFAULT_PASSWORD | chpasswd
useradd -m -U -G wheel -p $DEFAULT_PASSWORD $DEFAULT_USER

# Install required packages for the commands below
pacman -S --noconfirm \
	base-devel \
	efibootmgr \
	cryptsetup \
    dosfstools \
	git \
	grub-btrfs \
	grub \
	man \
	networkmanager \
    tlp \
	vim \
	vi \
	sudo

# Install yay
bash ./sub_yay.sh

# Install grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Configure grub
UUID="$(blkid -o value /dev/$ENCRYPTED_DEVICE | head -n 1)"
sed -i "6s/\\\"$/ cryptdevice\=UUID\=$UUID:$ENCRYPTED_MAPPER_DEVICE root\=\/dev\/mapper\/$ENCRYPTED_MAPPER_DEVICE\"/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# mkinitcpio config and regeneration
sed -i '7s/()/(btrfs)/' /etc/mkinitcpio.conf
sed -i '55s/block filesystem/block encrypt filesystem/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Start TLP (power saving)
systemctl enable tlp
systemctl start tlp

echo
echo "GRUB should be installed. Reboot and hope for the best"
