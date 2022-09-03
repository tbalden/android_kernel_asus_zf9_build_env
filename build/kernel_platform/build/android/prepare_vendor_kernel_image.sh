#!/bin/bash

# Copyright (c) 2020-2021, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## prepare_vendor.sh prepares kernel/build's output for direct consumption in AOSP
# - Script assumes running after lunch w/Android build environment variables available
# - Select which kernel target+variant (defconfig) to use
#    - Default target based on TARGET_PRODUCT from lunch
#    - Default variant based on corresponding target's build.config
# - Remove all Android.mk and Android.bp files from source so they don't conflict with Android's
#   Kernel Platform has same clang/gcc prebuilt projects, which both have Android.mk/Android.bp that
#   would conflict
# - Compile in-vendor-tree devicetrees
# - Overlay those devicetrees onto the kernel platform's dtb/dtbos
#
# The root folder for kernel prebuilts in Android build system is following:
# KP_OUT = device/qcom/$(TARGET_PRODUCT)-kernel
# Default boot.img kernel Image: $(KP_OUT)/Image
# All Kernel Platform DLKMs: $(KP_OUT)/*.ko
# Processed Board UAPI Headers: $(KP_OUT)/kernel-headers
# First-stage DLKMs listed in $(KP_OUT)/modules.load
#   - If not present, all modules are for first-stage init
# Second-stage blocklist listed in $(KP_OUT)/modules.blocklist
#   - If not present, no modules should be blocked
# DTBs, DTBOs, dtb.img, and dtbo.img in $(KP_OUT)/merged-dtbs/
#
# The following optional arguments can be passed to prepare_vendor.sh:
#  prepare_vendor.sh [KERNEL_TARGET [KERNEL_VARIANT [OUT_DIR]]]
#   See below for descriptions of the arguments and default behavior when unspecified.
#   Note that in order for KERNEL_VARIANT to be defined, KERNEL_TARGET must also be
#   explicitly mentioned. Similarly, in order for OUT_DIR to be mentioned,
#   KERNEL_TARGET and KERNEL_VARIANT must also be mentioned.
#
# The following environment variables are considered during execution
#   ANDROID_KERNEL_OUT - The output location to copy artifacts to.
#                        If unset, then ANDROID_BUILD_TOP and TARGET_BOARD_PLATFORM
#                        (usually set by Android's "lunch" command)
#                        are used to figure it out
#   KERNEL_TARGET      - Kernel target to use. This variable can also be the first argument
#                        to prepare_vendor.sh [KERNEL_TARGET], or is copied from
#                        BOARD_TARGET_PRODUCT
#   KERNEL_VARIANT     - Kernel target variant to use. This variable can also be the second argument
#                        to prepare_vendor.sh [KERNEL_TARGET] [KERNEL_VARIANT]. If left unset,
#                        the default kernel variant is used for the kernel target.
#   OUT_DIR            - Kernel Platform output folder for the KERNEL_TARGET and KERNEL_VARIANT.
#                        This variable can also be the third argument to
#                        prepare_vendor.sh [KERNEL_TARGET] [KERNEL_VARIANT] [OUT_DIR].
#                        If left unset, conventional locations will be checked:
#                        $ANDROID_BUILD_TOP/out/$BRANCH and $KP_ROOT_DIR/out/$BRANCH
#   DIST_DIR           - Kernel Platform dist folder for the KERNEL_TARGET and KERNEL_VARIANT
#   RECOMPILE_KERNEL   - Recompile the kernel platform
#
# To compile out-of-tree kernel objects and set up the prebuilt UAPI headers,
# these environment variables must be set.
# ${ANDROID_BUILD_TOP}/vendor/**/*-devicetree/
#   ANDROID_BUILD_TOP   - The root source tree folder
#   ANDROID_PRODUCT_OUT - The root output folder. Output is placed in ${OUT}/obj/DLKM_OBJ
# Currently only DTBs are compiled from folders matching this pattern:

set -e

# rel_path <to> <from>
# Generate relative directory path to reach directory <to> from <from>
function rel_path() {
  python -c "import os.path; import sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$1" "$2"
}

ROOT_DIR=$(realpath $(dirname $(readlink -f $0))/../..) # build/android/prepare.sh -> .
echo "  kernel platform root: $ROOT_DIR"

