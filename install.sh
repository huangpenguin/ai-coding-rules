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
  --no-alias     Skip writing the init-ai shell alias
  -h, --help     Show this help message

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

append_alias_if_missing() {
  local rc_file="$1"
  local alias_line="alias init-ai=\"bash ${INSTALL_DIR}/inject-ai.sh\""

  if [[ ! -f "${rc_file}" ]]; then
    touch "${rc_file}"
  fi

  if grep -Fq 'alias init-ai=' "${rc_file}"; then
    echo "Alias already present in ${rc_file}"
    return
  fi

  {
    echo ''
    echo '# AI coding rules template'
    echo "${alias_line}"
  } >> "${rc_file}"

  echo "Added init-ai alias to ${rc_file}"
}

configure_alias() {
  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"

  case "${shell_name}" in
    zsh)
      append_alias_if_missing "${HOME}/.zshrc"
      ;;
    bash)
      append_alias_if_missing "${HOME}/.bashrc"
      ;;
    *)
      append_alias_if_missing "${HOME}/.bashrc"
      echo "Unknown shell '${shell_name}'. Added alias to ~/.bashrc only."
      ;;
  esac
}

install_or_update_repo

if [[ "${CONFIGURE_ALIAS}" == true ]]; then
  configure_alias
fi

cat <<EOF

Template ready at: ${INSTALL_DIR}

Next steps:
  1. Reload your shell, or run: source ~/.bashrc  (or source ~/.zshrc)
  2. cd into a project directory
  3. Run: init-ai

To update this template later (do not re-run curl install):
  cd ${INSTALL_DIR}
  git pull

Then sync an existing project:
  init-ai --update --dry-run
  init-ai --update --apply
EOF
