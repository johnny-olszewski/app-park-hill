#!/bin/sh
# Fails if shared app sources branch on the build variant (guide 5.2 rule 2).
# Flavor source sets (src/mock, src/local) are where variants differ. Run by CI
# and the pre-push hook.
cd "$(dirname "$0")/.." || exit 1

found=$(grep -rnE 'BuildConfig\.(FLAVOR|DEBUG|BUILD_TYPE)' app/src/main)
if [ -n "$found" ]; then
    echo "Build-variant branching is not allowed in src/main (guide 5.2 rule 2):"
    echo "$found"
    exit 1
fi
echo "Sources: no build-variant branching."
