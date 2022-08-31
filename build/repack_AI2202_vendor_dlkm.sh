#!/bin/bash


if [ "$1" == "all" ]; then
	rm -rf kernel_platform/out/
	rm -rf device/qcom/waipio-kernel/
	rm -rf out/
	git checkout *.bp  *.mk
	rm -rf system/
fi


# copy_target <to> <from>
function copy_target() {
	if [ -f "$1" -o -d "$1" ];then
		folder=$2
		mkdir -p $folder
		cp -r $1 $2
	else
		echo "[asus] $1 doesn't exist!"
		exit
	fi
}



set -e

export ANDROID_BUILD_TOP=$PWD
export TARGET_BOARD_PLATFORM=taro
export TARGET_BUILD_VARIANT=user
export ASUS_BUILD_PROJECT=AI2202
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/taro

echo "[asus]ANDROID_BUILD_TOP=$ANDROID_BUILD_TOP; TARGET_BOARD_PLATFORM=$TARGET_BOARD_PLATFORM"

cd ${ANDROID_BUILD_TOP}



function build_vendor_dlkmimage(){
#	mkdir -p ${ANDROID_BUILD_TOP}/out/host/linux-x86/
#	mkdir -p ${ANDROID_BUILD_TOP}/system/extras/ext4_utils/
#	mkdir -p ${ANDROID_BUILD_TOP}/prebuilts/build-tools
#	mkdir -p ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/PACKAGING/vendor_dlkm_intermediates/
#        mkdir -p ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/ETC/
#	mkdir -p ${ANDROID_BUILD_TOP}/out/target/product/taro/system
#	cp -r ${ANDROID_BUILD_TOP}/asus_tool/out/host/linux-x86/.  ${ANDROID_BUILD_TOP}/out/host/linux-x86/
#	cp -r ${ANDROID_BUILD_TOP}/asus_tool/system/extras/ext4_utils/.  ${ANDROID_BUILD_TOP}/system/extras/ext4_utils/
#        cp -r ${ANDROID_BUILD_TOP}/asus_tool/prebuilts/build-tools/.  ${ANDROID_BUILD_TOP}/prebuilts/build-tools/
#	cp -r ${ANDROID_BUILD_TOP}/asus_tool/out/host/linux-x86/.  ${ANDROID_BUILD_TOP}/out/host/linux-x86/
	cp -r ${ANDROID_BUILD_TOP}/asus_tool/vendor_dlkm_image_info.txt ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/PACKAGING/vendor_dlkm_intermediates/vendor_dlkm_image_info.txt
#	cp -r ${ANDROID_BUILD_TOP}/asus_tool/out/target/product/taro/obj/ETC/. ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/ETC/
	PATH=${ANDROID_BUILD_TOP}/out/host/linux-x86/bin/:${ANDROID_BUILD_TOP}/system/extras/ext4_utils/:${ANDROID_BUILD_TOP}/prebuilts/build-tools/path/linux-x86:${ANDROID_BUILD_TOP}/out/.path ${ANDROID_BUILD_TOP}/out/host/linux-x86/bin/build_image ${ANDROID_BUILD_TOP}/out/target/product/taro/vendor_dlkm ${ANDROID_BUILD_TOP}/out/target/product/taro/obj/PACKAGING/vendor_dlkm_intermediates/vendor_dlkm_image_info.txt ${ANDROID_BUILD_TOP}/out/target/product/taro/vendor_dlkm.img ${ANDROID_BUILD_TOP}/out/target/product/taro/system
}
build_vendor_dlkmimage

echo "[asus] build vendor_dlkm.img success"







