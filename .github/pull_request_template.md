## Summary
- What changed?
- Why did it change?

## Validation
- [ ] Ran `make lint`
- [ ] Ran `make test` (or explained below why it was skipped)

## Security And Secrets
- [ ] No credentials, tokens, or private keys were added
- [ ] Did not stage local/generated secret files (`DeveloperSettings.xcconfig`, `Hadge/Secrets.xcconfig`, `Hadge/Generated/Secrets.generated.swift`)
- [ ] Secret checks pass locally/CI (pre-commit hook and gitleaks workflow)

## Agent Workflow Checks
- [ ] Updated `/Users/scottdensmore/Developer/scottdensmore/hadge/AGENTS.md` and/or `/Users/scottdensmore/Developer/scottdensmore/hadge/README.md` if workflow/tooling changed
- [ ] Used GitHub CLI (`gh`) for GitHub operations when available

## Notes
- Risks, follow-ups, or anything reviewers should verify
