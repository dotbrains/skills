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

### Engineering

Skills for code work — bug-hunting, design, planning, review, and execution.

- **[diagnose](./skills/engineering/diagnose/README.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[grill-with-docs](./skills/engineering/grill-with-docs/README.md)** — Code-aware grilling session that challenges your plan against the existing domain model and updates `CONTEXT.md` / ADRs inline.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/README.md)** — Surface architectural friction and propose deepening opportunities — refactors that turn shallow modules into deep ones.
- **[review](./skills/engineering/review/README.md)** — Read-only, high-signal pull request review using PR description, ticket scope, full diff context, and PR-suggested tests. Returns Critical / Suggestions / Nits.
- **[tdd](./skills/engineering/tdd/README.md)** — Test-driven development with a red-green-refactor loop. Vertical slices via tracer bullets — one test, one implementation, repeat.
- **[to-issues](./skills/engineering/to-issues/README.md)** — Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices.
- **[to-prd](./skills/engineering/to-prd/README.md)** — Turn the current conversation context into a PRD and publish it to the project issue tracker.
- **[triage](./skills/engineering/triage/README.md)** — Move issues through a small state machine of triage roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`).
- **[workon](./skills/engineering/workon/README.md)** — Pick up a Linear ticket end-to-end: worktree, implement, PR, then watch the PR on a 5-minute loop addressing review comments, CI failures, and merge conflicts until merged.
- **[zoom-out](./skills/engineering/zoom-out/README.md)** — Tell the agent to zoom out and give a higher-level perspective on an unfamiliar section of code.

### Productivity

General workflow skills, not code-specific.

- **[caveman](./skills/productivity/caveman/README.md)** — Ultra-compressed communication mode. Cuts token usage ~75% by dropping filler while keeping full technical accuracy.
- **[grill-me](./skills/productivity/grill-me/README.md)** — Get interviewed relentlessly about a plan or design until every branch of the decision tree resolves.
- **[write-a-skill](./skills/productivity/write-a-skill/README.md)** — Create new agent skills with proper structure, progressive disclosure, and bundled resources.

Each skill directory contains its own `README.md` (with usage and any
diagrams) and the canonical `SKILL.md` consumed by the agent.

## Manual install

If you don't want to use `npx skills`, copy the `SKILL.md` you want into your
agent's skills directory. For Claude Code:

```bash
mkdir -p ~/.claude/skills/diagnose
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/diagnose/SKILL.md \
  -o ~/.claude/skills/diagnose/SKILL.md
```

Or, from a clone of this repo, symlink every skill into `~/.claude/skills/`:

```bash
./scripts/link-skills.sh
```

## Repository layout

```text
skills/
  engineering/
    diagnose/
      SKILL.md
      README.md
      scripts/hitl-loop.template.sh
    grill-with-docs/
      SKILL.md  README.md
      CONTEXT-FORMAT.md  ADR-FORMAT.md
    improve-codebase-architecture/
      SKILL.md
      README.md
      DEEPENING.md  INTERFACE-DESIGN.md  LANGUAGE.md
    review/        SKILL.md  README.md
    tdd/           SKILL.md  README.md
                   tests.md  mocking.md  deep-modules.md
                   interface-design.md  refactoring.md
    to-issues/     SKILL.md  README.md
    to-prd/        SKILL.md  README.md
    triage/        SKILL.md  README.md
                   AGENT-BRIEF.md  OUT-OF-SCOPE.md
    workon/        SKILL.md  README.md
    zoom-out/      SKILL.md  README.md
  productivity/
    caveman/       SKILL.md  README.md
    grill-me/      SKILL.md  README.md
    write-a-skill/ SKILL.md  README.md
scripts/
  link-skills.sh   # symlink every SKILL.md into ~/.claude/skills/
  list-skills.sh   # print discovered SKILL.md paths
```

The `npx skills add` CLI scans `skills/<category>/<name>/SKILL.md`, so any
skill added under that layout is auto-discovered.

## Contributing

Each skill lives in its own directory under
`skills/<category>/<name>/SKILL.md`, where `<category>` is one of
`engineering`, `productivity`, or `misc`. Every `SKILL.md` must start with YAML
frontmatter containing at minimum `name` and `description`. CI validates
frontmatter, checks that the directory name matches the `name` field, and
lints markdown across the repo.

## Attributions

Several skills are ported from
[mattpocock/skills](https://github.com/mattpocock/skills) under MIT — see
[THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md) for the full attribution
and license text.

## License

PolyForm Shield 1.0.0 — see [LICENSE](./LICENSE).
