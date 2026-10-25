#!/bin/sh
# Prints a smoke list's tests in the form a test runner takes, skipping
# comment lines (starting with #) and blank lines (guide 7.2 rule 4).
#
#   scripts/smoke_tests.sh xcodebuild <list>   -only-testing:<test> for each
#   scripts/smoke_tests.sh gradle <list>       one comma-separated class argument

set -e
[ $# -eq 2 ] || { echo "usage: scripts/smoke_tests.sh xcodebuild|gradle <list>" >&2; exit 2; }
tests=$(grep -v -e '^#' -e '^[[:space:]]*$' "$2" | sed 's/[[:space:]]*$//' || true)
[ -n "$tests" ] || { echo "smoke_tests: $2 lists no tests" >&2; exit 1; }
case "$1" in
    xcodebuild) echo "$tests" | sed 's/^/-only-testing:/' | tr '\n' ' ' ;;
    gradle) echo "$tests" | tr '\n' ',' | sed 's/,$//' ;;
    *) echo "smoke_tests: unknown runner $1" >&2; exit 2 ;;
esac
