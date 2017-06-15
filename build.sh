#!/bin/bash

if [[ ! $# -eq 1 ]] ; then
	echo 'You need to input arch.'
	echo 'Supported archs are:'
	echo -e '\tarm arm64 mips mips64 x86 x86_64'
	exit 1
fi

LOCAL_PATH=$(readlink -f .)
NDK_PATH=$(dirname "$(which ndk-build)")

if [ -z ${NDK_PATH} ] || [ ! -d ${NDK_PATH} ] || [ ${NDK_PATH} == . ]; then
	if [ ! -d android-ndk-r15 ]; then
		echo "downloading android ndk..."
		wget https://dl.google.com/android/repository/android-ndk-r15-linux-x86_64.zip
		unzip android-ndk-r15-linux-x86_64.zip
		rm -f android-ndk-r15-linux-x86_64.zip
	fi
	echo 'using integrated ndk'
	NDK_PATH=$(readlink -f android-ndk-r15)
fi

if [ ! -d ffmpeg.git ]; then
	#git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
	git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg.git --bare --depth=1 -b n3.3.2
fi

FFMPEG_BARE_PATH=$(readlink -f ffmpeg.git)
ANDROID_API=14
ARCH="$1"

ARCH_CONFIG_OPT=

case "${ARCH}" in
	'arm')
		ARCH_TRIPLET='arm-linux-androideabi'
		ABI='armeabi-v7a'
		ARCH_CFLAGS='-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb' ;;
	'arm64')
		ARCH_TRIPLET='aarch64-linux-android'
		ABI='arm64-v8a'
		ANDROID_API=21 ;;
        'mips')
		ARCH_TRIPLET='mipsel-linux-android'
		ABI='mips' ;;
        'mips64')
		ARCH_TRIPLET='mips64el-linux-android'
		ABI='mips64'
		ANDROID_API=21 ;;
        'x86')
		ARCH_TRIPLET='i686-linux-android'
		ARCH_CONFIG_OPT='--disable-asm'
		ABI='x86' ;;
        'x86_64')
		ARCH_TRIPLET='x86_64-linux-android'
		ABI='x86_64'
		ANDROID_API=21 ;;
	*)
		echo "Arch ${ARCH} is not supported."
		exit 1 ;;
esac


CROSS_DIR="$(mktemp -d)"
FFMPEG_DIR="$(mktemp -d)"
git clone "${FFMPEG_BARE_PATH}" "${FFMPEG_DIR}"

"${NDK_PATH}"/build/tools/make_standalone_toolchain.py \
            --arch "${ARCH}" --api ${ANDROID_API} \
            --stl libc++ --unified-headers \
            --install-dir "${CROSS_DIR}" --force

CONFIG_LIBAV= #to be customized if needed
FLAVOR='default'

pushd "${FFMPEG_DIR}"

git clean -fdx

CROSS_PREFIX="${CROSS_DIR}/bin/${ARCH_TRIPLET}-"

mkdir -p "${FFMPEG_DIR}/dist-${FLAVOR}-${ABI}"

./configure --cross-prefix="${CROSS_PREFIX}" \
            --cc="${CROSS_PREFIX}clang" \
            --as="${CROSS_PREFIX}gcc" \
            --sysroot="${CROSS_DIR}/sysroot" --sysinclude="${CROSS_DIR}/sysroot/usr/include" \
            --enable-cross-compile --target-os=android \
            --prefix="${FFMPEG_DIR}/dist-${FLAVOR}-${ABI}" \
            --arch="${ARCH}" ${ARCH_CONFIG_OPT} \
            --extra-cflags="${ARCH_CFLAGS} -fPIC -fPIE -DPIC -D__ANDROID_API__=${ANDROID_API}" \
            --extra-ldflags='-fPIE -pie' \
            --enable-shared --disable-static --disable-symver --disable-doc \
            ${CONFIG_LIBAV} > "${FFMPEG_DIR}/dist-${FLAVOR}-${ABI}/configure.log"

make -j16 install

popd

rm -Rf "${CROSS_DIR}"
cp -R "${FFMPEG_DIR}/dist-${FLAVOR}-${ABI}"  "${LOCAL_PATH}/"
rm -Rf "${FFMPEG_DIR}"

