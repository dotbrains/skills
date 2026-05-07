# /ci-monitoring

Monitor GitHub PR checks, rerun failed jobs when appropriate, and confirm merge-readiness.

- Watches checks until pass/fail is clear
- Suggests rerunning only failed jobs for likely unrelated failures
- Emphasizes actionable CI signal over noisy informational checks

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/ci-monitoring
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/ci-monitoring/SKILL.md \
  -o ~/.claude/skills/ci-monitoring/SKILL.md
```

## Usage

Use when a PR has running or failing checks and you need a tight feedback loop.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
