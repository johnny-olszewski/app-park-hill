XCODEGEN_VERSION := 2.46.0

.PHONY: project check-xcodegen

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
