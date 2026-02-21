# AGENTS.md

Agent-focused guide for working in this repository.

For repository-wide contribution policy (PR flow and required checks), see `CONTRIBUTING.md`.
System context and release process docs live in:
- `docs/ARCHITECTURE.md`
- `docs/RELEASE.md`

## Project Snapshot
- App: `Hadge` (iOS, UIKit, Swift)
- Xcode project: `Hadge.xcodeproj`
- App source: `Hadge/`
- Tests: `HadgeTests/`
- CI workflows:
  - `.github/workflows/ci_pr.yml` (PR lint/test)
  - `.github/workflows/build_app.yml` (push build/release path)
  - `.github/workflows/secret_scan.yml` (secret scanning)
  - `.github/workflows/secret_scan_history.yml` (scheduled full-history secret scanning)

## Tooling
- Xcode 16+ and iOS Simulator tooling (`xcodebuild`, `xcrun`)
- Homebrew dependencies from `Brewfile`:
  - `swiftlint`
  - `sourcery`

Install dependencies:

```bash
brew bundle
```

Use repo entrypoints where possible:

```bash
make help
make doctor
```

## Setup
Run the guided setup script:

```bash
make setup
```

Or create config files manually:
- `DeveloperSettings.xcconfig` from `DeveloperSettings.template.xcconfig`
- `Hadge/Secrets.xcconfig` from `Hadge/Secrets.template.xcconfig`

For automation, use non-interactive setup (requires all values via env vars or flags):

```bash
DEV_TEAM_ID=... \
ORG_IDENTIFIER=... \
GITHUB_CLIENT_ID=... \
GITHUB_CLIENT_SECRET=... \
make setup-non-interactive
```

`Hadge/Generated/Secrets.generated.swift` is generated from `Hadge/Helpers/Secrets.stencil` by a build phase (Sourcery). Do not edit generated files directly.

Enable repo-managed Git hooks (one-time per clone):

```bash
git config core.hooksPath .githooks
```

## Common Commands
Run environment diagnostics:

```bash
make doctor
```

Run lint:

```bash
make lint
```

Run unit tests on an available iPhone simulator:

```bash
make test
```

Build archive (release-oriented):

```bash
make build
```

GitHub PR helpers:

```bash
make pr-open
make pr-status
```

## GitHub Workflow Rule
- For any GitHub task (PRs, issues, workflow runs, releases, labels, comments), use the GitHub CLI (`gh`) when it is available.
- Only fall back to web UI or direct API calls when `gh` is unavailable or missing required functionality.

## Change Guidelines
- Keep changes scoped; avoid unrelated refactors.
- Add or update tests in `HadgeTests/` when behavior changes.
- Keep secrets out of commits. Never hardcode credentials in Swift source.
- The pre-commit hook blocks known secret files and obvious credential patterns in staged changes.
- CI also runs `.github/workflows/secret_scan.yml` (gitleaks) on pushes and pull requests.
- Repo-specific gitleaks rules live in `.gitleaks.toml`.
- If you update CI scripts or workflow behavior, keep this file and `README.md` aligned.
