#!/bin/sh
# Fails if a build log shows any file under ParkHill/Mocks/ or
# ParkHill/DevTools/ being compiled into the app (guide 5.2 rule 3). Proves
# absence even where the optimizer would leave no symbol behind. The log must
# come from a clean build. Usage: check_release_build_log.sh <xcodebuild log>
log=${1:?usage: check_release_build_log.sh <xcodebuild log>}

if ! grep -qE "^SwiftCompile .*\(in target 'ParkHill' " "$log"; then
    echo "No app compile lines in $log; build from clean derived data."
    exit 1
fi

found=$(grep -E "^SwiftCompile [a-z]+ [a-z0-9_]+ [^ ]*/ParkHill/(Mocks|DevTools)/[^ ]+\.swift \(in target 'ParkHill' " "$log")
if [ -n "$found" ]; then
    echo "Mock or dev tools sources were compiled into the release build (guide 5.2 rule 3):"
    echo "$found" | head -20
    exit 1
fi
echo "Release build log: no mock or dev tools sources compiled."
