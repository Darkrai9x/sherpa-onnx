#!/usr/bin/env bash
set -ex

# If BUILD_SHARED_LIBS is ON, we use libonnxruntime.so
# If BUILD_SHARED_LIBS is OFF, we use libonnxruntime.a
#
# In any case, we will have libsherpa-onnx-jni.so
#
# If BUILD_SHARED_LIBS is OFF, then libonnxruntime.a is linked into libsherpa-onnx-jni.so
# and you only need to copy libsherpa-onnx-jni.so to your Android projects.
#
# If BUILD_SHARED_LIBS is ON, then you need to copy both libsherpa-onnx-jni.so
# and libonnxruntime.so to your Android projects
#
BUILD_SHARED_LIBS=OFF
SHERPA_ONNX_ENABLE_TTS=ON
SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION=OFF
SHERPA_ONNX_ENABLE_BINARY=OFF
SHERPA_ONNX_ENABLE_JNI=ON
SHERPA_ONNX_ENABLE_C_API=OFF
SHERPA_ONNX_ENABLE_ASR=OFF
SHERPA_ONNX_ENABLE_DENOISER=OFF
SHERPA_ONNX_ENABLE_SOURCE_SEPARATION=OFF
SHERPA_ONNX_ENABLE_AUDIO_TAGGING=OFF
SHERPA_ONNX_ENABLE_SPEAKER_ID=OFF
SHERPA_ONNX_ENABLE_KWS=OFF
SHERPA_ONNX_ENABLE_PUNCTUATION=OFF
SHERPA_ONNX_DISABLE_LOG=ON

SHERPA_ONNX_DISABLE_LOG_FLAGS=""
if [ "$SHERPA_ONNX_DISABLE_LOG" == ON ]; then
  SHERPA_ONNX_DISABLE_LOG_FLAGS="-DCMAKE_CXX_FLAGS=-DSHERPA_ONNX_DISABLE_LOG=1 -DCMAKE_C_FLAGS=-DSHERPA_ONNX_DISABLE_LOG=1"
fi

if [ $BUILD_SHARED_LIBS == ON ]; then
  dir=$PWD/build-android-armv7-eabi
else
  dir=$PWD/build-android-armv7-eabi-static
fi

if [ -n "${SHERPA_ONNXRUNTIME_LIB_DIR:-}" ] && [ -n "${SHERPA_ONNXRUNTIME_INCLUDE_DIR:-}" ]; then
  if [ ! -d "$SHERPA_ONNXRUNTIME_LIB_DIR" ]; then
    echo "Error: SHERPA_ONNXRUNTIME_LIB_DIR does not exist: $SHERPA_ONNXRUNTIME_LIB_DIR"
    exit 1
  fi
  if [ ! -d "$SHERPA_ONNXRUNTIME_INCLUDE_DIR" ]; then
    echo "Error: SHERPA_ONNXRUNTIME_INCLUDE_DIR does not exist: $SHERPA_ONNXRUNTIME_INCLUDE_DIR"
    exit 1
  fi
  SHERPA_ONNXRUNTIME_LIB_DIR=$(cd "$SHERPA_ONNXRUNTIME_LIB_DIR" && pwd)
  SHERPA_ONNXRUNTIME_INCLUDE_DIR=$(cd "$SHERPA_ONNXRUNTIME_INCLUDE_DIR" && pwd)
  export SHERPA_ONNXRUNTIME_LIB_DIR
  export SHERPA_ONNXRUNTIME_INCLUDE_DIR
elif [ -n "${SHERPA_ONNX_ONNXRUNTIME_ROOT:-}" ] && [ "$BUILD_SHARED_LIBS" == ON ]; then
  if [ ! -d "$SHERPA_ONNX_ONNXRUNTIME_ROOT" ]; then
    echo "Error: SHERPA_ONNX_ONNXRUNTIME_ROOT does not exist: $SHERPA_ONNX_ONNXRUNTIME_ROOT"
    exit 1
  fi
  SHERPA_ONNX_ONNXRUNTIME_ROOT=$(cd "$SHERPA_ONNX_ONNXRUNTIME_ROOT" && pwd)
  export SHERPA_ONNX_ONNXRUNTIME_ROOT
fi

mkdir -p $dir
cd $dir

# Note from https://github.com/Tencent/ncnn/wiki/how-to-build#build-for-android
# (optional) remove the hardcoded debug flag in Android NDK android-ndk
# issue: https://github.com/android/ndk/issues/243
#
# open $ANDROID_NDK/build/cmake/android.toolchain.cmake for ndk < r23
# or $ANDROID_NDK/build/cmake/android-legacy.toolchain.cmake for ndk >= r23
#
# delete "-g" line
#
# list(APPEND ANDROID_COMPILER_FLAGS
#   -g
#   -DANDROID

