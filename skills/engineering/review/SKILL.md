---
name: review
description: Review a pull request end-to-end in read-only mode by using the PR description, associated ticket scope, full diff context, and PR-suggested tests. Return only high-signal findings grouped as Critical, Suggestions, and Nits.
argument-hint: "<PR-URL-or-NUMBER>"
---

# Review: high-signal pull request reviewer

Deep, read-only review skill. It inspects intent, implementation, and validation
without changing code, posting comments, or mutating git state.

**Arguments:** "$ARGUMENTS"

## 0. Parse argument

Accept either:

- A full GitHub pull request URL (e.g.
  `https://github.com/owner/repo/pull/123`)
- A PR number (e.g. `123`) in the current repository

If the input is missing or malformed, stop with a short usage hint.

## 1. Resolve PR and baseline metadata

Use GitHub CLI to resolve PR details:

```bash
gh pr view "$PR_REF" --json number,title,body,state,baseRefName,headRefName,url,author
```

If PR is closed/merged, still review unless user explicitly requested only open PRs.

Capture:

- PR title/body (stated intent)
- base/head branches
- PR URL and number
- author

## 2. Build scope context (PR + associated ticket)

### 2.1 Read PR description thoroughly

Extract:

- Claimed problem
- Claimed solution
- Claimed risks/tradeoffs
- Claimed tests run

### 2.2 Resolve associated ticket/issue

Try in order:

1. Parse ticket references from PR body/title (e.g. `ENG-123`, `#456`,
   linked URLs).
2. If a Linear-style ticket id exists, fetch ticket details and latest comments
   through the configured **Linear MCP server** (e.g. `mcp__*Linear__get_issue`,
   `mcp__*Linear__list_comments`; exact prefix depends on the user's MCP server
   name). Do not fall back to the Linear REST API, the `linear` CLI, or HTML
   scraping. If no Linear MCP server is connected, treat the ticket as
   unavailable and proceed with reduced certainty rather than guessing.
3. If GitHub issue references exist, fetch those issues/comments.
4. If no associated ticket is discoverable, continue with PR-only scope and note
   reduced certainty.

### 2.3 Derive review contract

Create a short internal contract:

- **In scope:** what the PR and ticket say should change
- **Out of scope:** what should not change
- **Success criteria:** what must be true for approval

Reject speculative assumptions. If scope is ambiguous, flag uncertainty in final
output.

## 3. Gather repo context

Before judging the diff, build a working picture of the repo's conventions, standards, and the tooling already available. Without this, "consistent with existing patterns" (§4.2) is just opinion. This is read-only — same constraint as the rest of the skill.

**Repository documentation** — read what's present, skip what isn't:

- Root-level: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `README.md`, `STYLEGUIDE.md`, `ARCHITECTURE.md`.
- `docs/` and `documentation/` trees — focus on entries about contributing, conventions, testing, architecture.
- AI-assistant rules: `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`, `.windsurfrules` — treat as authoritative when present.
- The nearest `CLAUDE.md` / `AGENTS.md` to each changed file (subdirectory rules can override repo-root rules).
- Lint/format/test config (`.eslintrc*`, `prettier*`, `pyproject.toml`, `tsconfig.json`, `Makefile`, `package.json` scripts) — surfaces required quality gates and naming conventions used as the baseline for findings.

**Available skills** — identify ones that fit the changed code's domain:

- Re-read the available-skills list already provided in this conversation; flag any whose description matches what the PR touches (e.g. `claude-api` for Anthropic SDK changes, `tdd` for test-heavy PRs, `simplify` for cleanup PRs).
- Also scan `~/.claude/skills/`, `~/.agents/skills/`, and `<repo>/.claude/skills/` for project-local skills.
- Use applicable skills' criteria to sharpen findings — but stay read-only and do not invoke any skill that mutates state.

If repo docs and the PR materially conflict, the conflict is itself a finding (Critical or Suggestion depending on severity).

## 4. Analyze code changes with surrounding context

### 4.1 Read changed files

Use:

```bash
gh pr diff "$PR_REF"
```

and/or file-level APIs to identify changed paths and hunks.

### 4.2 Read nearby code beyond hunks

For each changed region, inspect surrounding functions/modules to evaluate:

- behavioral correctness
- invariants and edge cases
- consistency with existing patterns
- API and contract impact
- security and performance implications

Do not limit analysis to exact diff lines.

### 4.3 Prioritize evidence-backed findings

Only surface findings when supported by concrete evidence from code behavior,
tests, contracts, or runtime implications.

Suppress low-value noise and stylistic churn unless it meaningfully affects
maintainability or correctness.

## 5. Run tests claimed by the PR (read-only execution)

Identify tests/commands explicitly claimed in PR description (e.g. "Tests run",
checklist, pasted commands).

Then:

1. Run those commands when safe and available.
2. If a command is missing in this environment, report it as "not runnable here"
   instead of guessing.
3. Do not install dependencies or modify project files as part of this skill.
4. Optionally run minimal adjacent checks only when directly relevant to a
   discovered risk.

Record pass/fail plus key error snippets for failed commands.

