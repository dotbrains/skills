---
name: ci-monitoring
description: "Watches GitHub PR checks and handles CI failures — reruns failed jobs, ignores the approval-requirements check, and confirms PR readiness once all required checks are green."
version: 1.0.0
user-invocable: true
category: development
---

## Watching PR Checks

```bash
gh pr checks <pr_number> --watch
```

Keep watching until:

- All checks pass, or
- You can clearly report which check failed and why

Note: You can ignore the "approval requirements" check which will not complete until a human approves.

## After New Commits

Re-run local tests and/or re-watch for GitHub PR checks.

## Handling Failures

### If a failing test appears unrelated to your change

Rerun only failed jobs (preferred):

1. Find run id in `gh pr checks` output or on GitHub Actions UI
2. Re-run failed jobs:
   ```bash
   gh run rerun <run_id> --failed
   ```

## PR Ready Confirmation

Confirm the PR is ready:

- All required checks green
- Approval requirements satisfied
- PR description complete and reviewer-friendly
