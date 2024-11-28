#!/bin/bash

BUILD_DIR=yay_build

rm -rf $BUILD_DIR
git clone https://aur.archlinux.org/yay.git $BUILD_DIR
cd $BUILD_DIR
makepkg -si --noconfirm
cd ..
rm -rf $BUILD_DIR
