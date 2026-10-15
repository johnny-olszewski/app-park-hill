XCODEGEN_VERSION := 2.46.0

.PHONY: project check-xcodegen test-dev

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

## Run the Dev tests (unit, integration, UI) against freshly reset local
## Supabase. CI runs Mock only, so run this before merging changes to an app,
## /backend or /contract.
test-dev: project
	cd ../backend && supabase start && supabase db reset
	xcodebuild -scheme ParkHill-Dev -destination "id=$$(scripts/simulator.sh)" test
