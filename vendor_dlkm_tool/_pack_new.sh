cp /home/android/zf9/build/out/target/product/taro/vendor_dlkm.img vendor_dlkm.img

#exit 0
#/home/android/zf9/build/kernel_platform/prebuilts/kernel-build-tools/linux-x86/bin/simg2img vendor_dlkm.simg vendor_dlkm.img
#./pad_zeroes.sh

adb push httools /data/local/tmp
adb push fec /data/local/tmp
adb push vendor_dlkm.img /data/local/tmp
adb push vbmeta.img /data/local/tmp
adb shell 'cd /data/local/tmp && chmod +x httools && chmod +x fec && ./httools patch vendor_dlkm vendor_dlkm.img vbmeta.img'
adb pull /data/local/tmp/vendor_dlkm.img vendor_dlkm-patched.img
adb pull /data/local/tmp/vbmeta.img vbmeta-patched.img