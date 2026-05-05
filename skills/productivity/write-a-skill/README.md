# /write-a-skill

Create new agent skills with proper structure, progressive disclosure, and
bundled resources. Useful when you want to add a new entry to *this* repo, or
to build skills for any other agent that consumes the SKILL.md format.

## Flow

```mermaid
flowchart LR
  G[Gather requirements] --> D[Draft skill]
  D --> R[Review with user]
  R -->|revisions| D
  R -->|approved| F[Final skill]
```

## Skill structure the skill produces

```text
skill-name/
├── SKILL.md           # main instructions (required)
├── REFERENCE.md       # detailed docs (if needed)
├── EXAMPLES.md        # usage examples (if needed)
└── scripts/           # utility scripts (if needed)
    └── helper.js
```

`SKILL.md` should stay under ~100 lines; spill into REFERENCE/EXAMPLES files
when content gets large or rarely-needed. The frontmatter `description` is the
only thing the agent sees when deciding whether to load the skill — make it
specific.

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/write-a-skill
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/productivity/write-a-skill/SKILL.md \
  -o ~/.claude/skills/write-a-skill/SKILL.md
```

## Usage

Trigger by saying "write a skill", "create a skill", or "build a skill".

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.

## Attribution

Ported from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/skills/productivity/write-a-skill) under MIT. See [THIRD_PARTY_LICENSES.md](../../../THIRD_PARTY_LICENSES.md).
