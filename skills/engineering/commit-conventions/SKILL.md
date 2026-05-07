---
name: commit-conventions
description: "Formats commits as conventional commits and matches commit-message type (feat:, fix:, chore:) to branch intent, appending optional issue references."
version: 1.0.0
user-invocable: true
category: development
---

## Format

Commits should be formatted as conventional commits.

## Matching Branch Intent

The first commit should match the branch intent:

| Branch                | First Commit         |
| --------------------- | -------------------- |
| `feat/<feature-name>` | `feat: feature name` |
| `fix/<bug-name>`      | `fix: bug name`      |
| `chore/<task-name>`   | `chore: task name`   |

## Examples

```bash
# Feature branch
git commit -m "feat: add user avatar upload"

# Fix branch
git commit -m "fix: resolve plan export timeout"

# Chore branch
git commit -m "chore: update typescript to v5.3"
```

## With Issue References

Append issue reference when provided:

```bash
git commit -m "feat: add user avatar upload [AI-123]"
```
