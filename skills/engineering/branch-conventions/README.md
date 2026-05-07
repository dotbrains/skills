# /branch-conventions

Standard branch naming and creation flow for feature work.

- Uses conventional prefixes: `feat/`, `fix/`, `chore/`
- Detects the repo default branch (`main` or `master`) before branching
- Starts from an up-to-date default branch to reduce avoidable merge drift

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/branch-conventions
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/branch-conventions/SKILL.md \
  -o ~/.claude/skills/branch-conventions/SKILL.md
```

## Usage

Use when creating a new branch for a feature, fix, or maintenance task.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
