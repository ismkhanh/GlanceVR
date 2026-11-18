#!/bin/zsh
# With the Quest plugged into the Mac (developer mode on):
#   zsh cable.sh install     install builds/GlanceVR.apk (or APK=/path/to/GlanceVR.apk) and link it to the Mac
#   zsh cable.sh             just link it again over USB (after re-plugging the cable)
set -e
cd "${0:A:h}"
ADB=adb
command -v adb >/dev/null || ADB="$HOME/Library/Android/sdk/platform-tools/adb"
"$ADB" devices
if [[ "$1" == "install" ]]; then
  APK="${APK:-builds/GlanceVR.apk}"
  [[ -f "$APK" ]] || { echo "No APK at $APK: download GlanceVR.apk from Releases (APK=… zsh cable.sh install) or run zsh build.sh"; exit 1; }
  "$ADB" install -r "$APK"
fi
"$ADB" reverse tcp:47811 tcp:47811
echo "Linked over USB. Start the Mac app (cd mac && swift run -c release GlanceVR), then open Glance VR on the Quest."
