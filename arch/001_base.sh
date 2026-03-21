#!/bin/bash
set -e

# MAKE SURE THAT THIS IS CORRECT BEFORE RUNNING !!
DEFAULT_USER=franck
DEFAULT_PASSWORD=password    # Used for root and default user
ENCRYPTED_DEVICE=nvme1n1p3
ENCRYPTED_MAPPER_DEVICE=cryptroot
TARGET_DEVICE=no_device
PART_UEFI=1
PART_LUKS=2

abort() {
    echo "Aborted"
    exit 1
}

error_handler() {
    echo "Error occured at line $1"
    abort
}
trap 'error_handler $LINENO' ERR

sudo lsblk

echo
read -p "Device where to install arch: " TARGET_DEVICE

read -p "This script will destroy all data on $TARGET_DEVICE. Enter YES to confirm: " CONFIRM
[ "$CONFIRM" != "YES" ] && abort

echo Deleting all existing partitions on /dev/"$TARGET_DEVICE"
sgdisk -Z /dev/"$TARGET_DEVICE"

echo Creating and formatting UEFI parition
sgdisk -n "$PART_UEFI":0:+1G -t "$PART_UEFI":ef00 /dev/"$TARGET_DEVICE"
mkfs.fat -F32 /dev/"$TARGET_DEVICE$PART_UEFI"

echo Creating encrypted LUKS partition
read -s -p "Enter encryption passphrase for /dev/$TARGET_DEVICE$PART_LUKS: " LUKS_PASSPHRASE
echo
read -s -p "Enter encryption passphrase again: " LUKS_PASSPHRASE_CONFIRM
echo
[ "$LUKS_PASSPHRASE" != "$LUKS_PASSPHRASE_CONFIRM" ] && abort
unset LUKS_PASSPHRASE_CONFIRM

sgdisk -n "$PART_LUKS":0:0 -t "$PART_LUKS":8300 /dev/"$TARGET_DEVICE"
echo "$LUKS_PASSPHRASE" | cryptsetup --batch-mode -q luksFormat /dev/"$TARGET_DEVICE$PART_LUKS"

echo Format encrypted partition to ext4
echo "$LUKS_PASSPHRASE" | cryptsetup open /dev/"$TARGET_DEVICE$PART_LUKS" cryptroot
unset LUKS_PASSPHRASE
mkfs.ext4 /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mount /dev/$TARGET_DEVICE$PART_UEFI /mnt/boot

echo Installing kernel
pacstrap /mnt base linux linux-firmware

echo Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo chrooting to new system
arch-chroot /mnt

# System time config
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

exit 0

# Locale config
LINE_NUM=`grep -n "en_US.UTF-8" /etc/locale.gen | cut -d: -f1`
sed -i '"$LINE_NUM"s/.//' /etc/locale.gen
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

# Install yay
bash ./sub_yay.sh

# Install grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Configure grub
UUID="$(blkid -o value /dev/$ENCRYPTED_DEVICE | head -n 1)"
sed -i "6s/\\\"$/ cryptdevice\=UUID\=$UUID:$ENCRYPTED_MAPPER_DEVICE root\=\/dev\/mapper\/$ENCRYPTED_MAPPER_DEVICE\"/" /etc/default/grub

# Set kernel parameters to enable suspend
sed -i '6s/"$/ acpi_rev_override=1 acpi_osi=Linux mem_sleep_default=deep"/' /etc/default/grub

# Regenerate grub settings
grub-mkconfig -o /boot/grub/grub.cfg

# mkinitcpio config and regeneration
sed -i '7s/()/(btrfs)/' /etc/mkinitcpio.conf
sed -i '55s/block filesystem/block encrypt filesystem/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Start TLP (power saving)
systemctl enable tlp
systemctl start tlp

# Set thermal mode. smbios-thermal-ctl works only as root or sudo.
# Get current mode: smbios-thermal-ctl -g  
# Get available modes: smbios-thermal-ctl -i
smbios-thermal-ctl --set-thermal-mode=Balanced

echo
echo "GRUB should be installed. Reboot and hope for the best"
