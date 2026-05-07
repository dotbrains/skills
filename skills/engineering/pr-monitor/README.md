# /pr-monitor

One-pass PR monitoring skill for AI review feedback, GitHub Actions failures, and merge-readiness.

- Resolves actionable bot review threads with scoped fixes
- Triages failing CI runs into fixable/report-only/stale categories
- Re-checks completion criteria before offering another monitoring pass

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/pr-monitor
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/pr-monitor/SKILL.md \
  -o ~/.claude/skills/pr-monitor/SKILL.md
```

## Usage

```text
/pr-monitor
/pr-monitor 123
/pr-monitor owner/repo#123
/pr-monitor https://github.com/owner/repo/pull/123
```

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
