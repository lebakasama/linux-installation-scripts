#!/bin/bash

# MAKE SURE THAT THIS IS CORRECT BEFORE RUNNING !!
DEFAULT_USER=franck
DEFAULT_PASSWORD=password    # Used for root and default user
ENCRYPTED_DEVICE=nvme1n1p3
ENCRYPTED_MAPPER_DEVICE=cryptroot

function log {
    printf "\n##### $1\n"
}
 
log "System time config"
sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
sudo hwclock --systohc

log "Locale config"
sudo sed -i '171s/#//' /etc/locale.gen
sudo locale-gen
sudo echo "LANG=en_US.UTF-8" > /etc/locale.conf

log "Basic network config"
sudo echo "arch" > /etc/hostname
sudo cp config_files/hosts /etc/hosts

#log "Set default root password and create user"
#sudo echo root:$DEFAULT_PASSWORD | chpasswd
#sudo useradd -m -U -G wheel -p $DEFAULT_PASSWORD $DEFAULT_USER

log "Install required packages for the commands below"
sudo pacman -S --noconfirm \
	base-devel \
	efibootmgr \
	cryptsetup \
    dosfstools \
	fwupd \
	git \
	grub-btrfs \
	grub \
	libsmbios \
	man \
	networkmanager \
    tlp \
	vim \
	vi \
	sudo

log "Install yay"
bash ./sub_yay.sh

log "Install grub"
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

log "Configure grub"
UUID="$(sudo blkid -o value /dev/$ENCRYPTED_DEVICE | head -n 1)"
LINENUM=6
TO_INSERT=" cryptdevice\\=UUID\\=$UUID:$ENCRYPTED_MAPPER_DEVICE root\\=\\/dev\\/mapper\\/$ENCRYPTED_MAPPER_DEVICE\\\""
sed "${LINENUM}q;d" /etc/default/grub | grep -qF "$UUID" || sudo sed -i "${LINENUM}s/\\\"$/$TO_INSERT/" /etc/default/grub

log "Set kernel parameters to enable suspend"
TO_INSERT=" acpi_rev_override=1 acpi_osi=Linux mem_sleep_default=deep"
LINENUM=6
sed "${LINENUM}q;d" /etc/default/grub | grep -qF "$TO_INSERT" || sudo sed -i "${LINENUM}s/\\\"$/$TO_INSERT\\\"/" /etc/default/grub

log "Regenerate grub settings"
sudo grub-mkconfig -o /boot/grub/grub.cfg

log "mkinitcpio config and regeneration"
TO_INSERT=" btrfs"
LINENUM=7
sed "${LINENUM}q;d" /etc/mkinitcpio.conf | grep -qF "$TO_INSERT" || sudo sed -i "${LINENUM}s/)/$TO_INSERT)/" /etc/mkinitcpio.conf
sudo sed -i '55s/block filesystem/block encrypt filesystem/' /etc/mkinitcpio.conf
sudo mkinitcpio -p linux

log "Start TLP (power saving)"
sudo systemctl enable tlp
sudo systemctl start tlp

log "Set thermal mode. smbios-thermal-ctl works only as root or sudo."
# Get current mode: smbios-thermal-ctl -g  
# Get available modes: smbios-thermal-ctl -i
sudo smbios-thermal-ctl --set-thermal-mode=Balanced

echo
echo "GRUB should be installed. Reboot and hope for the best"
