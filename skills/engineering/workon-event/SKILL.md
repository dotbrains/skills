---
name: workon-event
description: "Event-driven ticket driver — receives a single event (ticket-ready, PR comment, CI failure, base advanced, merge, close, convergence check) and dispatches to the matching handler. Same surface as /workon but reactive instead of polling. Triggers when the harness delivers an event payload referencing a Linear ticket."
version: 1.0.0
argument-hint: "<TICKET-ID> <EVENT-JSON>"
user-invocable: false
category: development
---

# Workon-event: event-driven ticket driver

Reactive sibling of the `workon` skill. The original `workon` runs a Setup pass and then schedules itself on a 5-minute timer; this skill is invoked **once per event** by an external dispatcher (a webhook router, a queue consumer, or a hook on Linear/GitHub state changes) and exits cleanly after handling that single event. There is no polling, no `sleep`, and no scheduled re-entry inside this skill.

This file is the **scaffold**:

- Event-input contract (§2)
- State-file shape (§3)
- Dispatch table that routes each event to a handler stub (§4)
- §4.1-equivalent merge-state routing — every PR-keyed event re-verifies PR state from GitHub before its handler runs, and re-routes to teardown if the PR is already merged or closed (§5)

The handler **bodies** are stubbed: each one logs the event it received and exits. Implementing real behavior is intentionally split into per-handler follow-up work — do not add behavior to the handler stubs in this file.

## 0. Parse argument

Inputs:

- `$1` (`<TICKET-ID>`): must match `[A-Z]+-\d+`. If missing or malformed, abort with a short error.
- `$2` (`<EVENT-JSON>`): a single JSON object matching the event-input contract in §2. Exactly one of three forms — the dispatcher picks one and supplies `$2` accordingly:
  1. **Literal JSON string.** `$2` is the raw JSON (e.g. `{"type":"pr-comment",...}`).
  2. **Path to a JSON file.** `$2` is a filesystem path that exists and contains the JSON object.
  3. **Stdin.** `$2` is the literal single-character `-`, in which case the JSON is read from stdin until EOF.

  `$2` is always required; missing or empty `$2` must fail. The empty string is **not** a valid signal for "use stdin" — only `-` is. If `$2 == "-"` and stdin is empty or not valid JSON, fail. If `$2` is non-empty and is neither valid JSON nor an existing file path, fail.

Both inputs are required. The skill never infers the event type from the ticket; the dispatcher tells us what happened.

**Ticket-ID consistency check.** After the JSON is parsed but **before** state is loaded or any handler dispatch, the skill must verify `event.ticketId == $1`. A mismatch indicates a dispatcher bug or an unsafe manual invocation: continuing would load/save state under one ticket while processing event data for another, corrupting the idempotency record on both sides. On mismatch, emit a single `result: "validation-error"` log line (see §6) naming both IDs and exit non-zero. Do not load state, do not dispatch.

## 1. Scope of this scaffold

This skill is deliberately small. The scaffold ships the contract + dispatch + routing only — every handler body in this file is a stub that emits one structured log line and returns. Real behavior for each handler (Setup, base-advanced resolution, CI failure, PR-comment processing, convergence, teardown) lands in follow-up work that ports the corresponding section of `skills/engineering/workon/SKILL.md`. The scaffold is invocable end-to-end before that work lands — invocations log "received event X for ticket Y" and exit zero.

The §9 reference table at the bottom of this file maps each `workon` section to the event(s) and handler(s) that subsume it.

## 2. Event-input contract

The dispatcher passes a single event per invocation. Every event is a JSON object with this top-level shape:

```json
{
  "type": "<event-type>",
  "ticketId": "PROJ-123",
  "ts": "2026-05-05T22:30:00Z",
  "payload": { "...": "event-specific fields" }
}
```

Required fields on every event:

| Field | Type | Notes |
| --- | --- | --- |
| `type` | string | Non-empty. Recognized values are listed in the taxonomy table below; any other non-empty string passes top-level validation and routes to the `unknown` handler (see Validation rule below). |
| `ticketId` | string | Linear identifier, e.g. `PROJ-123`. Must match `[A-Z]+-\d+`. |
| `ts` | string | RFC 3339 / ISO 8601 timestamp of when the event was emitted. Used for ordering and idempotency. |
| `payload` | object | Event-specific fields (see per-event sections). May be an empty object for events with no extra context. |

### Event taxonomy

The taxonomy covers every phase the original `workon` skill drives — Setup (§3), Watch (§4.1–§4.5), and Teardown (§5).

