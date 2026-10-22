#!/bin/sh
# Builds the APK for sharing: one file for all Android phones, signed with
# the release key from android/key.properties. Debug symbols stay in
# build/debug-info (needed to read crash stack traces of this build).
set -e
cd "$(dirname "$0")/.."
flutter build apk --release \
  --target-platform android-arm,android-arm64 \
  --obfuscate --split-debug-info=build/debug-info
version=$(grep '^version:' pubspec.yaml | sed 's/version: \([^+]*\).*/\1/')
cp build/app/outputs/flutter-apk/app-release.apk "build/FriendBase-$version.apk"
ls -lh "build/FriendBase-$version.apk"
