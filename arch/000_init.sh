#!/bin/bash

# This script is the first one to run. What it does:
# - delete all paritions
# - create new ones with luks2 encryption
# - set up encryption and BTRFS sub-volumes
# - install base system

# Device (drive) where Arch will be installed
DEVICE=/dev/nvme1n1
WIFI_SSID=FromageSuperSushi
SIZE_EFI_PARTITION=512MiB
SIZE_SWAP_PARTITION=16GiB

# Exit on error
set -e

function log {
    printf "\n### $1\n"
}

#log "Creating all paritions on $DEVICE..."
sgdisk --clear \
	--new=1:0:+${SIZE_EFI_PARTITION} --typecode=1:ef00 --change-name=1:EFI \
	--new=2:0:+${SIZE_SWAP_PARTITION} --typecode=2:8200 --change-name=2:cryptswap \
	--new=3:0:0 --typecode=3:8300 --change-name=3:cryptsystem \
	$DEVICE
fdisk -l $DEVICE

log "Encrypting main paritition..."
cryptsetup luksFormat --type luks2 --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem 

log "Mounting main partition..."
cryptsetup open /dev/disk/by-partlabel/cryptsystem system

log "Creating encrypted swap..."
cryptsetup open --type plain -c aes-xts-plain64 -s 256 --key-file /dev/urandom /dev/disk/by-partlabel/cryptswap swap
mkswap -L swap /dev/mapper/swap
swapon -L swap

log "Setting up BTRFS filesystem..."
mkfs.btrfs --label system /dev/mapper/system
mount -t btrfs LABEL=system /mnt

log "Creating BTRFS subvolumes..."
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots

log "Remounting BTRFS subvolumes with better options..."
umount -R /mnt
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root LABEL=system /mnt
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@home LABEL=system /mnt/home
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@var LABEL=system /mnt/var
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@snapshots LABEL=system /mnt/snapshots

log "Setting up EFI partition..."
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
mkdir /mnt/efi
mount LABEL=EFI /mnt/efi

log "Connecting to Wifi..."
iwctl station wlan0 connect $WIFI_SSID

log "Installing base software..."
pacstrap /mnt base linux linux-firmware

log "Creating filesystem table..."
genfstab -L -p /mnt >> /mnt/etc/fstab

log "Adding swap to boot. A new encryption key is generated at every boot so swap is not persistent. This has implications on hibernation."
echo "swap /dev/disk/by-partlabel/cryptswap /dev/urandom swap,offset=2048,cipher=aes-xts-plain64,size=256" >> /mnt/etc/crypttab

log "All done !"