| Event `type` | Source trigger | Phase served | Handler (this file) |
| --- | --- | --- | --- |
| `ticket-ready` | Linear ticket marked groomed / ready-for-work | Setup | `handle_ticket_ready` |
| `pr-comment` | GitHub PR issue-comment or review-comment created | Watch §4.3 | `handle_pr_comment` |
| `pr-push` | A new commit landed on the PR branch | Watch (commit-time bookkeeping) | `handle_pr_push` |
| `pr-ci-failure` | Required GitHub Actions check turned red | Watch §4.4 | `handle_pr_ci_failure` |
| `pr-base-advanced` | The PR's base branch advanced past its merge-base (whether or not a conflict materialized) | Watch §4.2 | `handle_pr_base_advanced` |
| `pr-merged` | PR `state == "MERGED"` | Teardown §5 | `handle_pr_merged` |
| `pr-closed` | PR `state == "CLOSED"` and not merged | Teardown §5 | `handle_pr_closed` |
| `convergence-check` | Periodic tick from the dispatcher (e.g. every 5 min while a PR is open) | Watch §4.5 | `handle_convergence_check` |

### Per-event payload shapes

`ticket-ready` — no extra fields required. The handler will pull the ticket body itself via the Linear MCP.

```json
{ "type": "ticket-ready", "ticketId": "PROJ-123", "ts": "...", "payload": {} }
```

All `pr-*` and `convergence-check` events carry enough PR identity to look the PR up without re-deriving it from state:

```json
{
  "type": "pr-comment",
  "ticketId": "PROJ-123",
  "ts": "2026-05-05T22:30:00Z",
  "payload": {
    "prNumber": 123,
    "repoSlug": "owner/repo",
    "commentId": 9876543210,
    "commentKind": "issue|review",
    "author": "chatgpt-codex-connector",
    "createdAt": "2026-05-05T22:29:58Z"
  }
}
```

| Event | Required `payload` fields | Optional |
| --- | --- | --- |
| `pr-comment` | `prNumber`, `repoSlug`, `commentId`, `commentKind` (`"issue"` or `"review"`), `author`, `createdAt` | thread/body fields the dispatcher already has on hand |
| `pr-push` | `prNumber`, `repoSlug`, `sha`, `committedAt` | `pusher` |
| `pr-ci-failure` | `prNumber`, `repoSlug`, `checkRunId`, `checkName`, `conclusion` | `runUrl` |
| `pr-base-advanced` | `prNumber`, `repoSlug` | `mergeStateStatus` |
| `pr-merged` | `prNumber`, `repoSlug`, `mergedAt` | `mergedBy`, `mergeCommitSha` |
| `pr-closed` | `prNumber`, `repoSlug`, `closedAt` | `closedBy` (not exposed by `gh pr view --json`; the §5 pre-check leaves it absent on rerouted payloads — fetch via `gh api repos/.../issues/<n>/events` if needed) |
| `convergence-check` | `prNumber`, `repoSlug` | — |

**Validation rule.** Validation is split into two layers, in this order:

1. **Top-level shape (always enforced).** The event must be a JSON object carrying all four top-level fields — `type`, `ticketId`, `ts`, `payload` — with `type` and `ticketId` non-empty strings, `ts` a non-empty string, and `payload` an object. `type` is **not** checked against the known taxonomy at this stage: any non-empty string passes.
2. **Per-type payload shape (only when `type` is a known taxonomy value).** When `event.type` matches one of the rows below, the listed `payload` fields must also be present. Unknown `type` values skip this layer entirely so the dispatcher can route them to `handle_unknown` and emit the `result: "unknown"` line promised in §6.

| Event `type` | Required `payload` fields enforced at validation time |
| --- | --- |
| `ticket-ready` | (none beyond top-level) |
| `pr-comment` | `prNumber`, `repoSlug`, `commentId`, `commentKind`, `author`, `createdAt` |
| `pr-push` | `prNumber`, `repoSlug`, `sha`, `committedAt` |
| `pr-ci-failure` | `prNumber`, `repoSlug`, `checkRunId`, `checkName`, `conclusion` |
| `pr-base-advanced` | `prNumber`, `repoSlug` |
| `pr-merged` | `prNumber`, `repoSlug`, `mergedAt` |
| `pr-closed` | `prNumber`, `repoSlug`, `closedAt` |
| `convergence-check` | `prNumber`, `repoSlug` |

A missing field at either layer emits a single `result: "validation-error"` log line (see §6) naming the missing field, exits non-zero, and writes no state. An unknown `type` value is **not** a validation error — it passes validation, reaches the dispatch table, falls through to `handle_unknown`, and emits the `result: "unknown"` line. This split guarantees that malformed events surface as `validation-error` while unrecognized event types surface as `unknown`, matching the line-count contract in §6.

Validation runs **before** the merge-state pre-check in §5, so a malformed event never causes a `gh pr view` call. An unknown `type` likewise skips the §5 pre-check — there is no PR-keyed routing decision to make for an event whose type the dispatcher doesn't recognize, and the per-type payload contract that would supply `prNumber` / `repoSlug` was not enforced.

## 3. State-file shape

Location: `~/.claude/workon-event/<TICKET-ID>.json`. The directory mirrors the original `workon` skill's `~/.claude/workon/` layout but is deliberately separate so the two skills can run side-by-side without trampling each other during the migration.

