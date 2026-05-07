---
name: branch-conventions
description: "Provides conventional-commit branch-name prefixes (feat/, fix/, chore/) and the standard flow for creating a branch from the up-to-date default branch."
version: 1.0.0
user-invocable: true
category: development
---

## Naming Convention

Branch names follow conventional commit type prefixes:

- `feat/<feature-name>` - New features
- `fix/<bug-name>` - Bug fixes
- `chore/<maintenance-name>` - Maintenance tasks

## Creating a Branch

Always create branches from an up-to-date default branch. The default branch is `main` or `master` depending on the repo — detect it before checking out:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
git checkout "$DEFAULT_BRANCH"
git pull origin "$DEFAULT_BRANCH"
git checkout -b <type>/<branch-name>
```

If `origin/HEAD` isn't set locally, run `git remote set-head origin --auto` once to populate it, or fall back to `git branch -r | grep -E 'origin/(main|master)$'` to pick the right one.

## Examples

```bash
git checkout -b feat/add-user-avatars
git checkout -b fix/plan-export-timeout
git checkout -b chore/update-dependencies
```
