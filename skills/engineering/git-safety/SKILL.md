---
name: git-safety
description: "Guards against destructive git operations — prefers stash + cherry-pick over rebase, restricts force pushes to `--force-with-lease`, and avoids `reset --hard` and `clean -fd`."
version: 1.0.0
user-invocable: true
category: development
---

## Core Principle

Prefer **stash + cherry-pick** to move work between branches.
Avoid `git rebase` and force pushes unless absolutely necessary.

## When switching context, stash first

If the working tree is not clean:

```bash
git status
git stash push -u -m "wip: <short description>"
```

## When you need to move work to a different base branch

Prefer _replaying commits_ rather than rebasing a branch:

1. Create a fresh branch from the up-to-date default branch (`main` or `master`, depending on the repo):
   ```bash
   DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   git checkout "$DEFAULT_BRANCH"
   git pull origin "$DEFAULT_BRANCH"
   git checkout -b <type>/<branch-name>-v2
   ```
2. Cherry-pick the relevant commit(s):
   ```bash
   git cherry-pick <sha1> <sha2> ...
   ```

## When you have uncommitted work that needs to move

Convert it into a safe, transferable unit:

```bash
git stash push -u -m "wip: <short description>"
# Switch to the target branch
git stash pop
# Commit the result
```

## Force push policy

- Default: **do not force push**.
- If you must rewrite history:
  - Prefer opening a new PR from a new branch rather than rewriting an existing PR branch.
  - If you still must force push, use `--force-with-lease` (never plain `--force`).

## Avoid these commands

Unless explicitly directed to do so:

- `git reset --hard`
- `git clean -fd`
- `git rebase` (prefer cherry-pick/merge)
- Force pushes
