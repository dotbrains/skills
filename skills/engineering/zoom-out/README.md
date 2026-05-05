# /zoom-out

Tell the agent to zoom out and give a higher-level perspective on an
unfamiliar section of code — a map of the relevant modules and callers, named
in the project's domain vocabulary.

The skill body is one paragraph: it's deliberately small, and explicitly
disables model-invocation auto-triggering (`disable-model-invocation: true`)
so it only runs when you call it.

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/zoom-out
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/zoom-out/SKILL.md \
  -o ~/.claude/skills/zoom-out/SKILL.md
```

## Usage

Use when you don't know an area of code well and need orientation before
making changes.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.

## Attribution

Ported from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/skills/engineering/zoom-out) under MIT. See [THIRD_PARTY_LICENSES.md](../../../THIRD_PARTY_LICENSES.md).