if [ -z $ANDROID_NDK ]; then
  ANDROID_NDK=/c/Users/LongVu/AppData/Local/Android/Sdk/ndk/27.0.12077973
fi

if [ -z $SHERPA_CMAKE ]; then
  SHERPA_CMAKE=/c/Users/LongVu/AppData/Local/Android/Sdk/cmake/3.31.6/bin/cmake.exe
fi
if [ -z $SHERPA_NINJA ]; then
  SHERPA_NINJA=/c/Users/LongVu/AppData/Local/Android/Sdk/cmake/3.31.6/bin/ninja.exe
fi

if [ ! -d $ANDROID_NDK ]; then
  echo Please set the environment variable ANDROID_NDK before you run this script
  exit 1
fi

echo "ANDROID_NDK: $ANDROID_NDK"
sleep 1

onnxruntime_version=${SHERPA_ONNX_ONNXRUNTIME_VERSION:-1.24.3}

if [ -n "${SHERPA_ONNXRUNTIME_LIB_DIR:-}" ] && [ -n "${SHERPA_ONNXRUNTIME_INCLUDE_DIR:-}" ]; then
  echo "Using externally provided ONNX Runtime"
elif [ -n "${SHERPA_ONNX_ONNXRUNTIME_ROOT:-}" ] && [ "$BUILD_SHARED_LIBS" == ON ]; then
  export SHERPA_ONNXRUNTIME_LIB_DIR="$SHERPA_ONNX_ONNXRUNTIME_ROOT/jni/armeabi-v7a/"
  export SHERPA_ONNXRUNTIME_INCLUDE_DIR="$SHERPA_ONNX_ONNXRUNTIME_ROOT/headers/"
elif [ "$BUILD_SHARED_LIBS" == ON ]; then
  if [ ! -f $onnxruntime_version/jni/armeabi-v7a/libonnxruntime.so ]; then
    mkdir -p $onnxruntime_version
    pushd $onnxruntime_version
    curl -L -o onnxruntime-android-${onnxruntime_version}.zip https://github.com/csukuangfj/onnxruntime-libs/releases/download/v${onnxruntime_version}/onnxruntime-android-${onnxruntime_version}.zip
    unzip onnxruntime-android-${onnxruntime_version}.zip
    rm onnxruntime-android-${onnxruntime_version}.zip
    popd
  fi

  export SHERPA_ONNXRUNTIME_LIB_DIR=$dir/$onnxruntime_version/jni/armeabi-v7a/
  export SHERPA_ONNXRUNTIME_INCLUDE_DIR=$dir/$onnxruntime_version/headers/
else
  if [ ! -f ${onnxruntime_version}-static/lib/libonnxruntime.a ]; then
    curl -L -o onnxruntime-android-armeabi-v7a-static_lib-${onnxruntime_version}.zip https://github.com/csukuangfj/onnxruntime-libs/releases/download/v${onnxruntime_version}/onnxruntime-android-armeabi-v7a-static_lib-${onnxruntime_version}.zip
    unzip onnxruntime-android-armeabi-v7a-static_lib-${onnxruntime_version}.zip
    rm onnxruntime-android-armeabi-v7a-static_lib-${onnxruntime_version}.zip
    mv onnxruntime-android-armeabi-v7a-static_lib-${onnxruntime_version} ${onnxruntime_version}-static
  fi

  export SHERPA_ONNXRUNTIME_LIB_DIR=$dir/$onnxruntime_version-static/lib/
  export SHERPA_ONNXRUNTIME_INCLUDE_DIR=$dir/$onnxruntime_version-static/include/
fi

echo "SHERPA_ONNXRUNTIME_LIB_DIR: $SHERPA_ONNXRUNTIME_LIB_DIR"
echo "SHERPA_ONNXRUNTIME_INCLUDE_DIR $SHERPA_ONNXRUNTIME_INCLUDE_DIR"

if [ -z $SHERPA_ONNX_ENABLE_RKNN ]; then
  SHERPA_ONNX_ENABLE_RKNN=OFF
fi

