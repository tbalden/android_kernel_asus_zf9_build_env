#!/bin/sh
echo "reboot bootloader"
adb reboot-bootloader
echo "flash vbmeta-patched"
fastboot flash vbmeta full_img/vbmeta-patched.img
echo "flash boot"
fastboot flash boot full_img/boot.img
echo "flash vendor_boot"
fastboot flash vendor_boot full_img/vendor_boot.img
echo "flash dtbo"
fastboot flash dtbo full_img/dtbo.img
echo "reboot fastbootd"
fastboot reboot fastboot
echo "flash vendor_dlkm"
fastboot flash vendor_dlkm full_img/vendor_dlkm.img
echo "press key to reboot"
read
fastboot reboot


