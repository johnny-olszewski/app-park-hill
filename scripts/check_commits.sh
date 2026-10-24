#!/bin/sh
# Runs a check on every commit of the current branch, oldest first, so each
# commit is proven standalone (guide 7.1 rule 2) before pushing.
#
#   scripts/check_commits.sh                      fast source checks only
#   scripts/check_commits.sh "<command>"          also run <command> from the repo root
#
# Example: scripts/check_commits.sh "cd android && ./gradlew -q testMockDebugUnitTest"
#
# Uses one temporary worktree, so build caches stay warm between commits.
# Gitignored per-developer files the builds need (Android local.properties,
# backend overrides) are copied in; the iOS project is regenerated per commit
# when the command builds iOS (run `make project` in the command).

set -e
root=$(git rev-parse --show-toplevel)
base=$(git merge-base HEAD origin/main)
commits=$(git rev-list --reverse "$base..HEAD")
[ -n "$commits" ] || { echo "No commits on this branch beyond origin/main."; exit 0; }
extra=$1

work=$(mktemp -d)/worktree
git worktree add --quiet --detach "$work" "$base"
trap 'git -C "$root" worktree remove --force "$work"' EXIT

local_files="android/local.properties android/dev.local.properties ios/Config/Local.override.xcconfig"

for commit in $commits; do
    git -C "$work" checkout --quiet "$commit"
    for file in $local_files; do
        if [ -f "$root/$file" ]; then cp "$root/$file" "$work/$file"; fi
    done
    echo "== $(git -C "$work" log -1 --format='%h %s')"
    changed=$(git -C "$work" diff --name-only "$commit~1" "$commit")
    if echo "$changed" | grep -q '^ios/'; then "$work/ios/scripts/check_sources.sh"; fi
    if echo "$changed" | grep -q '^android/'; then "$work/android/scripts/check_sources.sh"; fi
    if [ -n "$extra" ]; then (cd "$work" && sh -c "$extra") || { echo "Failed at $(git -C "$work" log -1 --format='%h %s')"; exit 1; }; fi
done
echo "Every commit passed."
