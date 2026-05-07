#!/usr/bin/env bash
set -euo pipefail

REPO="${DOTBRAINS_SKILLS_REPO:-${SKILLS_REPO:-dotbrains/skills}}"

say() {
  printf '%s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "$1 is required but not installed."
  fi
}

verify_node() {
  if ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)' >/dev/null 2>&1; then
    fail "Node.js 18 or newer is required."
  fi
}

need_cmd node
need_cmd npx
verify_node

say "Installing skills from ${REPO}..."
npx --yes skills@latest add "${REPO}" "$@"

say
say "Done."
