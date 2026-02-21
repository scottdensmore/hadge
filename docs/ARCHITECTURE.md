# Architecture

## Purpose
Hadge is an iOS app that reads HealthKit workout/activity data and exports yearly CSV files into a private GitHub repository.

## Runtime Flow
1. App launch initializes GitHub auth/session state and background task registration.
2. User signs in with GitHub OAuth (`ASWebAuthenticationSession`), token is stored in keychain.
3. Setup enables HealthKit background delivery and marks setup complete in `UserDefaults`.
4. Foreground or background collectors pull workouts/activity/distances from HealthKit.
5. CSV payloads are generated and written to GitHub repo paths via GitHub Contents API.

## Main Components
- App lifecycle: `Hadge/AppDelegate.swift`, `Hadge/SceneDelegate.swift`
- GitHub integration and token handling: `Hadge/Models/GitHub.swift`
- HealthKit querying and CSV generation: `Hadge/Models/Health.swift`
- Export orchestration and background pipeline: `Hadge/Helpers/BackgroundTaskHelper.swift`
- UI controllers and setup flow: `Hadge/Controllers/`
- Shared constants/user defaults/app IDs: `Hadge/Helpers/Constants.swift`

## Data And Export Layout
- Workouts: `workouts/<year>.csv`
- Activity rings: `activity/<year>.csv`
- Distances/steps: `distances/<year>.csv`

Each CSV is generated in-app and upserted through GitHub API calls from `GitHub.updateFile(...)`.

## Security And Secrets
- OAuth client values are sourced from `Hadge/Secrets.xcconfig` and injected via Sourcery template into generated code.
- Local secret/config files are intentionally ignored by git and blocked by pre-commit hook.
- CI secret scanning is enforced via gitleaks workflows.

## CI Topology
- PR validation: `.github/workflows/ci_pr.yml`
- Main branch build/release path: `.github/workflows/build_app.yml`
- Secret scanning (push/PR): `.github/workflows/secret_scan.yml`
- Secret scanning (scheduled full history): `.github/workflows/secret_scan_history.yml`