## 6. Algorithmic analysis pass

A separate read-only sweep over the diff for time/space complexity issues. **Informational by default** — algorithmic findings never alone move the verdict to `REQUEST CHANGES`. A `high`-severity finding may be promoted into `Critical` or `Suggestions` only when it meets the standard evidence bar in §4.3 (concrete user/system impact, not theoretical).

Run the diff against the PR base and walk each modified region:

```bash
gh pr diff "$PR_REF"
# or, if already on the branch:
git diff "$BASE_BRANCH"...HEAD
```

Decision flow per region:

```text
for each changed region:
  if not algorithmic in nature → skip (note as non-algorithmic)
  elif not on a hot path AND not over a large dataset → skip (trivial micro-optimization)
  else:
    assess time + space Big-O
    if optimal for the constraints → mark "Optimal"
    else → record opportunity + severity (high | medium | low)
```

"Algorithmic" means search, sort, graph traversal, dynamic programming, or loops with non-trivial complexity. UI markup, configuration, copy changes, and simple field access are skipped explicitly.

For each non-skipped item, capture:

- **File / function:** path + symbol
- **Time / space complexity:** Big-O notation
- **Optimality verdict:** `Optimal` or `Can be optimized`
- **Opportunity:** concrete alternative (e.g. "binary search on already-sorted input")
- **Severity:** `high` (critical impact), `medium` (meaningful), `low` (minor)
- **Notes:** caller assumptions, dataset size, hot-path evidence

Severity rubric:

- `high` — algorithm chosen is asymptotically wrong for the realistic input size (e.g. O(n²) in a request-path loop over user-scale data).
- `medium` — meaningful but bounded gain (e.g. O(n) → O(log n) on inputs that are already sorted upstream).
- `low` — micro-optimization on a non-hot path; record only if explicitly worth mentioning.

Output rendering rules (used by the §7 `Algorithmic Analysis` section). Pick the heading that matches the worst severity present in the findings:

- any `high` → `Algorithmic Analysis — Optimization Opportunities Found`
- any `medium` (no `high`) → `Algorithmic Analysis — Minor Opportunities`
- only `Optimal` items, or only `low` severity → `Algorithmic Analysis — Code Quality Good`
- no algorithmic code in the diff → `Algorithmic Analysis — No algorithmic code in diff`

Adapted from [`dotbrains/ticketsmith` — `docs/algorithmic-analysis.md`](https://github.com/dotbrains/ticketsmith/blob/main/docs/algorithmic-analysis.md).

## 7. Produce final review output

Return a well-formatted review with the exact section order below.

## Summary

- 3-6 bullets: scope, confidence, and overall recommendation
- Include explicit confidence level: High / Medium / Low

## Critical

List only must-fix issues that can cause:

- incorrect behavior
- data loss/corruption
- security vulnerabilities
- broken contracts/API behavior

For each item include:

- **What:** concise problem statement
- **Where:** file path + function/line context
- **Why it matters:** user/system impact
- **Suggested fix:** concrete direction

If none, write `None.`

## Suggestions

Important but non-blocking improvements that materially improve reliability,
clarity, or maintainability.

Use the same What/Where/Why/Suggested fix format.

If none, write `None.`

## Nits

Minor polish items only if worthwhile and low-noise.

If none, write `None.`

## Algorithmic Analysis

Heading text follows the §6 severity rubric. Then for each non-skipped item:

- **File:** `<path>` (`<function>`)
- **Time / Space:** `<O(...)>` / `<O(...)>` — `Optimal` or `Can be optimized` (severity)
- **Opportunity:** _(omit when `Optimal`)_
- **Notes:** _(constraints, dataset size, hot-path evidence)_

End with a one-line summary. If no algorithmic code was found in the diff, write only the heading and `No algorithmic code in diff.`

This section is informational — see §6 for promotion rules into `Critical` / `Suggestions`.

## Test Validation

- Commands claimed by PR
- Commands actually run
- Pass/fail outcomes
- Gaps (claimed but not runnable)

## Scope Alignment Check

- What matches the ticket/PR scope
- What appears out of scope
- Any missing expected changes

## Verdict

Choose exactly one:

- `APPROVE`
- `APPROVE WITH SUGGESTIONS`
- `REQUEST CHANGES`

Add one short rationale sentence.

---

## Cross-cutting rules

- **Read-only by default.** Never edit files, commit, push, or post PR comments.
- **Evidence over opinion.** Every finding must be grounded in code or test data.
- **High signal only.** Prefer fewer meaningful findings over exhaustive noise.
- **Context-aware review.** Always evaluate nearby code, not just changed lines.
- **Scope-first judging.** Review against stated ticket/PR intent, not preferences.
- **Linear via MCP, always.** All Linear ticket reads go through the configured Linear MCP server (e.g. `mcp__*Linear__get_issue`, `mcp__*Linear__list_comments`) — never the Linear REST API, the `linear` CLI, or HTML scraping. Read-only: do not invoke any Linear `save_*` MCP tool from this skill. If no Linear MCP is connected, treat the ticket as unavailable and note reduced certainty.
