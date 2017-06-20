### FFmpeg-Android-builder

A simple shell script to cross-compile FFmpeg project for Android targets.

Builds the binaries and libs using dynamic linking.

Typical usage:
```
bash ./build.sh -a $ARCH
```

$ARCH can be either: arm arm64 x86 x86_64

mips and mips64 are untested

Requirements:
- NDK r15
- some dev tools
- free disk space in your tempfolder
