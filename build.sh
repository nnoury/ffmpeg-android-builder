#!/bin/bash

NDK_PATH=/mnt/ssd/noury/mc/android-ndk
FFMPEG_PATH=/mnt/ssd2/noury/dev/ffmpeg

ANDROID_API=21

CROSS_DIR=$(mktemp -d)

${NDK_PATH}/build/tools/make_standalone_toolchain.py \
            --arch arm --api ${ANDROID_API} \
            --stl libc++ --unified-headers \
            --install-dir ${CROSS_DIR} --force

cd ${FFMPEG_PATH}

git clean -fdx


ARCH_CFLAGS='-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb'
ARCH='arm'
ARCH_TRIPLET=${ARCH}'-linux-androideabi'
CROSS_PREFIX=${CROSS_DIR}/bin/${ARCH_TRIPLET}-

./configure --cross-prefix=${CROSS_PREFIX} \
            --cc=${CROSS_PREFIX}clang \
            --as=${CROSS_PREFIX}gcc \
            --sysroot=${CROSS_DIR}/sysroot --enable-cross-compile --target-os=android \
            --arch=${ARCH} --cpu=cortex-a9 \
            --extra-cflags="${ARCH_CFLAGS} -fPIC -fPIE -DPIC -D__ANDROID_API__=${ANDROID_API}" \
            --extra-ldflags='-fPIE -pie' --enable-shared --disable-symver

make -j16

rm -Rf ${CROSS_DIR}