if [ $SHERPA_ONNX_ENABLE_RKNN == ON ]; then
  rknn_version=2.2.0
  if [ ! -d ./librknnrt-android ]; then
    rm -fv librknnrt-android.tar.bz2
    wget https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/librknnrt-android.tar.bz2
    tar xvf librknnrt-android.tar.bz2
    rm librknnrt-android.tar.bz2
  fi

  export SHERPA_ONNX_RKNN_TOOLKIT2_LIB_DIR=$PWD/librknnrt-android/v$rknn_version/armeabi-v7a/
  export CPLUS_INCLUDE_PATH=$PWD/librknnrt-android/v$rknn_version/include:$CPLUS_INCLUDE_PATH
fi

"$SHERPA_CMAKE" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$SHERPA_NINJA" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -DSHERPA_ONNX_ENABLE_TTS=$SHERPA_ONNX_ENABLE_TTS \
    -DSHERPA_ONNX_ENABLE_ASR=$SHERPA_ONNX_ENABLE_ASR \
    -DSHERPA_ONNX_ENABLE_DENOISER=$SHERPA_ONNX_ENABLE_DENOISER \
    -DSHERPA_ONNX_ENABLE_SOURCE_SEPARATION=$SHERPA_ONNX_ENABLE_SOURCE_SEPARATION \
    -DSHERPA_ONNX_ENABLE_AUDIO_TAGGING=$SHERPA_ONNX_ENABLE_AUDIO_TAGGING \
    -DSHERPA_ONNX_ENABLE_SPEAKER_ID=$SHERPA_ONNX_ENABLE_SPEAKER_ID \
    -DSHERPA_ONNX_ENABLE_KWS=$SHERPA_ONNX_ENABLE_KWS \
    -DSHERPA_ONNX_ENABLE_PUNCTUATION=$SHERPA_ONNX_ENABLE_PUNCTUATION \
    -DSHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION=$SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION \
    -DSHERPA_ONNX_ENABLE_BINARY=$SHERPA_ONNX_ENABLE_BINARY \
    -DBUILD_PIPER_PHONMIZE_EXE=OFF \
    -DBUILD_PIPER_PHONMIZE_TESTS=OFF \
    -DBUILD_ESPEAK_NG_EXE=OFF \
    -DBUILD_ESPEAK_NG_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
    -DSHERPA_ONNX_ENABLE_PYTHON=OFF \
    -DSHERPA_ONNX_ENABLE_TESTS=OFF \
    -DSHERPA_ONNX_ENABLE_CHECK=OFF \
    -DSHERPA_ONNX_ENABLE_PORTAUDIO=OFF \
    -DSHERPA_ONNX_ENABLE_JNI=$SHERPA_ONNX_ENABLE_JNI \
    -DSHERPA_ONNX_LINK_LIBSTDCPP_STATICALLY=OFF \
    -DSHERPA_ONNX_ENABLE_C_API=$SHERPA_ONNX_ENABLE_C_API \
    -DCMAKE_INSTALL_PREFIX=./install \
    -DSHERPA_ONNX_ENABLE_RKNN=$SHERPA_ONNX_ENABLE_RKNN \
    -DANDROID_ABI="armeabi-v7a" -DANDROID_ARM_NEON=ON \
    -DANDROID_PLATFORM=android-21 \
    $SHERPA_ONNX_DISABLE_LOG_FLAGS \
    ..

    # By default, it links to libc++_static.a
    # -DANDROID_STL=c++_shared \

"$SHERPA_CMAKE" --build . -j4
"$SHERPA_CMAKE" --install . --strip
if [ "$BUILD_SHARED_LIBS" == ON ]; then
  cp -fv "$SHERPA_ONNXRUNTIME_LIB_DIR/libonnxruntime.so" install/lib
fi

if [ $SHERPA_ONNX_ENABLE_RKNN == ON ]; then
  cp -fv $SHERPA_ONNX_RKNN_TOOLKIT2_LIB_DIR/librknnrt.so install/lib
fi

rm -rf install/share
rm -rf install/lib/pkgconfig
rm -rf install/lib/lib*.a

if [ -f install/lib/libsherpa-onnx-c-api.so ]; then
  cat >install/lib/README.md <<EOF
# Introduction

Note that if you use Android Studio, then you only need to
copy libonnxruntime.so and libsherpa-onnx-jni.so
to your jniLibs, and you don't need libsherpa-onnx-c-api.so or
libsherpa-onnx-cxx-api.so.

libsherpa-onnx-c-api.so and libsherpa-onnx-cxx-api.so are for users
who don't use JNI. In that case, libsherpa-onnx-jni.so is not needed.

In any case, libonnxruntime.so is always needed.
EOF
  ls -lh install/lib/README.md
fi
