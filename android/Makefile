.PHONY: test-unit test-smoke test-local-smoke test-full test-local

GRADLE = ./gradlew --console=plain

## Unit tests (every task), both flavors.
test-unit:
	$(GRADLE) testMockDebugUnitTest testLocalDebugUnitTest

## Merge gate in mock (guide 7.2 rule 4): the smoke instrumented tests in
## smoke-mock.txt, on a running emulator or device. CI runs this on every PR,
## after the unit tests.
test-smoke:
	$(GRADLE) connectedMockDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=$$(../scripts/smoke_tests.sh gradle smoke-mock.txt)

## Merge gate against local Supabase: the smoke instrumented tests in
## smoke-local.txt. Run before merging changes to an app, /backend or /contract.
test-local-smoke:
	cd ../backend && supabase start && supabase db reset
	$(GRADLE) connectedLocalDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=$$(../scripts/smoke_tests.sh gradle smoke-local.txt)

## Every mock instrumented test. Runs nightly in CI.
test-full:
	$(GRADLE) connectedMockDebugAndroidTest

## Every local instrumented test against freshly reset local Supabase. Runs
## nightly in CI.
test-local:
	cd ../backend && supabase start && supabase db reset
	$(GRADLE) connectedLocalDebugAndroidTest
