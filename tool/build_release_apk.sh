#!/usr/bin/env bash
# Builds the smallest release APK(s) for DashKart.
#
#   tool/build_release_apk.sh           one APK per CPU type (3 files)
#   tool/build_release_apk.sh arm64     one APK, 64-bit ARM phones only
#
# What makes it small:
#   --split-per-abi   each APK carries one CPU's native libraries (the engine
#                     and the physics library), not all three.
#   --obfuscate +     shortens Dart symbol names and moves the debug symbols
#   --split-debug-info  out of the app. Keep build/symbols: it is what turns a
#                     crash report back into readable names.
#   R8 + resource shrinking are on for release in android/app/build.gradle.kts.
#
# Needs the Android SDK (ANDROID_HOME) with a platform and build-tools, and the
# licences accepted. See the "Release build" section of docs/README.md.
set -euo pipefail

cd "$(dirname "$0")/.."

# Use the Flutter version the project pins, when there is one.
FLUTTER=flutter
if [ -x .fvm/versions/3.47.6/bin/flutter ]; then
  FLUTTER=.fvm/versions/3.47.6/bin/flutter
fi

mode="${1:-split}"
args=(build apk --release --obfuscate --split-debug-info=build/symbols)
case "$mode" in
  split) args+=(--split-per-abi) ;;
  # Do NOT add -Pandroid.injected.build.abi (or any other `android.injected.*`
  # property) here to speed this up. The Android Gradle Plugin takes it as a
  # sign the build came from an IDE test run and marks the app
  # android:testOnly="true" — and Android then refuses to install the APK
  # ("App not installed as package appears to be invalid"). It only costs
  # extra build time and disk: the plugins' native code compiles for every CPU,
  # but --target-platform keeps only 64-bit ARM in the APK.
  arm64) args+=(--target-platform android-arm64) ;;
  *) echo "usage: $0 [split|arm64]" >&2; exit 2 ;;
esac

"$FLUTTER" "${args[@]}"

echo
echo "APKs:"
ls -lh build/app/outputs/flutter-apk/*.apk

# --- Refuse to hand over an APK the phone will not install ----------------
# A testOnly APK installs only through `adb install -t`; from a file manager
# or Google Drive the phone reports "package appears to be invalid".
apk=build/app/outputs/flutter-apk/app-release.apk
if [ "$mode" = "split" ]; then apk=$(ls build/app/outputs/flutter-apk/*-release.apk | head -1); fi

sdk=$(sed -n 's/^sdk.dir=//p' android/local.properties 2>/dev/null || true)
aapt2=$(ls -d "${sdk:-/nonexistent}"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)
if [ -n "$aapt2" ]; then
  if "$aapt2" dump xmltree --file AndroidManifest.xml "$apk" | grep -q "testOnly"; then
    echo "ERROR: $apk is marked testOnly and will not install on a phone." >&2
    echo "       Look for an android.injected.* property in this build." >&2
    exit 1
  fi
  echo "checked: not testOnly"
else
  echo "note: aapt2 not found, skipped the testOnly check"
fi
