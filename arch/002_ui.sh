#!/bin/bash

bash ./sub_bluetooth.sh
bash ./sub_NetworkManager.sh
bash ./sub_sound.sh
bash ./sub_gnome.sh

echo
echo Installed minimal Gnome UI. Sound should work after rebooting.
