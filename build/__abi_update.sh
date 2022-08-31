export ASUS_BUILD_PROJECT=AI2202

export ASUS_FTM=y
export ASUS_FTM_BUILD=1
export ASUS_FTM_BUILD=y

export ASUS_AI2202_AUDIO=y
export ASUS_FTM_AUDIO=y
export ASUS_AI2202_CAMERA=y
export ASUS_AI2202_DISPLAY=y

cd kernel_platform
./build/build_abi.sh --update
