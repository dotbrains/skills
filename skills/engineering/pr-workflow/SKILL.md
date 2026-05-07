---
name: pr-workflow
description: "Creates and manages pull requests — pushes the branch, writes a reviewer-focused description (why + how to verify), names the PR to match branch intent, and checks mergeability. Triggers on any PR creation or description-editing request."
version: 1.0.0
user-invocable: true
category: development
---

## Committing Before Pushing

Use the `/git-commit` skill to stage and commit any outstanding changes before pushing. Never use `git commit -m` with inline strings.

## Pushing the Branch

```bash
git push origin <branch-name>
```

## Creating the PR

Create the PR against the repo's default branch unless directed otherwise. The default is `main` or `master` depending on the repo:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
gh pr create --base "$DEFAULT_BRANCH" ...
```

## PR Naming

PR name should match the branch intent:

| Branch                | PR Title             |
| --------------------- | -------------------- |
| `feat/<feature-name>` | `feat: feature name` |
| `fix/<bug-name>`      | `fix: bug name`      |
| `chore/<task-name>`   | `chore: task name`   |

May include an issue reference: `feat: feature name [AI-123]`

## Writing the PR Description

**Before writing, gather context:**

1. `git diff "origin/${DEFAULT_BRANCH}...HEAD"` — the actual changes; let these speak for themselves (use `origin/<default>` not the local ref — your local copy may be stale)
2. Check for a plan file (e.g. `.claude/plans/`, `PLAN.md`, or similar) — use it to understand intent, not to copy into the description
3. Read `.github/pull_request_template.md` and fill it out

**The description should answer two questions for a reviewer:**
- *Why* does this change exist?
- *How do I verify it works?*

The diff already shows *what* changed, so don't restate it.

### What to leave out

A PR description is not a lab report, a commit log, or an explanation of how you arrived at the solution. Strip out:

- Investigation steps ("I tried X and found Y")
- Disproved theories or dead ends
- Intermediary decisions that didn't make the final cut
- Anything that only makes sense if you were there (e.g. "the harness confirmed...")
- Self-congratulatory or hedging side commentary

If you're explaining *your process* rather than *the change*, cut it.

### Test steps

In **"Test steps"** (or the equivalent section in your PR template), write concrete steps a reviewer can follow:

- ✅ `npm test -- src/auth.test.ts` — relevant tests pass
- ❌ "I tested this locally and it works"

### Calibration

A good description is often 3–6 lines. If you're writing more than ~10 lines of prose, you're probably over-explaining. When in doubt, cut.

**Apply directly** — don't draft for user review first; use `gh pr edit` or `gh pr create` with the description inline.

## PR Assignment

```bash
gh pr edit <pr_number> --add-assignee @me
```

## Mergeability Check

```bash
gh pr view <pr_number> --json mergeable,mergeStateStatus
```

If `mergeable` is `CONFLICTING`, resolve conflicts before proceeding.
