#!/bin/sh
# Fails if a release APK contains mock code or contract fixtures (guide 5.2
# rule 3). Usage: check_release_apk.sh <path to APK>
apk=${1:?usage: check_release_apk.sh <apk>}
[ -f "$apk" ] || { echo "No APK at $apk"; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unzip -q -o "$apk" 'classes*.dex' -d "$work" || { echo "No dex in $apk"; exit 1; }

classes=$(strings "$work"/classes*.dex | grep -oE 'Lapp/parkhill/[A-Za-z0-9_/$]*(Mock|/mocks/)[A-Za-z0-9_/$]*;' | sort -u)
fixtures=$(unzip -l "$apk" | grep -E 'assets/.*(get_entry|get_screen|sign_in)[^ ]*\.json')

if [ -n "$classes$fixtures" ]; then
    echo "Mock code or fixtures are in the release APK (guide 5.2 rule 3):"
    [ -n "$classes" ] && echo "$classes" | head -20
    [ -n "$fixtures" ] && echo "$fixtures" | head -20
    exit 1
fi
echo "Release APK: no mock code or fixtures."
