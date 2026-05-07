# /git-safety

Guardrails for safe git operations during active development.

- Prefers stash + cherry-pick over rebase for moving work
- Restricts force pushes to `--force-with-lease`
- Avoids destructive defaults like `reset --hard` and `clean -fd`

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/git-safety
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/git-safety/SKILL.md \
  -o ~/.claude/skills/git-safety/SKILL.md
```

## Usage

Use when switching branches, moving work across branches, or deciding whether to rewrite history.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
