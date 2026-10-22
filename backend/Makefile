# Generated data: seed.sql and contract fixtures come from
# contract/seed/dataset.json; client name constants come from
# contract/names.json; client screen models come from contract/screens.
# Never edit generated files by hand.

PYTHON ?= python3
GENERATED := supabase/seed.sql ../contract/fixtures ../contract/generated

.PHONY: seed fixtures names models data-check test-functions

## Generate supabase/seed.sql from the dataset
seed:
	$(PYTHON) scripts/generate_seed.py

## Generate the client name constants in contract/generated from names.json
names:
	$(PYTHON) scripts/generate_names.py

## Generate the client screen models in contract/generated from contract/screens
models:
	$(PYTHON) scripts/generate_models.py

## Reset local Supabase from migrations and seed, then regenerate fixtures
fixtures: seed
	supabase db reset
	$(PYTHON) scripts/generate_fixtures.py

## Regenerate everything and fail if it differs from what is committed
data-check: fixtures names models
	$(PYTHON) scripts/check_personas.py
	$(PYTHON) scripts/check_names.py
	$(PYTHON) scripts/check_models.py
	@if [ -n "$$(git status --porcelain -- $(GENERATED))" ]; then \
		git status --short -- $(GENERATED); \
		git --no-pager diff --stat -- $(GENERATED); \
		echo "Generated data differs from the committed files. Run 'make fixtures', 'make names' and 'make models', and commit the result."; \
		exit 1; \
	fi
	@echo "Generated data matches the dataset."

## Run the Edge Function tests against the running local stack
test-functions:
	$(PYTHON) -m unittest discover --start-directory tests/functions --verbose
