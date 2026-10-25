#!/bin/sh
# Proves every commit of the current branch standalone (guide 7.1 rule 2,
# 7.2 rule 4): oldest first, each commit builds what it changed. Tests run per
# task and at the merge gate, not here.
#
#   scripts/check_commits.sh                      source checks and builds for what each commit changed
#   scripts/check_commits.sh "<command>"          also run <command> from the repo root
#
# What a commit changed decides what is built:
#   /backend or /contract   the migrations apply (supabase db reset; skipped,
#                           with a note, when local Supabase is not running)
#   /ios or /contract       the Mock app and its tests compile
#   /android or /contract   the mock app and its tests compile
#
# Uses one temporary worktree, so build caches stay warm between commits.
# Gitignored per-developer files the builds need (Android local.properties,
# backend overrides) are copied in.

set -e
root=$(git rev-parse --show-toplevel)
base=$(git merge-base HEAD origin/main)
commits=$(git rev-list --reverse "$base..HEAD")
[ -n "$commits" ] || { echo "No commits on this branch beyond origin/main."; exit 0; }
extra=$1

work=$(mktemp -d)/worktree
derived=$(dirname "$work")/ios-derived
log=$(dirname "$work")/build.log
git worktree add --quiet --detach "$work" "$base"
trap 'git -C "$root" worktree remove --force "$work"' EXIT

local_files="android/local.properties android/local.override.properties ios/Config/Local.override.xcconfig"

supabase_running() {
    (cd "$work/backend" && supabase status >/dev/null 2>&1)
}

# Applying an older commit's migrations resets the shared local database, so
# finish by resetting it to the branch tip.
reset_database=false

for commit in $commits; do
    git -C "$work" checkout --quiet "$commit"
    for file in $local_files; do
        if [ -f "$root/$file" ]; then cp "$root/$file" "$work/$file"; fi
    done
    echo "== $(git -C "$work" log -1 --format='%h %s')"
    changed=$(git -C "$work" diff --name-only "$commit~1" "$commit")
    failed() {
        echo "Failed at $(git -C "$work" log -1 --format='%h %s'): $1"
        if [ -s "$log" ]; then echo "Last lines of the output:"; tail -n 30 "$log"; fi
        exit 1
    }
    : > "$log"

    if echo "$changed" | grep -q '^ios/'; then "$work/ios/scripts/check_sources.sh" || failed "iOS source checks"; fi
    if echo "$changed" | grep -q '^android/'; then "$work/android/scripts/check_sources.sh" || failed "Android source checks"; fi

    if echo "$changed" | grep -qE '^(backend|contract)/'; then
        if supabase_running; then
            (cd "$work/backend" && supabase db reset >"$log" 2>&1) || failed "migrations"
            echo "Migrations apply."
            reset_database=true
        else
            echo "Local Supabase is not running: skipped applying the migrations."
            skipped_migrations=true
        fi
    fi
    if echo "$changed" | grep -qE '^(ios|contract)/'; then
        (cd "$work/ios" && make -s project >/dev/null \
            && xcodebuild -scheme ParkHill-Mock -destination "id=$(scripts/simulator.sh)" \
                -derivedDataPath "$derived" build-for-testing >"$log" 2>&1) || failed "iOS build"
        echo "iOS builds."
    fi
    if echo "$changed" | grep -qE '^(android|contract)/'; then
        (cd "$work/android" && ./gradlew -q assembleMockDebug assembleMockDebugUnitTest assembleMockDebugAndroidTest >"$log" 2>&1) \
            || failed "Android build"
        echo "Android builds."
    fi
    if [ -n "$extra" ]; then (cd "$work" && sh -c "$extra") || failed "$extra"; fi
done
if [ "$reset_database" = true ]; then
    (cd "$root/backend" && supabase db reset >/dev/null 2>&1) && echo "Local database reset to the branch tip."
fi
if [ "${skipped_migrations:-false}" = true ]; then
    echo "Migrations were not checked: start local Supabase and run again to check them."
fi
echo "Every commit passed."
