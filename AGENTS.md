# AGENTS.md

Guidance for agents working in `dotbrains/skills`.

## Scope

This repository is the canonical home for portable dotbrains skills. Each skill
lives in its own directory under `skills/<name>/` with a single `SKILL.md`.

Keep changes focused on:

- Skill behavior and wording in `skills/<name>/SKILL.md`
- Documentation clarity in the top-level `README.md`
- Portability across environments (no company-internal assumptions)

## Rules

- Keep branding generic and open-source friendly.
- Each `SKILL.md` must start with YAML frontmatter containing `name`,
  `description`, and `argument-hint`.
- Skill directory name must match the `name` field in its frontmatter.
- Prefer explicit idempotency and recovery behavior in skill flows.
- Do not hardcode environment-specific defaults when they can be discovered.
- Keep human-facing output concise and free of internal jargon.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with the required frontmatter.
2. Add an entry to the "Available skills" list in `README.md`.
3. Run `./scripts/list-skills.sh` to confirm the skill is discoverable.

## Validation

Before finishing, verify:

1. Every `SKILL.md` frontmatter is valid and complete.
2. References are generic (no company-internal docs).
3. `./scripts/list-skills.sh` lists every skill you intended to add.
4. CI passes (markdown lint + skill frontmatter validation).