```json
{
  "ticketId": "PROJ-123",
  "worktreePath": "/absolute/path/to/worktree",
  "branchName": "feat/...",
  "baseBranch": "main",
  "repoSlug": "owner/repo",
  "prNumber": 123,
  "phase": "setup|watch|teardown",
  "convergenceCommentPosted": false,
  "lastHandledEventTs": null,
  "lastHandledEventType": null
}
```

Field notes:

- `phase` is informational only — this skill does not branch on it. The dispatcher decides which event to send; the handler executes. `phase` is maintained so the original `workon` view of the world still reads cleanly.
- `lastHandledEventTs` / `lastHandledEventType` are for idempotency: if the dispatcher delivers the same event twice (`ts` and `type` match what was last handled for this ticket), handlers may no-op. The scaffold records these on every successful dispatch but does not yet enforce de-duplication — that decision is left to the per-handler implementations.
- The state file is a **cache**. GitHub and Linear are the sources of truth. Every handler that needs PR or ticket state re-reads it from the API rather than trusting the cache.

If the file does not exist, the skill creates the directory and writes a default skeleton with `phase: "setup"` and null PR fields before dispatching. This first-time write is **deferred until after** the §5 pre-check guards have passed (see §4 "Pre-handler steps") so that rejection paths — `validation-error`, `unknown`, `pre-check-error`, and `stale` — never leave a state file behind for a first-time ticket. The unknown-type path short-circuits to `log_unknown` and exits before `load_or_create_state` runs at all; the other rejection paths exit between validation and state load. State load happens immediately before handler invocation, never before.

## 4. Dispatch table

Pseudocode for the top-level body of the skill. **All handler bodies are stubs in the scaffold** — they log and return. The merge-state pre-check in §5 runs before any handler that isn't `ticket-ready`.

The post-handler state-write block (`lastHandledEvent*` + `save_state`) is **mandatory on every dispatched code path**, including re-routed ones. Returning early from a re-route without writing state breaks the idempotency contract in §3 and §7 — the next invocation would treat the event as never handled and could re-run teardown on every retry.

When a re-route flips the effective event type (e.g. `pr-comment` → `pr-merged`), the downstream handler still expects the **payload invariants** for the *new* type to hold (see §2: `pr-merged` requires `payload.mergedAt`, `pr-closed` requires `payload.closedAt`). The original event payload doesn't carry those fields. Before invoking the rerouted handler, the dispatch loop synthesizes a payload that satisfies the destination contract, using fields it already fetched from `gh pr view` for the §5 pre-check. The original event is preserved (for the `rerouted` log line and for `state.lastHandledEvent*`), but the value passed into the rerouted handler is the synthesized event.

**Pre-handler steps.** Validate the event (§2), enforce ticket-ID consistency between `$1` and `event.ticketId` (§0), short-circuit unknown event types (emit `result: "unknown"` and exit), then run the §5 pre-check guards (`pre-check-error`, `stale`, re-route routing). State load/create is deferred until **after** all of those guards pass — it is the last step before invoking a handler. This ordering matters because the `validation-error`, `unknown`, `pre-check-error`, and `stale` outcomes must all leave the state file untouched, and `load_or_create_state` is a disk write for first-time tickets: an early call would write the default skeleton (§3) before the guards rejected the event, mutating disk state on paths the contract says write none. The §0 mismatch case and the unknown-type short-circuit are bounded the same way for the same reason.

**Merge-state pre-check.** For every PR-keyed event (everything except `ticket-ready`), `gh pr view` is called against `payload.repoSlug` / `payload.prNumber` with the `--json` field set defined in §5 — `state`, `mergeable`, `mergeStateStatus`, `mergedAt`, `mergedBy`, `mergeCommit`, `closedAt`. (`gh pr view --json` does not expose `closedBy`; see §5 for how callers obtain closer identity.) If the call itself fails (non-zero exit, network outage, PR-not-found, JSON parse failure), the pre-check emits a single `result: "pre-check-error"` line, exits non-zero, and writes no state — see "`gh pr view` failure handling" below. If the call succeeds: when the PR is `MERGED` and the event is not `pr-merged`, dispatch is re-routed to `handle_pr_merged`; when the PR is `CLOSED` (not merged) and the event is not `pr-closed`, dispatch is re-routed to `handle_pr_closed` — including the case where the original event type was `pr-merged`, since GitHub is the source of truth and a closed-not-merged PR must run the closed-without-merge teardown. When the PR is `OPEN` and the event is `pr-merged` or `pr-closed`, the pre-check rejects the event as stale: no handler runs, no state is written, and a single `result: "stale"` line is emitted. A re-route emits the `rerouted` log line first, before invoking the downstream handler (see §6).

