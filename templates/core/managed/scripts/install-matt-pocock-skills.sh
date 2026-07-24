#!/usr/bin/env bash
# Install Matt Pocock AI skills (mattpocock/skills) for Cursor + Claude Code.
# Idempotent. Requires Node.js (npx) and network access.
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"

if ! command -v npx >/dev/null 2>&1; then
  echo "ERROR: npx not found. Install Node.js to install mattpocock/skills." >&2
  exit 1
fi

cd "${TARGET_DIR}"

echo "Installing mattpocock/skills into ${TARGET_DIR} (Cursor + Claude Code)..."
npx --yes skills@latest add mattpocock/skills \
  -y \
  -a cursor \
  -a claude-code \
  -s '*' \
  --copy

echo
echo "Matt Pocock skills installed under .agents/skills/ (and .claude/skills/)."
echo "If docs/agents/ is missing, run /setup-matt-pocock-skills once in the agent."
