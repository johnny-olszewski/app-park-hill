#!/bin/sh
# Fails if app or test Swift sources branch on a build configuration (guide
# 5.2 rule 2). Platform and toolchain conditions (canImport, os, arch, swift,
# compiler, targetEnvironment) are allowed. Run by CI and the pre-push hook.
cd "$(dirname "$0")/.." || exit 1

found=$(grep -rnE '^[[:space:]]*#(if|elseif)[[:space:]]' --include='*.swift' ParkHill ParkHillTests ParkHillUITests \
    | grep -vE '#(if|elseif)[[:space:]]+!?(canImport|os|arch|swift|compiler|targetEnvironment)\(')

if [ -n "$found" ]; then
    echo "Build-configuration branching is not allowed (guide 5.2 rule 2):"
    echo "$found"
    exit 1
fi
echo "Sources: no build-configuration branching."
