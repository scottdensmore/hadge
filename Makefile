SHELL := /bin/bash

PROJECT := Hadge.xcodeproj/
SCHEME := Hadge
BASE ?= main

.PHONY: help setup setup-non-interactive hooks doctor lint test ci-local build ipa pr-open pr-status

help:
	@echo "Available targets:"
	@echo "  make setup                    # interactive local setup"
	@echo "  make setup-non-interactive    # setup using env vars/flags (see setup.sh --help)"
	@echo "  make hooks                    # enable repo-managed hooks"
	@echo "  make doctor                   # run local environment checks"
	@echo "  make lint                     # run SwiftLint"
	@echo "  make test                     # run unit tests on first available iPhone simulator"
	@echo "  make ci-local                 # local CI subset (lint + test)"
	@echo "  make build                    # archive build"
	@echo "  make ipa                      # export IPA from archive"
	@echo "  make pr-open                  # create PR with gh (uses BASE=main by default)"
	@echo "  make pr-status                # show PR status via gh"

setup:
	./setup.sh

setup-non-interactive:
	./setup.sh --non-interactive

hooks:
	git config core.hooksPath .githooks

doctor:
	./scripts/doctor.sh

lint:
	swiftlint

test:
	@SIMULATOR_ID=$$(xcrun simctl list devices available iOS | awk -F '[()]' '/iPhone/ { print $$2; exit }'); \
	if [ -z "$$SIMULATOR_ID" ]; then \
		echo "error: no available iPhone simulator found" >&2; \
		exit 1; \
	fi; \
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "id=$$SIMULATOR_ID" \
		CODE_SIGNING_ALLOWED=NO \
		-enableCodeCoverage YES \
		test

ci-local: lint test

build:
	./.github/scripts/build_app.sh

ipa:
	./.github/scripts/export_ipa.sh

pr-open:
	gh pr create --base "$(BASE)" --fill

pr-status:
	gh pr status
