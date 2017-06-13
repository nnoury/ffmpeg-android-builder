#!/bin/bash

if [[ ! $# -eq 1 ]] ; then
	echo 'You need to input arch.'
	echo 'Supported archs are:'
	echo -e '\tarm arm64 mips mips64 x86 x86_64'
	exit 1
fi

LOCAL_PATH=$(readlink -f .)
NDK_PATH=$(dirname "$(which ndk-build)")

if [ ! -d ffmpeg ]; then
	#git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
	git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg
fi

FFMPEG_PATH=$(readlink -f ffmpeg)
ANDROID_API=14
ARCH="$1"

case "${ARCH}" in
	'arm')
		ARCH_TRIPLET='arm-linux-androideabi'
		ARCH_CFLAGS='-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb' ;;
	'arm64')
		ARCH_TRIPLET='aarch64-linux-android'
		ANDROID_API=21 ;;
        'mips')
		ARCH_TRIPLET='mipsel-linux-android';;
        'mips64')
		ARCH_TRIPLET='mips64el-linux-android'
		ANDROID_API=21 ;;
        'x86')
		ARCH_TRIPLET='i686-linux-android';;
        'x86_64')
		ARCH_TRIPLET='x86_64-linux-android'
		ANDROID_API=21 ;;
	*)
		echo "Arch ${ARCH} is not supported."
		exit 1 ;;
esac


CROSS_DIR="$(mktemp -d)"

"${NDK_PATH}"/build/tools/make_standalone_toolchain.py \
            --arch "${ARCH}" --api ${ANDROID_API} \
            --stl libc++ --unified-headers \
            --install-dir "${CROSS_DIR}" --force

CONFIG_LIBAV= #to be customized if needed
FLAVOR='default'

pushd "${FFMPEG_PATH}"

git clean -fdx

CROSS_PREFIX="${CROSS_DIR}/bin/${ARCH_TRIPLET}-"

./configure --cross-prefix="${CROSS_PREFIX}" \
            --cc="${CROSS_PREFIX}clang" \
            --as="${CROSS_PREFIX}gcc" \
            --sysroot="${CROSS_DIR}/sysroot" --sysinclude="${CROSS_DIR}/sysroot/usr/include" \
            --enable-cross-compile --target-os=android \
            --prefix="${LOCAL_PATH}/android-${FLAVOR}-${ARCH_TRIPLET}" \
            --arch="${ARCH}" \
            --extra-cflags="${ARCH_CFLAGS} -fPIC -fPIE -DPIC -D__ANDROID_API__=${ANDROID_API}" \
            --extra-ldflags='-fPIE -pie' \
            --enable-shared --disable-static --disable-symver --disable-doc \
            ${CONFIG_LIBAV}

make -j16 install

popd

rm -Rf "${CROSS_DIR}"

