# Release Runbook

## Overview
Releases are created by GitHub Actions from `main` in `.github/workflows/build_app.yml`.

The workflow always runs tests. Signing/build/export/release steps only run when `CERTIFICATE_GPG_KEY` is present.

## Required GitHub Secrets
- `OCTO_CLIENT_ID`
- `OCTO_CLIENT_SECRET`
- `CERTIFICATE_GPG_KEY` (required for signed IPA + release)

## Release Path (Automated)
1. Merge PR to `main`.
2. `Build App` workflow runs.
3. Workflow bumps `CFBundleVersion` and commits it.
4. Encrypted cert/profile are decrypted and imported.
5. App archive and IPA export run.
6. A GitHub Release is created with tag `v<marketingVersion>-<buildVersion>` and `Hadge.ipa` attached.

## Dry-Run / Local Checks Before Merge
- `make doctor`
- `make lint`
- `make test`

## Troubleshooting
- Missing release artifacts:
  - Verify `CERTIFICATE_GPG_KEY` is configured and valid.
- OAuth/auth failures in build:
  - Verify `OCTO_CLIENT_ID` and `OCTO_CLIENT_SECRET`.
- Signing failures:
  - Verify encrypted files under `.github/secrets/` and passphrase correctness.

## Operational Notes
- Prefer PR-based delivery to `main` so required checks run normally.
- Use `gh` for release and workflow operations when available:
  - `gh run list`
  - `gh run view --log <run-id>`
  - `gh release list`