**Synthesized payload on re-route.** The `pr-merged` and `pr-closed` payload contracts in §2 require `mergedAt` and `closedAt` respectively, and the originating event (e.g. a `pr-comment`) does not carry those fields. The dispatch loop builds a payload that satisfies the destination contract from the `gh pr view` result already in hand: `mergedAt` (required), `mergedBy` (optional), and `mergeCommitSha` (optional, sourced from `mergeCommit.oid` **only when `mergeCommit` is non-null**) for `pr-merged`; `closedAt` (required) for `pr-closed`. `mergeCommitSha` is conditional because `gh pr view --json mergeCommit` returns `null` for PRs whose merge mode does not produce a stable merge commit object (and for not-yet-merged PRs); a blind `mergeCommit.oid` dereference would crash before the handler runs and before state is saved, causing the dispatcher to retry the same event indefinitely. When `pr_view.mergeCommit` is null the synthesizer simply omits `mergeCommitSha` from the payload, consistent with its optional status in §2. `closedBy` is intentionally **not** synthesized — `gh pr view --json` does not expose a `closedBy` field, so it stays optional on `pr-closed` (§2) and absent from the synthesized payload. Handlers that need closer identity fetch it separately (see §5). The handler receives the synthesized event; the *original* event is what gets recorded on `state.lastHandledEvent*`, so duplicate-delivery detection keys off what the dispatcher actually sent.

**`gh pr view` failure handling.** The §5 pre-check is a network call and can fail for reasons unrelated to the event — auth outage, transient network error, the PR no longer exists (manually deleted / repo renamed), or GitHub returning a non-zero exit. None of these failure modes correspond to a routing decision, but they must still produce a structured outcome so the dispatcher can classify the result instead of seeing an unstructured crash. On any non-zero exit from the `gh pr view` call (or any failure to parse its JSON output), the dispatch loop emits a single `result: "pre-check-error"` log line (§6) carrying the original event's `eventType` and `eventTs` and a `note` identifying the failure (exit code, stderr summary, or PR-not-found marker), exits non-zero, and writes no state. State is intentionally not written so the dispatcher can re-deliver the same event after the underlying problem clears, on the same idempotency footing as the §5 stale-teardown guard.

**Post-handler bookkeeping is mandatory on every dispatched code path**, including re-routes. The state-write step records the original event's `(type, ts)` and runs before exit. Returning early from a re-route without writing state breaks the idempotency contract in §3 and §7 — the next invocation would treat the event as never handled and could re-run teardown on every retry. The stale-teardown guard and the `pre-check-error` guard are not dispatched paths: both exit before any handler runs and intentionally do **not** write state, so the dispatcher can re-deliver the same event after live PR state catches up (or after the API outage clears).

