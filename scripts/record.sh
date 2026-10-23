#!/bin/sh
# Records a slice's behavior criteria (guide 7.2 rule 4) into the gitignored
# recordings/<slice ID>/ folder. Recordings stay on this machine; PRs do not
# link them.
#
#   scripts/record.sh start <slice ID> <name> ios|android   start a screen recording
#   scripts/record.sh stop                                   stop every running recording and save it
#   scripts/record.sh terminal <slice ID> <name> <command>   run a command, saving a transcript
#
# Names say the criterion, platform build and what is shown, for example
# B2-mock-leader-leaves. Files: <name>-ios.mp4, <name>-android.mp4, and
# <name>.txt: a transcript of each command run from the repo root (shown with
# a leading +), its output and its exit status.
#
# iOS records the booted simulator; Android the one connected emulator or
# device, for at most 3 minutes (screenrecord's limit).

set -e

root=$(git rev-parse --show-toplevel)
active="$root/recordings/.active"

usage() {
    sed -n '6,8p' "$0" | sed 's/^# //'
    exit 2
}

folder() {
    case "$1" in
        EP-[0-9][0-9].[A-Z]) ;;
        *) echo "record: '$1' is not a slice ID such as EP-03.A" >&2; exit 2 ;;
    esac
    mkdir -p "$root/recordings/$1"
    echo "$root/recordings/$1"
}

start() {
    [ $# -eq 3 ] || usage
    dir=$(folder "$1")
    file="$dir/$2-$3.mp4"
    case "$3" in
        ios)
            udid=$(xcrun simctl list devices booted -j | python3 -c '
import json, sys
booted = [d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds]
print(booted[0] if booted else "")')
            [ -n "$udid" ] || { echo "record: no booted simulator" >&2; exit 1; }
            xcrun simctl io "$udid" recordVideo --codec=h264 --force "$file" </dev/null >/dev/null 2>&1 &
            echo "ios $! $file" >> "$active"
            ;;
        android)
            [ "$(adb devices | grep -c 'device$')" -eq 1 ] || { echo "record: connect exactly one emulator or device" >&2; exit 1; }
            remote="/sdcard/parkhill-recording-$$.mp4"
            adb shell screenrecord "$remote" </dev/null >/dev/null 2>&1 &
            echo "android $! $file $remote" >> "$active"
            ;;
        *) usage ;;
    esac
    sleep 1
    echo "record: recording $3 to ${file#$root/}; stop with scripts/record.sh stop"
}

stop() {
    [ -f "$active" ] || { echo "record: nothing is recording"; exit 0; }
    while read -r platform pid file remote; do
        case "$platform" in
            ios)
                kill -INT "$pid" 2>/dev/null || true
                ;;
            android)
                adb shell pkill -INT screenrecord </dev/null 2>/dev/null || true
                ;;
        esac
        while kill -0 "$pid" 2>/dev/null; do sleep 0.5; done
        if [ "$platform" = android ]; then
            sleep 1
            adb pull "$remote" "$file" </dev/null >/dev/null
            adb shell rm -f "$remote" </dev/null
        fi
        echo "record: saved ${file#$root/}"
    done < "$active"
    rm -f "$active"
}

terminal() {
    [ $# -ge 3 ] || usage
    dir=$(folder "$1")
    file="$dir/$2.txt"
    shift 2
    {
        echo "# $(date '+%Y-%m-%d %H:%M') $(git rev-parse --short HEAD)"
        status=0
        (cd "$root" && sh -xc "$*") 2>&1 || status=$?
        echo "# exit $status"
    } | tee "$file"
    echo "record: saved ${file#$root/}"
}

command=$1
[ -n "$command" ] || usage
shift
case "$command" in
    start) start "$@" ;;
    stop) stop ;;
    terminal) terminal "$@" ;;
    *) usage ;;
esac
