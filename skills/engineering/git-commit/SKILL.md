---
name: git-commit
description: "Commits staged files using a temp-file commit message to avoid shell-substitution pitfalls. Triggers on any `git commit` invocation — especially when the message contains special characters, newlines, Co-Authored-By trailers, or multi-line bodies. Never use `git commit -m` with heredocs, `$()`, backticks, or inline strings."
version: 1.0.0
user-invocable: true
category: development
---

## Pattern

Write the commit message to a temp file, then use `git commit -F` to read it. This avoids all shell substitution, quoting, and injection issues.

**Never use:** `git commit -m "..."`, heredocs, `$()`, backticks, or `echo >` to write the message.

## Exact steps (in order)

1. **Stage files** (if not already staged):
   ```bash
   git add <file1> <file2> ...
   ```

2. **Touch the temp file** so the Read tool can open it:
   ```bash
   touch /tmp/commit_msg.txt
   ```

3. **Read the temp file** with the Read tool — required before Write will accept it:
   ```
   Read: /tmp/commit_msg.txt
   ```

4. **Write the message** with the Write tool (never echo/cat):
   ```
   Write: /tmp/commit_msg.txt
   ---
   feat: your commit title here

   Optional body paragraph.
   ```

5. **Commit**:
   ```bash
   git commit -F /tmp/commit_msg.txt
   ```

6. **Clean up**:
   ```bash
   rm /tmp/commit_msg.txt
   ```

## Message format

Follow the repo's [commit-conventions](../commit-conventions/SKILL.md):
- First line: `type: short description` (under 72 chars)
- Blank line, then optional body

## Example (full sequence)

```
Bash:   touch /tmp/commit_msg.txt
Read:   /tmp/commit_msg.txt
Write:  /tmp/commit_msg.txt  ←  content below
---
feat: extract shared serializer module

Moves shared text serialization into a focused module, keeping the
domain package centered on data models.
---
Bash:   git add packages/domain/src/index.ts packages/api/src/serializeText.ts
Bash:   git commit -F /tmp/commit_msg.txt
Bash:   rm /tmp/commit_msg.txt
```