```
ticket_id = $1
event = parse_json($2)
validate_event(event)
require_equal(event.ticketId, ticket_id)
# State load is deferred until after the §5 pre-check guards. For a
# first-time ticket, load_or_create_state writes a default skeleton
# to ~/.claude/workon-event/<TICKET-ID>.json — running it before the
# pre-check would mutate disk on the stale and pre-check-error paths,
# which the contract says write no state. See "Pre-handler steps" above.

# Unknown event types reach this point because §2 validation only enforces
# the per-type payload contract for known types — an unrecognized type
# passes top-level shape validation and falls through to handle_unknown,
# which emits the result: "unknown" line required by §6. A bare
# DISPATCH_TABLE[type] would raise before logging, breaking the contract.
handler = DISPATCH_TABLE.get(event.type, handle_unknown)
dispatched_event = event

# Short-circuit unknown event types BEFORE load_or_create_state. Per §3
# and §7, the "unknown" outcome is a no-state-mutation rejection path —
# but load_or_create_state writes a default skeleton for first-time
# tickets, so falling through to the post-pre-check load below would
# create ~/.claude/workon-event/<TICKET-ID>.json on disk for a typo'd
# event type that was never actually handled. Emit the unknown line and
# exit before any state I/O happens.
if event.type not in DISPATCH_TABLE:
    log_unknown(ticket_id, event.ts, event.type, f"unhandled event type: {event.type}")
    exit 1

if event.type in PR_KEYED_EVENTS:
    # Single gh pr view call returns every field needed for both
    # the routing decision and the rerouted payload synthesis below.
    # See §5 for the full --json list. Any non-zero exit or JSON
    # parse failure from this call is reported as result:
    # "pre-check-error" without writing state, so the dispatcher
    # can safely re-deliver after the underlying problem clears.
    try:
        pr_view = gh_pr_view(event.payload.repoSlug, event.payload.prNumber)
    except GhPrViewError as err:
        log_pre_check_error(event, err)
        exit 1
    if pr_view.state == "MERGED" and event.type != "pr-merged":
        log_rerouted(event, "pr-merged")
        handler = handle_pr_merged
        # mergeCommitSha is optional in §2 and is only sourced from
        # pr_view.mergeCommit.oid when GitHub actually returned a
        # mergeCommit object. PRs whose merge mode does not produce
        # a stable merge commit (and not-yet-merged PRs) get null
        # back; a blind dereference would crash before the handler
        # runs and trip the dispatcher into infinite retries.
        merged_payload = {
            "prNumber": event.payload.prNumber,
            "repoSlug": event.payload.repoSlug,
            "mergedAt": pr_view.mergedAt,
            "mergedBy": pr_view.mergedBy,
        }
        if pr_view.mergeCommit is not None:
            merged_payload["mergeCommitSha"] = pr_view.mergeCommit.oid
        dispatched_event = synthesize_event(
            type      = "pr-merged",
            ticketId  = event.ticketId,
            ts        = event.ts,
            payload   = merged_payload,
        )
    elif pr_view.state == "CLOSED" and event.type != "pr-closed":
        # GitHub is the source of truth: a CLOSED-not-merged PR routes to
        # handle_pr_closed even when the originating event was mislabeled
        # as pr-merged. The merged branch above only fires when GitHub
        # itself reports MERGED, so this elif cannot run for a truly
        # merged PR.
        log_rerouted(event, "pr-closed")
        handler = handle_pr_closed
        dispatched_event = synthesize_event(
            type      = "pr-closed",
            ticketId  = event.ticketId,
            ts        = event.ts,
            payload   = {
                "prNumber": event.payload.prNumber,
                "repoSlug": event.payload.repoSlug,
                "closedAt": pr_view.closedAt,
                # closedBy is intentionally omitted — gh pr view --json does
                # not expose it. See §5 for how downstream handlers fetch
                # closer identity when needed.
            },
        )
    elif pr_view.state == "OPEN" and event.type in ("pr-merged", "pr-closed"):
        # Stale teardown guard. The event claims the PR is merged or closed,
        # but GitHub reports it is still open — this is a delayed,
        # out-of-order, or post-reopen delivery. "GitHub is source of truth"
        # means we must not run destructive teardown (worktree cleanup,
        # state archival) against a live PR. Emit a structured `stale`
        # outcome and exit without dispatching to a handler. State is not
        # written for stale events: lastHandledEvent* must reflect handlers
        # that actually ran.
        log_stale(event, pr_view.state)
        exit 1

# All pre-check guards have passed (validation, ticket-ID consistency,
# pre-check-error, stale). Only now is it safe to touch the state file:
# load_or_create_state may write the default skeleton for a first-time
# ticket, and that disk write must not happen on any rejection path.
state = load_or_create_state(ticket_id)

handler(ticket_id, dispatched_event, state)

state.lastHandledEventTs   = event.ts
state.lastHandledEventType = event.type
save_state(state)
exit 0
```

### Dispatch table

```
DISPATCH_TABLE = {
  "ticket-ready":       handle_ticket_ready,
  "pr-comment":         handle_pr_comment,
  "pr-push":            handle_pr_push,
  "pr-ci-failure":      handle_pr_ci_failure,
  "pr-base-advanced":   handle_pr_base_advanced,
  "pr-merged":          handle_pr_merged,
  "pr-closed":          handle_pr_closed,
  "convergence-check":  handle_convergence_check,
}

PR_KEYED_EVENTS = {
  "pr-comment", "pr-push", "pr-ci-failure",
  "pr-base-advanced", "pr-merged", "pr-closed",
  "convergence-check",
}
```

### Logging helpers

The pseudocode below uses one helper per `result` value, and the mapping is part of the contract — a handler that picks the wrong helper silently misclassifies the outcome and breaks the §6 line-count table:

| Helper | `result` field value | Used by |
| --- | --- | --- |
| `log_event(...)` | `"stub"` | The eight in-taxonomy handler stubs (`handle_ticket_ready` … `handle_convergence_check`) |
| `log_unknown(...)` | `"unknown"` | `handle_unknown` only — never `log_event` |
| `log_rerouted(event, dest_type)` | `"rerouted"` | The §4 dispatch loop, before invoking a re-routed downstream handler |
| `log_stale(event, live_state)` | `"stale"` | The §4/§5 stale-teardown guard |
| `log_pre_check_error(event, err)` | `"pre-check-error"` | The §4/§5 pre-check failure guard |
| `log_validation_error(event, missing_field)` | `"validation-error"` | The §2 validation step (and §0 ticket-ID consistency check) |

`log_event` and `log_unknown` are intentionally distinct helpers, not the same function with a different first argument. Implementations must not collapse them: an unknown event running through `log_event` would emit `result: "stub"`, which the §6 line-count table reserves for handler stubs and which dispatcher retry/metrics logic would interpret as "successfully handled."

### Handler stubs

Each handler is a stub that emits one structured log line and returns. No side effects, no commits, no API writes. These signatures are the contract the per-handler implementations will fill in.

