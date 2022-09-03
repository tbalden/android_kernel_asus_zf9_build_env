#!/bin/bash

if [[ -z "${1}" ]]; then
    echo "No device specified."
    exit
fi

export TARGET_BOARD_PLATFORM="${1}"
export TARGET_BUILD_VARIANT=user
export BUILD_VENDOR_DLKM=1
export ASUS_GKI_BUILD=y
export ASUS_BUILD_PROJECT=AI2202

export ANDROID_BUILD_TOP=$(pwd)
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${TARGET_BOARD_PLATFORM}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-kernel-${TARGET_BOARD_PLATFORM}

export ASUS_FTM=y
export ASUS_FTM_BUILD=1
export ASUS_FTM_BUILD=y


export ASUS_AI2202_AUDIO=y
export ASUS_FTM_AUDIO=y
export ASUS_AI2202_CAMERA=y
export ASUS_AI2202_DISPLAY=y

export EXT_MODULES="
  ../vendor/qcom/opensource/mmrm-driver
  ../vendor/qcom/opensource/audio-kernel
  ../vendor/qcom/opensource/camera-kernel
  ../vendor/qcom/opensource/dataipa/drivers/platform/msm
  ../vendor/qcom/opensource/datarmnet/core
  ../vendor/qcom/opensource/datarmnet-ext/aps
  ../vendor/qcom/opensource/datarmnet-ext/offload

  ../vendor/qcom/opensource/datarmnet-ext/perf_tether
  ../vendor/qcom/opensource/datarmnet-ext/sch
  ../vendor/qcom/opensource/datarmnet-ext/shs
  ../vendor/qcom/opensource/datarmnet-ext/wlan
    ../vendor/qcom/opensource/datarmnet-ext/perf
  ../vendor/qcom/opensource/display-drivers/msm
  ../vendor/qcom/opensource/eva-kernel
  ../vendor/qcom/opensource/cvp-kernel
  ../vendor/qcom/opensource/video-driver
  ../vendor/qcom/opensource/wlan/qcacld-3.0/.qca6490
"

export LTO=thin

RECOMPILE_KERNEL=1 ./kernel_platform/build/android/prepare_vendor_kernel_image.sh ${TARGET_BOARD_PLATFORM} gki
