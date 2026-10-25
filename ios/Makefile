XCODEGEN_VERSION := 2.46.0

.PHONY: project check-xcodegen test-unit test-smoke test-local-smoke test-full test-local

## Generate ParkHill.xcodeproj from project.yml
project: check-xcodegen
	xcodegen generate --spec project.yml

check-xcodegen:
	@command -v xcodegen >/dev/null || { echo "XcodeGen not found. Install it: brew install xcodegen"; exit 1; }
	@installed="$$(xcodegen --version | sed 's/[^0-9.]//g')"; \
	if [ "$$installed" != "$(XCODEGEN_VERSION)" ]; then \
		echo "XcodeGen $(XCODEGEN_VERSION) required, found $$installed. Update the pin here and in ios/README.md together."; \
		exit 1; \
	fi

DESTINATION = -destination "id=$$(scripts/simulator.sh)"

## Unit tests (every task): the Mock scheme's unit tests only.
test-unit: project
	xcodebuild -scheme ParkHill-Mock $(DESTINATION) test -only-testing:ParkHillTests

## Merge gate in Mock (guide 7.2 rule 4): unit tests and the smoke UI tests in
## smoke-mock.txt. CI runs this on every PR.
test-smoke: project
	xcodebuild -scheme ParkHill-Mock $(DESTINATION) test -only-testing:ParkHillTests $$(../scripts/smoke_tests.sh xcodebuild smoke-mock.txt)

## Merge gate against local Supabase: unit and integration tests and the smoke
## UI tests in smoke-local.txt. Run before merging changes to an app, /backend
## or /contract (CI cannot run iOS against Supabase).
test-local-smoke: project
	cd ../backend && supabase start && supabase db reset
	xcodebuild -scheme ParkHill-Local $(DESTINATION) test -only-testing:ParkHillTests $$(../scripts/smoke_tests.sh xcodebuild smoke-local.txt)

## Every Mock test, UI tests included. Runs nightly in CI.
test-full: project
	xcodebuild -scheme ParkHill-Mock $(DESTINATION) test

## Every Local test against freshly reset local Supabase. Not run in CI (no
## Docker on its Mac runners): run it before a release or when a change needs it.
test-local: project
	cd ../backend && supabase start && supabase db reset
	xcodebuild -scheme ParkHill-Local $(DESTINATION) test
