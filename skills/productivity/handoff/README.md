# /handoff

Compact the current conversation into a **handoff document** so another
agent can pick up the work. The doc lives at a `mktemp` path so it doesn't
clutter the repo, and references existing artifacts (PRDs, plans, ADRs,
issues, commits, diffs) by path or URL rather than duplicating them.

## Usage

Trigger when you're about to end a session and want the next agent (or
yourself, tomorrow) to start without re-reading the whole transcript.

The skill takes an optional argument describing what the next session will
focus on — pass it to tailor the doc accordingly. Example:

```text
/handoff finish the migration and run the smoke tests
```

If no argument is provided, the doc summarises the whole conversation.

## What it produces

- A markdown file at `$(mktemp -t handoff-XXXXXX.md)` containing:
  - The current state of the work.
  - References to existing artifacts (no duplication).
  - A suggested set of skills for the next session.

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/handoff
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/productivity/handoff/SKILL.md \
  -o ~/.claude/skills/handoff/SKILL.md
```

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.

## Attribution

Ported from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/skills/productivity/handoff) under MIT. See [THIRD_PARTY_LICENSES.md](../../../THIRD_PARTY_LICENSES.md).