```
handle_ticket_ready(ticket_id, event, state):
    log_event("ticket-ready", ticket_id, event.ts, "stub: setup handler not yet implemented")

handle_pr_comment(ticket_id, event, state):
    log_event("pr-comment", ticket_id, event.ts,
              f"stub: pr-comment handler not yet implemented (commentId={event.payload.commentId})")

handle_pr_push(ticket_id, event, state):
    log_event("pr-push", ticket_id, event.ts,
              f"stub: pr-push handler not yet implemented (sha={event.payload.sha})")

handle_pr_ci_failure(ticket_id, event, state):
    log_event("pr-ci-failure", ticket_id, event.ts,
              f"stub: ci-failure handler not yet implemented (check={event.payload.checkName})")

handle_pr_base_advanced(ticket_id, event, state):
    log_event("pr-base-advanced", ticket_id, event.ts, "stub: base-advanced handler not yet implemented")

handle_pr_merged(ticket_id, event, state):
    log_event("pr-merged", ticket_id, event.ts, "stub: teardown handler not yet implemented")

handle_pr_closed(ticket_id, event, state):
    log_event("pr-closed", ticket_id, event.ts, "stub: closed-without-merge teardown not yet implemented")

handle_convergence_check(ticket_id, event, state):
    log_event("convergence-check", ticket_id, event.ts, "stub: convergence handler not yet implemented")

handle_unknown(ticket_id, event, state):
    # log_unknown — NOT log_event — so result is "unknown" per §6,
    # not "stub". Misclassifying as "stub" would tell the dispatcher
    # the unsupported event was successfully handled.
    #
    # In practice the §4 dispatch loop short-circuits unknown event
    # types before load_or_create_state runs, so this body is invoked
    # via the short-circuit's log_unknown call, not through the
    # handler signature above. The signature is preserved for
    # symmetry with the other stubs and for direct test invocation.
    log_unknown(ticket_id, event.ts, event.type, f"unhandled event type: {event.type}")
    exit 1
```

## 5. §4.1 merge-state routing

The original `workon` skill begins every Watch tick with §4.1 — re-verify PR state, route to teardown if merged or closed. In an event-driven world the same guarantee has to live at dispatch time, because individual events can lag PR-state transitions (a Codex comment event might arrive seconds after the PR was merged).

Rule: **every dispatch that touches a PR re-reads PR state from GitHub before the handler runs**, and re-routes when the PR is no longer open.

```bash
# Inputs: REPO and PR from event.payload
gh pr view "$PR" --repo "$REPO" \
  --json state,mergeable,mergeStateStatus,mergedAt,mergedBy,mergeCommit,closedAt
```

The `--json` list is the union of the routing inputs (`state`, `mergeable`, `mergeStateStatus`) and every field consumed by the rerouted-payload synthesis in §4: `mergedAt`/`mergedBy`/`mergeCommit` (the SHA is read from `mergeCommit.oid`, and only when `mergeCommit` is non-null — see §4) for `pr-merged`, and `closedAt` for `pr-closed`. Implementations must request all of these in a single call so the same `pr_view` result satisfies both the routing decision and the destination payload contract without a second round-trip.

`gh pr view --json` does not expose a `closedBy` field, so the pre-check cannot supply closer identity to the rerouted `pr-closed` payload. `closedBy` therefore stays optional in §2's `pr-closed` row, and the synthesis step in §4 omits it. Callers that need closer identity must fetch it via a separate call — `gh api repos/<owner>/<repo>/issues/<prNumber>/events` (look for the `closed` event's `actor.login`) or the equivalent `/issues/<prNumber>/timeline` endpoint — outside of this pre-check.

### `gh pr view` failure handling

The pre-check is a network call that can fail before any routing decision is possible: GitHub auth outage, transient network error, PR not found (manually deleted or repo renamed), `gh` itself returning a non-zero exit, or JSON parse failure on the response. These failures do not correspond to any routing branch and must not be silently swallowed — silence would let the dispatcher's retry policy treat the event as handled. The dispatch loop in §4 wraps the `gh pr view` call and, on any non-zero exit or JSON parse failure, emits a single `result: "pre-check-error"` log line carrying the original event's `eventType` and `eventTs` plus a `note` identifying the failure (exit code, stderr summary, or `pr-not-found` marker), exits non-zero, and writes **no** state. State is intentionally not written — on the same idempotency footing as the stale-teardown guard — so the dispatcher can re-deliver the same event after the underlying problem clears.

Routing decisions below assume the pre-check call succeeded; a failed pre-check exits before reaching them.

Routing decisions:

