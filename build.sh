#!/bin/bash

NDK_PATH=/mnt/ssd/noury/mc/android-ndk
FFMPEG_PATH=/mnt/ssd2/noury/dev/ffmpeg

ANDROID_API=21

CROSS_DIR=$(mktemp -d)

$NDK_PATH/build/tools/make_standalone_toolchain.py --arch arm --api $ANDROID_API --stl libc++ --unified-headers --install-dir $CROSS_DIR --force

cd $FFMPEG_PATH

git clean -fdx

./configure --cross-prefix=$CROSS_DIR/bin/arm-linux-androideabi- --cc=$CROSS_DIR/bin/arm-linux-androideabi-clang --as=$CROSS_DIR/bin/arm-linux-androideabi-gcc --sysroot=$CROSS_DIR/sysroot --enable-cross-compile --target-os=android --arch=arm  --cpu=cortex-a9 --extra-cflags="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb -fPIC -fPIE -DPIC -D__ANDROID_API__=$ANDROID_API" --extra-ldflags='-fPIE -pie' --enable-shared
#--disable-symver

make -j16

rm -Rf $CROSS_DIR

