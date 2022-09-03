#!/bin/sh

ANDROID_BUILD_TOP=/home/android/zf9/build

rm -rf mods
mkdir -p mods
CURR=`pwd`


LLVM_STRIP=${ANDROID_BUILD_TOP}/asus_tool/prebuilts/clang/host/linux-x86/clang-r416183b1/bin/llvm-strip
MKBOOTFS=${ANDROID_BUILD_TOP}/kernel_platform/prebuilts/kernel-build-tools/linux-x86/bin/mkbootfs
MODULES_SRC=${ANDROID_BUILD_TOP}/out/msm-kernel-waipio/staging/lib/modules
FSTAB_SRC=${ANDROID_BUILD_TOP}/out/target/product/taro/obj/ETC/fstab.qcom_intermediates
cd $MODULES_SRC

find . -name \*.ko -exec cp {} $CURR/mods \;
cd $CURR

MODULES=`ls ramdisk/lib/modules/`

rm -rf ramdisk_mix
cp -R ramdisk ramdisk_mix
rm -rf ramdisk_mix/lib/modules/*.ko

for FILE in ${MODULES}; do
      echo "  ${FILE}"
      ${LLVM_STRIP} -o ramdisk_mix/lib/modules/${FILE} --strip-debug  mods/${FILE}
done

rm ramdisk_mix/first_stage_ramdisk/*
rm ramdisk_mix/avb/*

cp ${FSTAB_SRC}/fstab.qcom ramdisk_mix/first_stage_ramdisk/
cp ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/ETC/q-gsi.avbpubkey_intermediates/* ramdisk_mix/avb/
cp ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/ETC/r-gsi.avbpubkey_intermediates/* ramdisk_mix/avb/
cp ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/ETC/s-gsi.avbpubkey_intermediates/* ramdisk_mix/avb/


cp ${ANDROID_BUILD_TOP}/device/qcom/taro-kernel/dtbs/dtb.img dtb
cp ${ANDROID_BUILD_TOP}/device/qcom/taro-kernel/dtbs/dtbo.img dtbo.img

${MKBOOTFS} ramdisk_mix > ramdisk.cpio
#gzip -c -f ramdisk.cpio > ramdisk.gz

./magiskboot repack vendor_boot.img