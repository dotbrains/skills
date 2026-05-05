# skills/

All dotbrains agent skills, grouped by category. Each skill lives at
`skills/<category>/<name>/SKILL.md` and has its own `README.md` with usage and
diagrams.

## Categories

- **[engineering/](./engineering/README.md)** — code-focused skills: bug-hunting, design, planning, review, execution.
- **[productivity/](./productivity/README.md)** — general workflow skills, not code-specific.

The `npx skills@latest add dotbrains/skills` CLI scans this directory
recursively and surfaces every `SKILL.md` it finds.

## Adding a skill

1. Pick the right category (or create one — see top-level [AGENTS.md](../AGENTS.md)).
2. Create `skills/<category>/<name>/SKILL.md` with frontmatter (`name`, `description`).
3. Add a per-skill `README.md` with usage, any diagrams, and attribution if ported.
4. Add an entry to the category's `README.md` and to the root [README](../README.md).
5. Run `../scripts/list-skills.sh` to confirm discovery, then push — CI validates frontmatter and category.
