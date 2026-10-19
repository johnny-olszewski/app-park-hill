#!/bin/sh
# Prints the UDID of an available iPhone simulator on the newest iOS runtime,
# for xcodebuild -destination "id=...". Used by CI and make test-dev.
xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
runtimes = sorted((r for r in devices if "iOS" in r), key=lambda r: [int(x) for x in r.rsplit("iOS-", 1)[-1].split("-")])
for runtime in reversed(runtimes):
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone")]
    if phones:
        print(phones[0]["udid"]); break
else:
    sys.exit("No available iPhone simulator")
'
