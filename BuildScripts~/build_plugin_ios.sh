#!/bin/bash -eu

export LIBWEBRTC_DOWNLOAD_URL=https://github.com/Unity-Technologies/com.unity.webrtc/releases/download/M116/webrtc-ios.zip
export SOLUTION_DIR=$(pwd)/Plugin~
export WEBRTC_FRAMEWORK_DIR=$(pwd)/Runtime/Plugins/iOS
export WEBRTC_ARCHIVE_DIR=build/webrtc.xcarchive
export WEBRTC_SIM_ARCHIVE_DIR=build/webrtc-sim.xcarchive

# Install cmake
export HOMEBREW_NO_AUTO_UPDATE=1
brew install cmake

# Download webrtc 
curl -L $LIBWEBRTC_DOWNLOAD_URL > webrtcUnity.zip
unzip -d $SOLUTION_DIR/webrtc webrtcUnity.zip 

# Build webrtc Unity plugin 
cd "$SOLUTION_DIR"
cmake . \
  -G Xcode \
  -D CMAKE_SYSTEM_NAME=iOS \
  -D "CMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -D CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
  -B build

xcodebuild \
  -sdk iphonesimulator \
  -arch 'x86_64' \
  -project build/webrtcUnity.xcodeproj \
  -target WebRTCLib \
  -configuration Release

xcodebuild archive \
  -sdk iphonesimulator \
  -arch 'x86_64' \
  -scheme WebRTCPlugin \
  -project build/webrtcUnity.xcodeproj \
  -configuration Release \
  -archivePath "$WEBRTC_SIM_ARCHIVE_DIR"

xcodebuild \
  -sdk iphoneos \
  -project build/webrtcUnity.xcodeproj \
  -target WebRTCLib \
  -configuration Release

xcodebuild archive \
  -sdk iphoneos \
  -scheme WebRTCPlugin \
  -project build/webrtcUnity.xcodeproj \
  -configuration Release \
  -archivePath "$WEBRTC_ARCHIVE_DIR"

rm -rf "$WEBRTC_FRAMEWORK_DIR/webrtcUnity.framework"
cp -r "$WEBRTC_ARCHIVE_DIR/Products/@rpath/webrtcUnity.framework" "$WEBRTC_FRAMEWORK_DIR/webrtcUnity.framework"

# todo(kazuki): The command below combines two libraries for supporting iOS and iOS simulator.
# But currently this is commented out because the combined binary adds a troublesome task to developer 
# when building iOS app on XCode. We need to support it using XCFramework or another way.
# 
# lipo -create -o "$WEBRTC_FRAMEWORK_DIR/webrtc.framework/webrtc" \
#   "$WEBRTC_ARCHIVE_DIR/Products/@rpath/webrtc.framework/webrtc" \
#   "$WEBRTC_SIM_ARCHIVE_DIR/Products/@rpath/webrtc.framework/webrtc"
