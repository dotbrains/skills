---
name: pr-monitor
description: "Monitors a GitHub pull request for AI review comments, GitHub Actions failures, and merge-readiness signals; applies scoped fixes, responds to bot threads, and stops once CI is green and Codex has approved the PR description with a thumbs-up reaction."
version: 2.0.0
argument-hint: "[pr-number | owner/repo#number | PR URL]"
user-invocable: true
category: development
---

Run one monitoring pass for a GitHub pull request. Each pass inspects unresolved AI review threads, GitHub Actions failures on the PR head SHA, and completion signals on the PR body. Apply small scoped fixes when warranted, reply to bot review threads, and stop once the PR is ready.

## What's available

All PR interaction uses the `gh` CLI plus local `git`:

- `gh pr view` - PR metadata, diff context, changed files, and head SHA
- `gh api graphql` - review threads and review-thread resolution
- `gh api repos/.../pulls/.../comments/.../replies` - replies to review comments
- `gh pr checks` - summary of PR check state
- `gh run view` - GitHub Actions run metadata and logs
- `gh api repos/.../issues/.../reactions` - reactions on the PR body
- `git` - fetch, checkout, commit, and push scoped fixes on the PR branch

## Common workflows

```text
/pr-monitor
```

Run a monitoring pass against the PR for the current branch.

```text
/pr-monitor 123
```

Run a monitoring pass against PR `#123` in the current repo.

```text
/pr-monitor owner/repo#123
```

Run a monitoring pass against a PR in another repo.

Only apply code fixes when the current working directory is a checkout of that target repo. Otherwise, inspect and summarize only, or stop and ask the user to switch into the correct checkout before making changes.

```text
/pr-monitor https://github.com/owner/repo/pull/123
```

Use an explicit PR URL when auto-detection is unreliable.

If the host supports recurring prompts or looped execution, offer to run the same monitoring pass every 5 minutes until the completion criteria are met.

## Monitoring pass

1. Resolve the PR reference.
   Accept a PR number, `owner/repo#number`, full URL, or the current branch PR. If the user gives only a number, derive `owner/repo` from `git remote get-url origin`.

   ```bash
   gh pr view <number> --repo <owner>/<repo> --json number,url
   gh api user --jq .login
   ```

   After parsing the user input, carry the resolved `<owner>`, `<repo>`, and `<number>` through every later `gh` command. Do not fall back to current-branch auto-detection once the user supplied an explicit PR reference.

2. Read PR state and intent.

   ```bash
   gh pr view <number> --repo <owner>/<repo> \
     --json title,body,state,url,headRefName,headRefOid,baseRefName
   ```

   If the PR is closed or merged, report that and stop.

3. Gather signals in parallel.
   - Review threads via GraphQL
   - PR diff and changed files
   - GitHub Actions status for the PR
   - Reactions on the PR body

4. Process actionable review threads.
5. Process actionable GitHub Actions failures.
6. Re-check completion criteria before offering another monitoring pass.

## Review-thread handling

Fetch review threads with GraphQL so each thread includes its node ID, resolution state, and full comment list:

```bash
gh api graphql -f query='query($after: String) {
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <number>) {
      reviewThreads(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          comments(first: 100) {
            pageInfo { hasNextPage endCursor }
            nodes {
              databaseId
              author { login }
              body
              path
              line
              originalLine
              outdated
              createdAt
            }
          }
        }
      }
    }
  }
}'
```

When processing review threads:

- Omit `after` on the first call (the nullable `$after` variable defaults to `null`). On subsequent pages, pass `-F after='<endCursor>'` with the cursor from `pageInfo.endCursor`.
- Paginate `reviewThreads` until thread-level `pageInfo.hasNextPage` is `false` before deciding there are no actionable bot threads left.
- Only evaluate the first comment in each thread. Treat later comments as replies.
- Paginate each thread's `comments` list until it is complete before deduplicating.
- Skip resolved threads.
- Skip any thread where you already replied.
- Treat any top-level author ending in `[bot]` as a bot reviewer. Also include obvious AI reviewer logins containing `codex`, `copilot`, `coderabbit`, or `sourcery`.

Classify each remaining thread:

