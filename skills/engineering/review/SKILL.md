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
2. If a Linear-style ticket id exists, fetch ticket details and latest comments.
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

## 3. Analyze code changes with surrounding context

### 3.1 Read changed files

Use:

```bash
gh pr diff "$PR_REF"
```

and/or file-level APIs to identify changed paths and hunks.

### 3.2 Read nearby code beyond hunks

For each changed region, inspect surrounding functions/modules to evaluate:

- behavioral correctness
- invariants and edge cases
- consistency with existing patterns
- API and contract impact
- security and performance implications

Do not limit analysis to exact diff lines.

### 3.3 Prioritize evidence-backed findings

Only surface findings when supported by concrete evidence from code behavior,
tests, contracts, or runtime implications.

Suppress low-value noise and stylistic churn unless it meaningfully affects
maintainability or correctness.

## 4. Run tests claimed by the PR (read-only execution)

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

## 5. Produce final review output

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
