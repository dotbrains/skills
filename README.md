# skills

[![CI](https://github.com/dotbrains/skills/actions/workflows/ci.yml/badge.svg)](https://github.com/dotbrains/skills/actions/workflows/ci.yml)
[![License: PolyForm Shield](https://img.shields.io/badge/License-PolyForm%20Shield-brightgreen.svg)](https://polyformproject.org/licenses/shield/1.0.0)

Portable agent skills from [dotbrains](https://github.com/dotbrains).

## Quickstart

```bash
npx skills@latest add dotbrains/skills
```

Pick the skills you want, choose the agents to install them on, and you're done.

## Available skills

- **[workon](./skills/workon/SKILL.md)** — Pick up a Linear ticket end-to-end: worktree, implement, PR, then watch the PR on a 5-minute loop addressing review comments, CI failures, and merge conflicts until merged.
- **[review](./skills/review/SKILL.md)** — Read-only, high-signal pull request review using PR description, ticket scope, full diff context, and PR-suggested tests. Returns Critical / Suggestions / Nits.

## Manual install

If you don't want to use `npx skills`, copy the `SKILL.md` you want into your agent's skills directory. For Claude Code:

```bash
mkdir -p ~/.claude/skills/workon
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/workon/SKILL.md \
  -o ~/.claude/skills/workon/SKILL.md
```

```bash
mkdir -p ~/.claude/skills/review
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/review/SKILL.md \
  -o ~/.claude/skills/review/SKILL.md
```

Or, from a clone of this repo, symlink every skill into `~/.claude/skills/`:

```bash
./scripts/link-skills.sh
```

## Repository layout

```
skills/
  workon/SKILL.md   # /workon
  review/SKILL.md   # /review
scripts/
  link-skills.sh    # symlink every SKILL.md into ~/.claude/skills/
  list-skills.sh    # print discovered SKILL.md paths
```

The `npx skills add` CLI scans `skills/<name>/SKILL.md`, so any skill added under that layout is auto-discovered.

## Contributing

Each skill lives in its own directory under `skills/<name>/` with a single canonical `SKILL.md` containing YAML frontmatter (`name`, `description`, `argument-hint`). CI validates frontmatter and lints markdown across the repo.

## License

PolyForm Shield 1.0.0 — see [LICENSE](./LICENSE).
