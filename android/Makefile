.PHONY: test-dev

## Run the dev integration and UI tests against freshly reset local Supabase,
## on a running emulator or device. CI runs Mock only, so run this before merging
## changes to an app, /backend or /contract.
test-dev:
	cd ../backend && supabase start && supabase db reset
	./gradlew --console=plain connectedDevDebugAndroidTest
