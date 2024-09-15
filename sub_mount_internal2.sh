#!/bin/bash

INTERNAL2_DEV=/dev/nvme0n1p1
INTERNAL2_MAP=internal2
INTERNAL2_KEY=/home/franck/.config/internal2_luksKey

echo "\n/dev/mapper/$INTERNAL2_MAP\t/mnt/$INTERNAL2_MAP\text4\tdefaults\t0\t0" >> /etc/fstab
echo "\n$INTERNAL2_MAP\t$INTERNAL2_DEV\t$INTERNAL2_KEY" >> /etc/crypttab
