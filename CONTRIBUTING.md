# Contributing

## Workflow
- Create a branch for each change and open a pull request into `main`.
- Pull requests are squash merged to maintain a linear commit graph on `main`.
- Keep changes scoped and include tests when behavior changes.
- Do not push local secrets or generated secret files.

## Required Local Setup
- Install dependencies: `brew bundle`
- Enable hooks once per clone: `git config core.hooksPath .githooks`
- Use project entrypoints: `make help`
- Run environment checks: `make doctor`
- Review architecture and release docs:
  - `docs/ARCHITECTURE.md`
  - `docs/RELEASE.md`

## Validation Before PR
- Run `make lint`
- Run `make test`
- Confirm no sensitive files are staged:
  - `DeveloperSettings.xcconfig`
  - `Hadge/Secrets.xcconfig`
  - `Hadge/Generated/Secrets.generated.swift`

## Pull Requests
- Fill out `.github/pull_request_template.md`.
- Use issue templates from `.github/ISSUE_TEMPLATE/` for new bug/feature issues.
- Validate changes locally with `make lint` and `make test`.
- Pull requests are merged with squash merge to keep a linear commit history.

## GitHub Operations
- Use GitHub CLI (`gh`) for GitHub work when available.
- Common commands:
  - `gh pr create`
  - `gh pr status`
  - `gh pr merge --squash`
- Make helpers:
  - `make pr-open`
  - `make pr-status`
