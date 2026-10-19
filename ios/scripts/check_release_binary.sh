#!/bin/sh
# Fails if a release app binary contains mock or dev tools code (guide 5.2
# rule 3). Usage: check_release_binary.sh <path to ParkHill.app>
app=${1:?usage: check_release_binary.sh <path to ParkHill.app>}
[ -f "$app/ParkHill" ] || { echo "No binary at $app/ParkHill"; exit 1; }

# The app's code: the executable, plus the debug dylib debug builds use.
found=$(for binary in "$app/ParkHill" "$app/ParkHill.debug.dylib"; do
        [ -f "$binary" ] && nm "$binary"
    done | swift demangle \
    | grep -iE 'Mock|DevTool|CurrentScreenTracker|SessionTracker|AppTools|HostWindowReader' \
    | grep -v 'NoDevTools')

if [ -n "$found" ]; then
    echo "Mock or dev tools code is in the release binary (guide 5.2 rule 3):"
    echo "$found" | head -20
    exit 1
fi
echo "Release binary: no mock or dev tools code."
