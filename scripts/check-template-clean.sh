#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

findings="$(
  find "${root_dir}/templates" \
    \( -type d -name '__pycache__' -o -type f -name '*.pyc' \) \
    -print | sort
)"

if [[ -n "${findings}" ]]; then
  printf 'Template hygiene check failed. Remove binary cache files from templates:\n' >&2
  printf '%s\n' "${findings}" | sed 's/^/  /' >&2
  exit 1
fi

echo "Template hygiene check passed."
