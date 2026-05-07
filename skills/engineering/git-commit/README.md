# /git-commit

Safe commit-message workflow using a temp file and `git commit -F`.

- Avoids shell quoting/injection pitfalls with multi-line commit messages
- Uses a deterministic sequence (touch → read → write → commit → cleanup)
- Pairs with `/commit-conventions` for message structure

## Install

```bash
npx skills@latest add dotbrains/skills
```

Or copy just this skill:

```bash
mkdir -p ~/.claude/skills/git-commit
curl -fsSL https://raw.githubusercontent.com/dotbrains/skills/main/skills/engineering/git-commit/SKILL.md \
  -o ~/.claude/skills/git-commit/SKILL.md
```

## Usage

Use whenever committing, especially when the message includes punctuation, multiple lines, or trailers.

## Files

- [`SKILL.md`](./SKILL.md) — canonical skill definition.
