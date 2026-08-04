#!/usr/bin/env bash
set -euo pipefail

DEFAULT_INSTALL_DIR="${HOME}/.ai-coding-rules"
DEFAULT_REPO_URL="https://github.com/huangpenguin/ai-coding-rules.git"
INSTALL_DIR="${DEFAULT_INSTALL_DIR}"
REPO_URL="${DEFAULT_REPO_URL}"
CONFIGURE_ALIAS=true

usage() {
  cat <<'EOF'
Usage:
  install.sh [options]

Options:
  --dir <path>   Install directory (default: ~/.ai-coding-rules)
  --repo <url>   Git clone URL (default: GitHub HTTPS)
  --no-alias     Skip writing the init-ai shell wrapper
  -h, --help     Show this help message

Consumer machines (recommended):
  Install once with this script, then only run init-ai in projects.
  Do not edit or commit inside the install directory.

Examples:
  curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
  bash install.sh --dir ~/.ai-coding-rules
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --no-alias)
      CONFIGURE_ALIAS=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Expand a leading "~/" so wrappers store an absolute-ish home path.
if [[ "${INSTALL_DIR}" == "~/"* ]]; then
  INSTALL_DIR="${HOME}/${INSTALL_DIR#~/}"
elif [[ "${INSTALL_DIR}" == "~" ]]; then
  INSTALL_DIR="${HOME}"
fi

install_or_update_repo() {
  if [[ -d "${INSTALL_DIR}/.git" ]]; then
    echo "Updating existing template at ${INSTALL_DIR}..."
    git -C "${INSTALL_DIR}" pull --ff-only
  elif [[ -e "${INSTALL_DIR}" ]]; then
    echo "Path exists but is not a git repository: ${INSTALL_DIR}" >&2
    exit 1
  else
    echo "Cloning template into ${INSTALL_DIR}..."
    git clone "${REPO_URL}" "${INSTALL_DIR}"
  fi
}

# True when the managed init-ai() block exists with paths for the current INSTALL_DIR.
init_ai_wrapper_is_correct() {
  local rc_file="$1"
  local line
  local state="normal"
  local has_marker_start=false
  local has_marker_end=false
  local has_function=false
  local has_pull=false
  local has_inject=false

  if [[ ! -f "${rc_file}" ]]; then
    return 1
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${state}" in
      normal)
        if [[ "${line}" == "# AI coding rules template" ]]; then
          state="in_block"
          has_marker_start=true
        fi
        ;;
      in_block)
        if [[ "${line}" == "init-ai() {" || "${line}" == "init-ai()" ]]; then
          has_function=true
        fi
        if [[ "${line}" == "  git -C \"${INSTALL_DIR}\" pull --ff-only || return \$?" ]]; then
          has_pull=true
        fi
        if [[ "${line}" == "  bash \"${INSTALL_DIR}/inject-ai.sh\" \"\$@\"" ]]; then
          has_inject=true
        fi
        if [[ "${line}" == "# end AI coding rules template" ]]; then
          has_marker_end=true
          state="normal"
        fi
        ;;
    esac
  done < "${rc_file}"

  [[ "${has_marker_start}" == true && "${has_marker_end}" == true && "${has_function}" == true && "${has_pull}" == true && "${has_inject}" == true ]]
}

legacy_init_ai_alias_present() {
  local rc_file="$1"

  if [[ ! -f "${rc_file}" ]]; then
    return 1
  fi

  grep -q '^alias init-ai=' "${rc_file}"
}

# Remove legacy `alias init-ai=...` and any previous managed wrapper block.
strip_previous_init_ai() {
  local rc_file="$1"
  local tmp
  local line
  local state="normal"

  if [[ ! -f "${rc_file}" ]]; then
    return
  fi

  tmp="$(mktemp)"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${state}" in
      normal)
        if [[ "${line}" == "# AI coding rules template" ]]; then
          state="after_marker"
          continue
        fi
        if [[ "${line}" == "# end AI coding rules template" ]]; then
          continue
        fi
        if [[ "${line}" == alias\ init-ai=* ]]; then
          continue
        fi
        printf '%s\n' "${line}"
        ;;
      after_marker)
        if [[ "${line}" == "# end AI coding rules template" ]]; then
          state="normal"
          continue
        fi
        if [[ "${line}" == alias\ init-ai=* ]]; then
          state="normal"
          continue
        fi
        if [[ "${line}" == "init-ai() {" || "${line}" == "init-ai()" ]]; then
          state="in_function"
          continue
        fi
        if [[ -z "${line}" ]]; then
          continue
        fi
        # Unrecognized content after a lone marker: keep it.
        state="normal"
        printf '%s\n' "${line}"
        ;;
      in_function)
        if [[ "${line}" == "}" || "${line}" == "# end AI coding rules template" ]]; then
          state="normal"
          continue
        fi
        continue
        ;;
    esac
  done < "${rc_file}" > "${tmp}"

  mv "${tmp}" "${rc_file}"
}

write_init_ai_wrapper() {
  local rc_file="$1"

  if init_ai_wrapper_is_correct "${rc_file}" && ! legacy_init_ai_alias_present "${rc_file}"; then
    echo "init-ai wrapper already configured in ${rc_file}; skipping"
    return
  fi

  if [[ ! -f "${rc_file}" ]]; then
    touch "${rc_file}"
  fi

  strip_previous_init_ai "${rc_file}"

  {
    echo ''
    echo '# AI coding rules template'
    echo 'init-ai() {'
    echo "  git -C \"${INSTALL_DIR}\" pull --ff-only || return \$?"
    echo "  bash \"${INSTALL_DIR}/inject-ai.sh\" \"\$@\""
    echo '}'
    echo '# end AI coding rules template'
  } >> "${rc_file}"

  echo "Configured init-ai wrapper in ${rc_file}"
}

configure_alias() {
  # Keep bash and zsh logins consistent on multi-shell machines.
  write_init_ai_wrapper "${HOME}/.zshrc"
  write_init_ai_wrapper "${HOME}/.bashrc"
}

install_or_update_repo
INSTALL_DIR="$(cd "${INSTALL_DIR}" && pwd)"

if [[ "${CONFIGURE_ALIAS}" == true ]]; then
  configure_alias
fi

cat <<EOF

Template ready at: ${INSTALL_DIR}

This machine is a consumer install:
  - init-ai always runs: git -C ${INSTALL_DIR} pull --ff-only
  - then injects packs into the current project
  - do not edit or commit inside ${INSTALL_DIR}

Next steps:
  1. Reload your shell, or run: source ~/.zshrc  (or source ~/.bashrc)
  2. Remove any old editable clone of this repo on this machine
  3. cd into a project directory
  4. Run: init-ai

Force-refresh the template without injecting:
  curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash

Sync an already-injected project after template updates:
  init-ai --update --dry-run
  init-ai --update --apply
EOF
