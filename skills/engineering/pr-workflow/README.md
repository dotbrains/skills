# /pr-workflow

Create and update pull requests with consistent naming, concise reviewer-focused descriptions, and mergeability checks.

- Pushes the branch and targets the repo default base branch
- Aligns PR title with branch intent (`feat`, `fix`, `chore`)
- Focuses PR descriptions on **why** the change exists and **how** to verify it

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/pr-workflow
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/pr-workflow/SKILL.md \
  -o ~/.claude/skills/pr-workflow/SKILL.md
```

## Usage

Use when creating a PR, editing a PR description, assigning reviewers, or checking mergeability.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
