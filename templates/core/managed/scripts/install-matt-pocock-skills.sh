#!/usr/bin/env bash
# Install selected Matt Pocock skills into this project (not global).
# Requires Node.js (npx) and network access.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: bash scripts/install-matt-pocock-skills.sh <skill-name> [<skill-name> ...] | --all" >&2
  exit 2
fi

if [[ "$1" == "--all" ]]; then
  if [[ $# -ne 1 ]]; then
    echo "ERROR: --all cannot be combined with skill names." >&2
    exit 2
  fi
  SKILLS=('*')
else
  SKILLS=("$@")
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "ERROR: npx not found. Install Node.js to install mattpocock/skills." >&2
  exit 1
fi

echo "Installing ${SKILLS[*]} from mattpocock/skills into project $(pwd)..."
npx --yes skills@latest add mattpocock/skills \
  -y \
  -a cursor \
  -a claude-code \
  -s "${SKILLS[@]}" \
  --copy

echo
echo "Selected skills installed under .agents/skills/ and .claude/skills/."
