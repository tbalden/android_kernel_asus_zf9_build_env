#!/bin/sh

#gather_images.sh
CURR=`pwd`
cd vendor_boot_tool
./make_vendor_boot.sh
cp new-boot.img ${CURR}/full_img/vendor_boot.img
cp dtbo.img ${CURR}/full_img/dtbo.img

cd $CURR
cd vendor_dlkm_tool
./_pack_new.sh
cp vendor_dlkm.img ${CURR}/full_img/
cp vbmeta.img ${CURR}/full_img/
cp vbmeta-patched.img ${CURR}/full_img/

cd $CURR
cd boot_img_target

cd bootimg/vanilla
./build.sh
cp new-boot.img ${CURR}/full_img/boot.img
cd ../vanilla_m
./build.sh
cp new-boot.img ${CURR}/full_img/boot-magisk.img

cd $CURR