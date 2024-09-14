#!/bin/bash

# This script assumes that the NetworkManager package has already been installed
# (through the base script)

SSID=FromageSuperSushi

systemctl enable NetworkManager
systemctl start NetworkManager

read -sp "Password for SSID $SSID: " password
nmcli device wifi connect $SSID password $password
