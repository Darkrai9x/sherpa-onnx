# Build sherpa-onnx for Mobile (TTS-only)

Custom build configuration that strips all non-TTS code (ASR, denoiser, speaker ID, etc.) to reduce library size.

## Feature Flags

These CMake options control which components are compiled:

| Flag | Default | Our Value | Description |
|------|---------|-----------|-------------|
| `SHERPA_ONNX_ENABLE_TTS` | ON | ON | Text-to-Speech |
| `SHERPA_ONNX_ENABLE_ASR` | ON | OFF | Speech recognition |
| `SHERPA_ONNX_ENABLE_DENOISER` | ON | OFF | Speech denoiser |
| `SHERPA_ONNX_ENABLE_SOURCE_SEPARATION` | ON | OFF | Source separation |
| `SHERPA_ONNX_ENABLE_AUDIO_TAGGING` | ON | OFF | Audio tagging |
| `SHERPA_ONNX_ENABLE_SPEAKER_ID` | ON | OFF | Speaker embedding/ID |
| `SHERPA_ONNX_ENABLE_KWS` | ON | OFF | Keyword spotter |
| `SHERPA_ONNX_ENABLE_PUNCTUATION` | ON | OFF | Punctuation |
| `SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION` | ON | OFF | Speaker diarization |

## Disable Logging

Logging (`SHERPA_ONNX_LOGE`) is disabled by default in the Android build scripts (`SHERPA_ONNX_DISABLE_LOG=ON`).

To re-enable logging, edit the build script and change:
```bash
SHERPA_ONNX_DISABLE_LOG=ON
```
to:
```bash
SHERPA_ONNX_DISABLE_LOG=OFF
```

For custom cmake builds, add these flags to disable logging:
```
-DCMAKE_CXX_FLAGS="-DSHERPA_ONNX_DISABLE_LOG=1"
-DCMAKE_C_FLAGS="-DSHERPA_ONNX_DISABLE_LOG=1"
```

---

## Android

### Prerequisites

- Android NDK (tested with r27, path: `$ANDROID_NDK`)
- CMake + Ninja from Android SDK (or system cmake/ninja)

On Windows (Git Bash / MSYS), the scripts default to:
```
ANDROID_NDK=/c/Users/LongVu/AppData/Local/Android/Sdk/ndk/27.0.12077973
SHERPA_CMAKE=/c/Users/LongVu/AppData/Local/Android/Sdk/cmake/3.31.6/bin/cmake.exe
SHERPA_NINJA=/c/Users/LongVu/AppData/Local/Android/Sdk/cmake/3.31.6/bin/ninja.exe
```

Override via environment variables if your paths differ.

### Build arm64-v8a

```bash
bash build-android-arm64-v8a.sh
```

Output: `build-android-arm64-v8a-static/install/lib/libsherpa-onnx-jni.so` (~20MB)

### Build armeabi-v7a

```bash
bash build-android-armv7-eabi.sh
```

Output: `build-android-armv7-eabi-static/install/lib/libsherpa-onnx-jni.so` (~13MB)

### Configuration

Both scripts use:
- `BUILD_SHARED_LIBS=OFF` — static link, produces a single `libsherpa-onnx-jni.so`
- `SHERPA_ONNX_ENABLE_JNI=ON` — for Android Kotlin/Java
- `SHERPA_ONNX_ENABLE_C_API=OFF` — not needed for Android
- `SHERPA_ONNX_DISABLE_LOG=ON` — strip all log output for smaller size and cleaner logcat

### Use in Android Studio

1. Copy `libsherpa-onnx-jni.so` to your project:
   ```
   app/src/main/jniLibs/arm64-v8a/libsherpa-onnx-jni.so
   app/src/main/jniLibs/armeabi-v7a/libsherpa-onnx-jni.so
   ```
2. Copy Kotlin API files from `sherpa-onnx/kotlin-api/` to your project
3. Load the library in code:
   ```kotlin
   System.loadLibrary("sherpa-onnx-jni")
   ```

### Known Issue: espeak-ng rpath on Windows

When building on Windows (MSYS/Git Bash), the first build may fail at link time with undefined symbols (`ucd_toupper`, `ucd_tolower`, etc.).

**Cause**: MSYS bash expands `$ORIGIN` in espeak-ng's CMakeLists.txt to empty string, which corrupts the linker command.

**Fix**: After the first build downloads dependencies, patch the file:
```
build-android-arm64-v8a-static/_deps/espeak_ng-src/src/libespeak-ng/CMakeLists.txt
```

Comment out (around line 42):
```cmake
# target_link_libraries(espeak-ng PRIVATE "-Wl,-rpath,${ESPEAK_NG_RPATH_ORIGIN}")
```

Then re-run the build script. This patch is needed once per clean build directory.

---

## iOS

### Prerequisites

- macOS with Xcode and command-line tools
- `cmake` (system or Homebrew)

### Build

```bash
bash build-ios.sh
```

This builds 3 targets and creates an xcframework:
1. Simulator x86_64
2. Simulator arm64
3. Device arm64

Output: `build-ios/sherpa-onnx.xcframework`

### Configuration

- `BUILD_SHARED_LIBS=OFF` — static libraries
- `SHERPA_ONNX_ENABLE_C_API=ON` — iOS uses C API (not JNI)
- `SHERPA_ONNX_ENABLE_JNI=OFF`
- Deployment target: iOS 13.0

### Use in Xcode

1. Drag `sherpa-onnx.xcframework` into your Xcode project
2. Also add the onnxruntime xcframework from `build-ios/ios-onnxruntime/onnxruntime.xcframework`
3. Link both frameworks in your target's "Frameworks, Libraries, and Embedded Content"
4. Use the C API headers from the xcframework's `Headers` directory