- `state == "MERGED"` and `event.type != "pr-merged"` → re-dispatch as `pr-merged` (handler: `handle_pr_merged`). Skip the original handler.
- `state == "CLOSED"` (not merged) and `event.type != "pr-closed"` → re-dispatch as `pr-closed` (handler: `handle_pr_closed`). Skip the original handler. A `pr-merged` event whose PR GitHub now reports as `CLOSED` (not merged) is routed here too: GitHub is the source of truth, so a mislabeled or out-of-order `pr-merged` against a closed-not-merged PR runs the closed-without-merge teardown rather than the merged teardown.
- `state == "OPEN"` and `event.type in {"pr-merged","pr-closed"}` → **stale-teardown guard.** The event claims the PR is merged or closed but GitHub reports it is still open (delayed or reopened-after-close delivery). Skip the teardown handler entirely and emit a single `result: "stale"` line (§6); exit non-zero. State is not written, so the dispatcher can re-deliver after live state catches up. Running teardown against a live PR would clean up the worktree and archive state for an active branch, which is the opposite of what `Watch §4.1` guarantees in the polling sibling.
- Otherwise — proceed to the original handler from the dispatch table.

The pre-check is skipped for `ticket-ready`, since no PR exists yet at that point.

The pre-check uses GitHub as the source of truth, **not** the cached `prNumber` / `phase` in the state file. The state file is updated to reflect the re-routed phase only after the teardown handler returns.

**Payload invariants on re-route.** The §2 contract requires `payload.mergedAt` for `pr-merged` and `payload.closedAt` for `pr-closed`. When a `pr-comment`/`pr-push`/`pr-ci-failure`/`pr-base-advanced`/`convergence-check` event is rerouted to teardown, its original payload doesn't carry those fields. The dispatch loop (§4) synthesizes a payload that meets the destination contract using values already returned by the `gh pr view` call that triggered the re-route — `mergedAt`/`mergedBy` for `pr-merged` (always), `mergeCommitSha` (only when `pr_view.mergeCommit` is non-null; see §4), and `closedAt` for `pr-closed`. `mergeCommitSha` stays optional in §2's `pr-merged` row precisely because GitHub returns `null` for `mergeCommit` on PRs whose merge mode does not produce a stable merge-commit object — the synthesizer omits the field rather than crashing on a null dereference. `closedBy` is **not** part of the synthesized payload because `gh pr view --json` does not expose it; it remains optional on `pr-closed` (§2), and a handler that needs closer identity must fetch it via a separate API call (e.g. `gh api repos/<owner>/<repo>/issues/<prNumber>/events`). Because the §5 `--json` list explicitly requests every other field in the same call, the synthesis step never needs a second round-trip to GitHub for routing. The rerouted handler receives the synthesized event; the *original* event is what gets recorded on `state.lastHandledEvent*` for idempotency.

### Done-when criteria for §5 routing

- Invoking the skill with any PR-keyed event payload, against a PR that GitHub reports as `MERGED`, must invoke `handle_pr_merged` and not the event's nominal handler.
- Invoking the skill with any PR-keyed event payload, against a PR that GitHub reports as `MERGED` whose `mergeCommit` field is null (e.g. squash/rebase merges where `gh pr view --json mergeCommit` returns `null`), must still invoke `handle_pr_merged` with a synthesized payload that omits `mergeCommitSha`, rather than crashing on a null dereference before the handler runs.
- Invoking the skill with any PR-keyed event payload, against a PR that GitHub reports as `CLOSED` (not merged), must invoke `handle_pr_closed` and not the event's nominal handler.
- Invoking the skill with a `pr-merged` or `pr-closed` event against a PR that GitHub reports as `OPEN` must skip dispatch entirely, emit `result: "stale"`, exit non-zero, and leave the state file untouched.
- Invoking the skill with any PR-keyed event payload when `gh pr view` exits non-zero or returns unparseable output must emit `result: "pre-check-error"`, exit non-zero, and leave the state file untouched (no handler runs, no `lastHandledEvent*` write).
- Invoking the skill against a first-time ticket (no existing `~/.claude/workon-event/<TICKET-ID>.json`) and exiting via `validation-error`, `unknown`, `pre-check-error`, or `stale` must leave the directory in its original state — no skeleton state file is written. State load/create is deferred until after the §5 pre-check guards have passed (and the unknown-type short-circuit fires before state load too); see §3 and §4 "Pre-handler steps."
- Invoking the skill with `ticket-ready` never performs the PR pre-check.

## 6. Logging contract

Every handler invocation emits exactly one JSON line on stdout. A re-route in §5 is logged with one *additional* line — the `rerouted` line — emitted *before* the downstream handler line. This is the only side effect the scaffold has, and it's how tests verify dispatch.

```json
{ "skill": "workon-event", "ticketId": "PROJ-123", "eventType": "pr-comment", "eventTs": "2026-05-05T22:30:00Z", "result": "stub", "note": "..." }
```

Required fields: `skill`, `ticketId`, `eventType`, `eventTs`, `result` (`"stub"`, `"rerouted"`, `"validation-error"`, `"unknown"`, `"stale"`, or `"pre-check-error"`), `note`.

### Line-count contract per invocation

The total number of JSON lines an invocation emits is fully determined by what happened:

