#!/bin/bash

# Build native libraries for synclib Flutter plugin
# This script runs the cross-platform build and copies libraries to the Flutter plugin

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
SYNCLIBC_DIR="$(dirname "$PLUGIN_DIR")/synclibc"

echo "Building native libraries..."
echo "Plugin directory: $PLUGIN_DIR"
echo "Synclibc directory: $SYNCLIBC_DIR"

# Check if synclibc directory exists
if [ ! -d "$SYNCLIBC_DIR" ]; then
    echo "Error: synclibc directory not found at $SYNCLIBC_DIR"
    exit 1
fi

# Build native libraries
cd "$SYNCLIBC_DIR"
./build-cross-platform.sh

echo ""
echo "Copying libraries to Flutter plugin..."

# Copy iOS libraries (device and simulator)
mkdir -p "$PLUGIN_DIR/ios/Libraries"
cp "$SYNCLIBC_DIR/build/ios/libsynclib_device.a" "$PLUGIN_DIR/ios/Libraries/"
cp "$SYNCLIBC_DIR/build/ios/libsynclib_simulator.a" "$PLUGIN_DIR/ios/Libraries/"
echo "✓ Copied iOS libraries (device + simulator)"

# Copy Android libraries
ANDROID_ARCHS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
for ARCH in "${ANDROID_ARCHS[@]}"; do
    mkdir -p "$PLUGIN_DIR/android/src/main/jniLibs/$ARCH"
    cp "$SYNCLIBC_DIR/build/android/$ARCH/libsynclib.a" "$PLUGIN_DIR/android/src/main/jniLibs/$ARCH/"
    echo "✓ Copied Android $ARCH library"
done

# Copy WebAssembly (to lib/src/web for Flutter web assets)
mkdir -p "$PLUGIN_DIR/lib/src/web"
cp "$SYNCLIBC_DIR/build/wasm/synclib.js" "$PLUGIN_DIR/lib/src/web/"
cp "$SYNCLIBC_DIR/build/wasm/synclib.wasm" "$PLUGIN_DIR/lib/src/web/"
echo "✓ Copied WebAssembly module"

# Copy header for reference
cp "$SYNCLIBC_DIR/synclib.h" "$PLUGIN_DIR/"
echo "✓ Copied header file"

echo ""
echo "Native libraries built and copied successfully!"
