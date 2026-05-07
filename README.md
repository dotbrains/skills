# skills

[![CI](https://github.com/dotbrains/skills/actions/workflows/ci.yml/badge.svg)](https://github.com/dotbrains/skills/actions/workflows/ci.yml)
[![License: PolyForm Shield](https://img.shields.io/badge/License-PolyForm%20Shield-brightgreen.svg)](https://polyformproject.org/licenses/shield/1.0.0)

[![skills.sh](https://skills.sh/b/dotbrains/skills)](https://skills.sh/dotbrains/skills)

Portable agent skills from [dotbrains](https://github.com/dotbrains).

## Quickstart

```bash
npx skills@latest add dotbrains/skills
```

Pick the skills you want, choose the agents to install them on, and you're done.

## Install (release script)

For the same release-delivered installer pattern used in `this repository`,
download and run `install.sh` / `install.ps1` from a GitHub Release.

Prerequisites:

- Node.js 18+
- GitHub CLI (`gh`)

macOS / Linux:

```bash
tmp="$(mktemp)"; gh release download --repo dotbrains/skills --pattern 'install.sh' --output "$tmp" --clobber; bash "$tmp"; rm "$tmp"
```

Windows PowerShell:

```powershell
$p = Join-Path $env:TEMP 'install.ps1'; gh release download --repo dotbrains/skills --pattern 'install.ps1' --output $p --clobber; & $p; Remove-Item $p
```

The installer validates Node.js and then runs:

```bash
npx --yes skills@latest add dotbrains/skills
```

Any additional arguments passed to the installer are forwarded to `skills add`.

## Available skills

### Engineering

Skills for code work — bug-hunting, design, planning, review, and execution.
- **[branch-conventions](./skills/engineering/branch-conventions/README.md)** — Standard branch naming and creation flow using conventional prefixes and an up-to-date default branch.
- **[ci-monitoring](./skills/engineering/ci-monitoring/README.md)** — Monitor GitHub PR checks, rerun failed jobs when appropriate, and confirm merge-readiness.
- **[commit-conventions](./skills/engineering/commit-conventions/README.md)** — Keep commit messages aligned with branch intent using conventional commit types.
- **[diagnose](./skills/engineering/diagnose/README.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[git-commit](./skills/engineering/git-commit/README.md)** — Safe commit-message workflow using temp files and `git commit -F` to avoid shell-substitution pitfalls.
- **[git-safety](./skills/engineering/git-safety/README.md)** — Guardrails for safe git operations: stash/cherry-pick preference, force-push constraints, and destructive-command avoidance.
- **[grill-with-docs](./skills/engineering/grill-with-docs/README.md)** — Code-aware grilling session that challenges your plan against the existing domain model and updates `CONTEXT.md` / ADRs inline.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/README.md)** — Surface architectural friction and propose deepening opportunities — refactors that turn shallow modules into deep ones.
- **[pr-monitor](./skills/engineering/pr-monitor/README.md)** — One-pass PR monitor that processes bot review feedback, CI failures, and merge-readiness signals.
- **[pr-workflow](./skills/engineering/pr-workflow/README.md)** — Create and update PRs with clear reviewer-focused descriptions and mergeability checks.
- **[review](./skills/engineering/review/README.md)** — Read-only, high-signal pull request review using PR description, ticket scope, full diff context, and PR-suggested tests. Returns Critical / Suggestions / Nits.
- **[tdd](./skills/engineering/tdd/README.md)** — Test-driven development with a red-green-refactor loop. Vertical slices via tracer bullets — one test, one implementation, repeat.
- **[to-issues](./skills/engineering/to-issues/README.md)** — Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices.
- **[to-prd](./skills/engineering/to-prd/README.md)** — Turn the current conversation context into a PRD and publish it to the project issue tracker.
- **[triage](./skills/engineering/triage/README.md)** — Move issues through a small state machine of triage roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`).
- **[workon](./skills/engineering/workon/README.md)** — Pick up a Linear ticket end-to-end: worktree, implement, PR, then watch the PR on a 5-minute loop addressing review comments, CI failures, and merge conflicts until merged.
- **[workon-event](./skills/engineering/workon-event/README.md)** — Event-driven `/workon` companion that handles one ticket event per invocation via a dispatcher.
- **[zoom-out](./skills/engineering/zoom-out/README.md)** — Tell the agent to zoom out and give a higher-level perspective on an unfamiliar section of code.

### Productivity

General workflow skills, not code-specific.

- **[caveman](./skills/productivity/caveman/README.md)** — Ultra-compressed communication mode. Cuts token usage ~75% by dropping filler while keeping full technical accuracy.
- **[grill-me](./skills/productivity/grill-me/README.md)** — Get interviewed relentlessly about a plan or design until every branch of the decision tree resolves.
- **[write-a-skill](./skills/productivity/write-a-skill/README.md)** — Create new agent skills with proper structure, progressive disclosure, and bundled resources.

Each skill directory contains its own `README.md` (with usage and any
diagrams) and the canonical `SKILL.md` consumed by the agent.

## Why these skills exist

These skills are a response to specific failure modes we keep hitting with
coding agents. Each one targets a problem we got tired of repeating and
encodes the workaround so the agent does it without being asked.

### 1. The agent doesn't actually understand what you want

The default failure of any AI coding session is misalignment. You think you
described the change clearly; the agent confidently builds something else.
Catching it ten minutes in is cheap, catching it after a full implementation
is not.

The fix is a **grilling session before any code gets written** — let the
agent ask you the questions you forgot to answer.

- [`/grill-me`](./skills/productivity/grill-me/README.md) — design / non-code grilling
- [`/grill-with-docs`](./skills/engineering/grill-with-docs/README.md) — same loop, but layered on the project's domain glossary and ADRs

### 2. The agent uses ten words where one would do

Agents drop into a project with no shared vocabulary, so they describe
everything in long generic English. The longer the description, the more
tokens you burn and the easier it is to lose precision.

The fix is a **shared language** captured in a `CONTEXT.md` and grown
incrementally. Once "the materialization cascade" is a defined term, the
agent says "the materialization cascade" instead of three sentences.

`/grill-with-docs` builds that language for you as a side-effect of
grilling — whenever a fuzzy term gets sharpened during the session, it gets
written to `CONTEXT.md` immediately.

### 3. The code doesn't work

When the agent and you are aligned on what to build, the next failure mode
is the agent producing code that compiles but doesn't behave. The cure is
**fast, deterministic feedback loops**: types, tests, browser access — and
discipline about how to use them.

- [`/tdd`](./skills/engineering/tdd/README.md) — red-green-refactor with vertical-slice tracer bullets, not horizontal "write all tests first"
- [`/diagnose`](./skills/engineering/diagnose/README.md) — bug-hunt loop where Phase 1 is *building the feedback loop itself*; everything else is mechanical

### 4. The codebase becomes a ball of mud

Agents accelerate coding, which means they also accelerate entropy. Without
deliberate design effort, the codebase grows complex faster than any human
can keep in their head.

The cure is **caring about design every day** — surfacing architectural
friction early and refactoring shallow modules into deep ones before they
calcify.

- [`/zoom-out`](./skills/engineering/zoom-out/README.md) — get oriented before changing unfamiliar code
- [`/to-prd`](./skills/engineering/to-prd/README.md) — capture the modules you're about to touch in a PRD before any code gets written
- [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/README.md) — find deepening opportunities in an existing codebase, run periodically

### 5. The PR cycle eats your day

Even when the agent ships good code, getting it through review, CI, and
merge is its own slog: address reviewer comments, fix flaky checks, rebase
when conflicts appear, repeat for hours.

The cure is **letting the agent own the entire ticket** — from worktree to
merge — and **reviewing each PR with the same discipline a human reviewer
would**.

- [`/workon`](./skills/engineering/workon/README.md) — drives a Linear ticket end-to-end, including a 5-minute watch loop that addresses review comments, fixes CI failures, and resolves merge conflicts until the PR merges
- [`/review`](./skills/engineering/review/README.md) — read-only, high-signal PR review with explicit Critical / Suggestions / Nits tiers, scoped against the ticket's stated intent

The first four failure modes are general — the engineering ideas behind
them are largely from
[mattpocock/skills](https://github.com/mattpocock/skills), where most of
those skills originated. `/workon` and `/review` are dotbrains originals
written for our own delivery loop.

## Further reading

The skills draw on a small canon. If you want the long-form versions of the
ideas they encode, these four books are the source material:

- **[The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)** — David Thomas & Andrew Hunt. The classic on alignment ("no-one knows exactly what they want") and feedback loops ("the rate of feedback is your speed limit"). Underpins `/grill-me` and `/diagnose`.
- **[Domain-Driven Design](https://www.domainlanguage.com/ddd/)** — Eric Evans. The case for a ubiquitous language shared between developers and domain experts. Underpins `/grill-with-docs` and the `CONTEXT.md` discipline.
- **[Extreme Programming Explained](https://www.informit.com/store/extreme-programming-explained-embrace-change-9780321278654)** — Kent Beck. "Invest in the design of the system every day." Underpins `/tdd` and the design-first stance of `/improve-codebase-architecture`.
- **[A Philosophy of Software Design](https://web.stanford.edu/~ouster/cgi-bin/book.php)** — John Ousterhout. Source of the deep-modules framing — "the best modules are deep" — that drives `/improve-codebase-architecture` and informs `/to-prd`.

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
    branch-conventions/ SKILL.md  README.md
    ci-monitoring/      SKILL.md  README.md
    commit-conventions/ SKILL.md  README.md
    diagnose/
      SKILL.md
      README.md
      scripts/hitl-loop.template.sh
    git-commit/         SKILL.md  README.md
    git-safety/         SKILL.md  README.md
    grill-with-docs/
      SKILL.md  README.md
      CONTEXT-FORMAT.md  ADR-FORMAT.md
    improve-codebase-architecture/
      SKILL.md
      README.md
      DEEPENING.md  INTERFACE-DESIGN.md  LANGUAGE.md
    pr-monitor/     SKILL.md  README.md
    pr-workflow/    SKILL.md  README.md
    review/        SKILL.md  README.md
    tdd/           SKILL.md  README.md
                   tests.md  mocking.md  deep-modules.md
                   interface-design.md  refactoring.md
    to-issues/     SKILL.md  README.md
    to-prd/        SKILL.md  README.md
    triage/        SKILL.md  README.md
                   AGENT-BRIEF.md  OUT-OF-SCOPE.md
    workon/        SKILL.md  README.md
    workon-event/  SKILL.md  README.md
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