| Outcome | Lines emitted | In order |
| --- | --- | --- |
| Validation failure (§2) | 1 | `result: "validation-error"` |
| Unknown event type | 1 | `result: "unknown"` |
| Pre-check error (§5) | 1 | `result: "pre-check-error"` (`gh pr view` non-zero exit, network/auth outage, PR-not-found, or JSON parse failure) |
| Stale teardown (§5) | 1 | `result: "stale"` (PR `OPEN` but event is `pr-merged`/`pr-closed`) |
| Normal dispatch (no re-route) | 1 | `result: "stub"` (the handler's line) |
| Re-routed dispatch (§5) | 2 | `result: "rerouted"` first, then `result: "stub"` for the re-routed handler |

When two lines are emitted, both carry the same `ticketId` and `eventTs` so consumers can pair them. The `rerouted` line's `eventType` is the *original* event type from the dispatcher; the `stub` line's `eventType` is the type the re-route resolved to (e.g. `pr-merged` or `pr-closed`). Consumers parsing the stream must treat `result: "rerouted"` as a routing record, not a handler outcome, and must not double-count it as a handled event.

The `pre-check-error` line's `eventType` is the *original* event type — the pre-check failed before any re-route decision was possible — and its `note` carries enough detail (exit code, stderr summary, or `pr-not-found` marker) for the dispatcher to classify the failure and decide whether to retry. No state is written for `pre-check-error`, on the same footing as `stale`, so re-delivery after the underlying problem clears is safe.

## 7. Idempotency and exit semantics

- Exactly one event handled per invocation. The skill exits zero on success, non-zero on validation errors, unknown event types, pre-check errors, or stale teardown rejections.
- No polling, no `sleep`, no scheduled re-entry. The dispatcher owns timing. `convergence-check` is a *normal event*, not an internal timer.
- State writes are last-step-only: state is only updated after the handler returns successfully, **including for re-routed dispatches** (see §4). A crash mid-handler leaves the previous state intact, so the dispatcher can safely retry. The unknown-type short-circuit (§4), the stale-teardown guard (§5), and the pre-check-error guard (§5) do **not** write state — all three exit before `load_or_create_state` runs (state load itself is deferred until after the §5 pre-check guards have passed; see §3 and §4 "Pre-handler steps"), so a first-time-ticket invocation that exits via `unknown`, `stale`, or `pre-check-error` leaves no state file behind. `lastHandledEvent*` therefore always reflects only handlers that actually ran.
- De-duplication on `(eventType, ts)` is left to per-handler implementations. The scaffold records the latest seen pair on `state.lastHandledEvent*` but does not skip duplicates. On a re-route, the **original** event's `(type, ts)` is what's recorded — not the synthesized destination type — so duplicate-delivery detection keys off what the dispatcher actually sent.
- Ticket-ID consistency: §0 enforces `event.ticketId == $1` before state load (state load is deferred until after the §5 pre-check guards anyway; see §4). A mismatch is a `validation-error` — no state file is touched, no handler runs.
- Live-state truth: the §5 pre-check uses GitHub as the source of truth on every PR-keyed event. Teardown events whose live PR state is `OPEN` are rejected as `stale` rather than dispatched, so destructive teardown never runs against a live PR.

## 8. Cross-cutting rules (carried over from `workon`)

These rules apply uniformly to all handlers and are reproduced here so the per-handler implementations don't have to re-derive them:

- **One push per handler invocation.** When a handler does push, it batches and pushes once at the end — never per-comment or per-fix.
- **Never force-push** unless explicitly requested.
- **State file is a cache.** Re-verify PR state, worktree presence, and ticket status from the source of truth at the start of every handler.
- **No speculative tickets.** If a handler surfaces work outside the current ticket's scope, it leaves an Open Questions note on the PR or Linear comment — it does not create new tickets.
- **No internal jargon in external artifacts.** PR descriptions, Linear comments, and commit messages describe what the change contains, not the team-local label for it.
- **Use project-preferred terminology in external artifacts.** Audit drafted text for outdated or team-specific terms before posting.

## 9. Reference

Original polling implementation, useful when filling in handler bodies: `skills/engineering/workon/SKILL.md`.

Section mapping:

| `workon` section | `workon-event` event(s) | Handler |
| --- | --- | --- |
| §3 Setup | `ticket-ready` | `handle_ticket_ready` |
| §4.1 merge-state | All PR events | Pre-dispatch routing in §5 above |
| §4.2 conflicts | `pr-base-advanced` | `handle_pr_base_advanced` |
| §4.3 Codex comments | `pr-comment` | `handle_pr_comment` |
| §4.4 CI failures | `pr-ci-failure` | `handle_pr_ci_failure` |
| §4.5 convergence | `convergence-check` (+ `pr-push` for bookkeeping) | `handle_convergence_check` |
| §5 Teardown | `pr-merged`, `pr-closed` | `handle_pr_merged`, `handle_pr_closed` |