- `fixed` - real issue, straightforward fix in scope for this PR
- `fixed-differently` - real issue, but the suggestion is not the best implementation
- `out-of-scope` - valid concern, not part of this PR's goal
- `pushback` - incorrect or unnecessary suggestion
- `stale` - already addressed, outdated, or file context no longer matches

For `fixed` and `fixed-differently`:

- Sync to the PR head branch before editing any files:
  ```bash
  git fetch origin <headRefName>
  git checkout <headRefName>
  git pull origin <headRefName>
  ```
- Fetch the current file from the PR head branch.
- Apply the smallest correct fix.
- Batch nearby fixes in the same file into one commit.

Reply to every processed thread:

- `fixed` - acknowledge the issue and cite the commit SHA
- `fixed-differently` - explain the alternative implementation and cite the commit SHA
- `out-of-scope` - acknowledge and defer to follow-up work
- `pushback` - explain why the current code is correct
- `stale` - explain that the code has already changed or the issue is no longer applicable

Resolve only `fixed`, `fixed-differently`, and `stale` threads.

## GitHub Actions handling

Only inspect GitHub Actions. External checks such as Buildkite are out of scope and should be reported with their details URL only.

Start with the PR check summary:

```bash
gh pr checks <number> --repo <owner>/<repo> \
  --json name,state,link,workflow,bucket
```

Then inspect failing or pending GitHub Actions runs tied to the current head SHA. Parse the run ID from the check link when needed, then fetch metadata and logs:

```bash
gh run view <run-id> --repo <owner>/<repo> --json name,workflowName,conclusion,status,url,event,headBranch,headSha
gh run view <run-id> --repo <owner>/<repo> --log
```

Classify each failing run:

- `fixable` - localized code, test, lint, or type issue with a clear fix
- `stale` - failure belongs to an older SHA or is already addressed on the current branch
- `report-only` - flaky, infra, auth, secret, quota, or runner problem
- `ask-first` - fixing it requires workflow edits, dependency updates, public API changes, or a broad refactor

For `fixable` failures:

- Sync to the PR head branch (same as for review-thread fixes) before editing any files.
- Use the log snippet plus PR diff context to make the smallest fix that addresses the failure.
- Commit and push the fix on the PR branch.
- Do not silently rerun workflows unless the user asks or rerunning is the only sane way to confirm a flaky recovery.

For `report-only` failures:

- Summarize the failing job, the likely cause, and the run URL.
- Do not claim the PR is blocked by code if the logs point to infrastructure.

## Completion criteria

Treat the PR as complete only when all of these are true on the current head SHA:

- No actionable bot review threads remain.
- No GitHub Actions checks are failing or pending.
- The PR body has a `+1` reaction from Codex.

For the reaction check, inspect the PR body reactions:

```bash
gh api --paginate repos/<owner>/<repo>/issues/<number>/reactions
```

Prefer an exact login match for `openai-codex[bot]` when present. If the repository uses a different Codex bot login, accept a `+1` from a bot login containing `codex`.

If the completion criteria are met, report that monitoring is complete and do not offer another monitoring pass.

If they are not met, summarize what is still outstanding. If the host supports recurring prompts or loops, offer to check again in 5 minutes.

## When to stop and ask the user

- The fix is larger than about 30 lines or touches unrelated files.
- Two review comments or failing checks imply conflicting fixes.
- The change requires a new dependency, workflow file edit, public API change, or test weakening.
- The PR targets `main` or `master` directly and you are about to push.
- The PR is in another repo and the current directory is not a checkout of that repo; inspect only or ask the user to switch before making code changes.
- More than 10 actionable items remain; summarize first.
- `git push` fails or branch protection blocks the update.

## Error handling

- `gh auth status` fails - tell the user to run `gh auth login`.
- PR auto-detection fails - ask for `123`, `owner/repo#123`, or a PR URL.
- PR lookup returns 404 - confirm the repo and access permissions.
- File fetch returns 404 - treat the review thread as `stale` if the file was renamed or removed.
- GitHub Actions logs are unavailable - report the run URL and that the logs could not be fetched.
- A failing check is still in progress - report it as pending, not fixable.
- GitHub API rate limits are hit - report the limit and suggest a slower monitoring cadence.
