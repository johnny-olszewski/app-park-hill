# Generated data: seed.sql and contract fixtures come from
# contract/seed/dataset.json; client name constants come from
# contract/names.json; client screen models come from contract/screens.
# Never edit generated files by hand.

PYTHON ?= python3
GENERATED := supabase/seed.sql ../contract/mock_responses ../contract/generated

.PHONY: seed mock-responses names models data-check test-functions test-scripts

## Generate supabase/seed.sql from the dataset
seed:
	$(PYTHON) scripts/generate_seed.py

## Generate the client name constants in contract/generated from names.json
names:
	$(PYTHON) scripts/generate_names.py

## Generate the client screen models in contract/generated from contract/screens
models:
	$(PYTHON) scripts/generate_models.py

## Reset local Supabase from migrations and seed, then regenerate the mock responses
mock-responses: seed
	supabase db reset
	$(PYTHON) scripts/generate_mock_responses.py

## Regenerate everything and fail if it differs from what is committed
data-check: mock-responses names models
	$(PYTHON) scripts/check_personas.py
	$(PYTHON) scripts/check_names.py
	$(PYTHON) scripts/check_models.py
	@if [ -n "$$(git status --porcelain -- $(GENERATED))" ]; then \
		git status --short -- $(GENERATED); \
		git --no-pager diff --stat -- $(GENERATED); \
		echo "Generated data differs from the committed files. Run 'make mock-responses', 'make names' and 'make models', and commit the result."; \
		exit 1; \
	fi
	@echo "Generated data matches the dataset."

## Run the Edge Function tests against the running local stack
test-functions:
	$(PYTHON) -m unittest discover --start-directory tests/functions --verbose

## Run the unit tests for the generation and check scripts (no stack needed)
test-scripts:
	$(PYTHON) -m unittest discover --start-directory tests/scripts --verbose
