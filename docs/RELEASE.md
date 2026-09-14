# Release Runbook

## Overview
Builds and IPA exports are produced locally using Make entrypoints (`make build` and `make ipa`).

## Prerequisites
- Apple Developer certificate and provisioning profile installed.
- Local configuration files (`DeveloperSettings.xcconfig` and `Hadge/Secrets.xcconfig`).

## Build and Export Flow
1. Verify local environment and tests:
   - `make doctor`
   - `make lint`
   - `make test`
2. Run archive build:
   - `make build`
3. Export IPA:
   - `make ipa`

## GitHub Operations
- All changes must be delivered via PR into `main` and squash merged.
- Use `gh` for GitHub releases and PRs:
  - `gh pr status`
  - `gh release list`
  - `gh release create`
