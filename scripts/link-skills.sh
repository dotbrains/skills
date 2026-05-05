#!/usr/bin/env bash
set -euo pipefail

# Symlink every skill in this repo into the local Claude CLI's skills
# directory (~/.claude/skills/<name>). Existing non-symlink entries are
# replaced; existing symlinks are repointed.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

# Refuse to run if the destination is itself a symlink into this repo —
# that would pollute the working copy when re-linking.
if [ -L "$DEST" ]; then
  target="$(readlink "$DEST")"
  case "$target" in
    "$REPO"|"$REPO"/*)
      echo "Refusing to link: $DEST is a symlink into this repo ($target)." >&2
      exit 1
      ;;
  esac
fi

mkdir -p "$DEST"

cd "$REPO"
while IFS= read -r -d '' skill_md; do
  skill_dir="$(dirname "$skill_md")"
  skill_name="$(basename "$skill_dir")"
  link="$DEST/$skill_name"

  if [ -e "$link" ] && [ ! -L "$link" ]; then
    rm -rf "$link"
  fi

  ln -sfn "$REPO/$skill_dir" "$link"
  echo "linked $skill_name -> $REPO/$skill_dir"
done < <(find skills -name SKILL.md -not -path '*/node_modules/*' -print0)
