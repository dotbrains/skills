# /commit-conventions

Conventional-commit guidance that keeps commit types aligned with branch intent.

- Branch intent and first commit type should match (`feat`, `fix`, `chore`)
- Supports optional issue references (for example `[ENG-123]`)
- Keeps commit history reviewable and predictable

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/commit-conventions
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/commit-conventions/SKILL.md \
  -o ~/.claude/skills/commit-conventions/SKILL.md
```

## Usage

Use when preparing commit messages, especially for the first commit on a branch.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