################################################################################
# Discover where to put Android output
if [ -z "${ANDROID_KERNEL_OUT}" ]; then
  if [ -z "${ANDROID_BUILD_TOP}" ]; then
    echo "ANDROID_BUILD_TOP is not set. Have you run lunch yet?" 1>&2
    exit 1
  fi

  if [ -z "${TARGET_BOARD_PLATFORM}" ]; then
    echo "TARGET_BOARD_PLATFORM is not set. Have you run lunch yet?" 1>&2
    exit 1
  fi

  ANDROID_KERNEL_OUT=${ANDROID_BUILD_TOP}/device/qcom/${TARGET_BOARD_PLATFORM}-kernel
fi
if [ ! -e ${ANDROID_KERNEL_OUT} ]; then
  mkdir -p ${ANDROID_KERNEL_OUT}
fi

################################################################################
# Determine requested kernel target and variant

if [ -z "${KERNEL_TARGET}" ]; then
  KERNEL_TARGET=${1:-${TARGET_BOARD_PLATFORM}}
fi

if [ -z "${KERNEL_VARIANT}" ]; then
  KERNEL_VARIANT=${2}
fi

case "${KERNEL_TARGET}" in
  taro)
    KERNEL_TARGET="waipio"
    ;;
esac

################################################################################
# Create a build config used for this run of prepare_vendor
# Temporary KP output directory so as to not accidentally touch a prebuilt KP output folder
export TEMP_KP_OUT_DIR=$(mktemp -d ${ANDROID_PRODUCT_OUT:+-p ${ANDROID_PRODUCT_OUT}})
trap "rm -rf ${TEMP_KP_OUT_DIR}" exit
(
  cd ${ROOT_DIR}
  OUT_DIR=${TEMP_KP_OUT_DIR} ./build/brunch ${KERNEL_TARGET} ${KERNEL_VARIANT}
)

################################################################################
# Determine output folder
# ANDROID_KP_OUT_DIR is the output directory from Android Build System perspective
ANDROID_KP_OUT_DIR="${3:-${OUT_DIR}}"
if [ -z "${ANDROID_KP_OUT_DIR}" ]; then
  ANDROID_KP_OUT_DIR=out/$(
    cd ${ROOT_DIR}
    OUT_DIR=${TEMP_KP_OUT_DIR}
    source build/_wrapper_common.sh
    get_branch
  )

  if [ -n "${ANDROID_BUILD_TOP}" -a -e "${ANDROID_BUILD_TOP}/${ANDROID_KP_OUT_DIR}" ] ; then
    ANDROID_KP_OUT_DIR="${ANDROID_BUILD_TOP}/${ANDROID_KP_OUT_DIR}"
  else
    ANDROID_KP_OUT_DIR="${ROOT_DIR}/${ANDROID_KP_OUT_DIR}"
  fi
fi

# Clean up temporary KP output directory
rm -rf ${TEMP_KP_OUT_DIR}
trap - EXIT
echo "  kernel platform output: ${ANDROID_KP_OUT_DIR}"

################################################################################
# Set up recompile and copy variables
set -x
if [ ! -e "${ANDROID_KERNEL_OUT}/Image" ]; then
  COPY_NEEDED=1
fi

if [ ! -e "${ANDROID_KERNEL_OUT}/build.config" ] || \
  ! diff -q "${ANDROID_KERNEL_OUT}/build.config" "${ROOT_DIR}/build.config" ; then
  COPY_NEEDED=1
fi

if [ ! -e "${ANDROID_KP_OUT_DIR}/dist/Image" -a "${COPY_NEEDED}" == "1" ]; then
  RECOMPILE_KERNEL=1
fi
set +x

cp "${ROOT_DIR}/build.config" "${ANDROID_KERNEL_OUT}/build.config"

# If prepare_vendor.sh fails and nobody checked the error code, make sure the android build fails
# by removing the kernel Image which is needed to build boot.img
if [ "${RECOMPILE_KERNEL}" == "1" -o "${COPY_NEEDED}" == "1" ]; then
  rm -f ${ANDROID_KERNEL_OUT}/Image ${ANDROID_KERNEL_OUT}/vmlinux ${ANDROID_KERNEL_OUT}/System.map
fi

################################################################################
if [ "${RECOMPILE_KERNEL}" == "1" ]; then
  echo
  echo "  Recompiling kernel"

  (
    cd ${ROOT_DIR}
    SKIP_MRPROPER=1 OUT_DIR=${ANDROID_KP_OUT_DIR} ./build/build_kernel_image.sh
  )

  COPY_NEEDED=1
fi

exit 0
