#!/usr/bin/env bash
# Install Matt Pocock AI skills (mattpocock/skills) into THIS project (not global).
# Writes .agents/skills/ and .claude/skills/ under the target directory.
# Idempotent. Requires Node.js (npx) and network access.
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"

if ! command -v npx >/dev/null 2>&1; then
  echo "ERROR: npx not found. Install Node.js to install mattpocock/skills." >&2
  exit 1
fi

cd "${TARGET_DIR}"

echo "Installing mattpocock/skills into project ${TARGET_DIR} (Cursor + Claude Code; project-local, not -g)..."
npx --yes skills@latest add mattpocock/skills \
  -y \
  -a cursor \
  -a claude-code \
  -s '*' \
  --copy

echo
echo "Matt Pocock skills installed under this project's .agents/skills/ (and .claude/skills/)."
echo "If docs/agents/ is missing, run /setup-matt-pocock-skills once in the agent."
