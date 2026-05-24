#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"
MODE="init"
DRY_RUN=false
APPLY=true
UPDATE_ACTION_SET=false

usage() {
  cat <<'EOF'
Usage:
  init-ai
  init-ai --update --dry-run
  init-ai --update --apply

Modes:
  init                 Initialize rules in the current project.
  --update --dry-run   Preview safe updates without writing files.
  --update --apply     Apply safe updates to managed template files.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update)
      MODE="update"
      ;;
    --dry-run)
      DRY_RUN=true
      APPLY=false
      UPDATE_ACTION_SET=true
      ;;
    --apply)
      DRY_RUN=false
      APPLY=true
      UPDATE_ACTION_SET=true
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
  shift
done

if [[ "${MODE}" == "update" && "${UPDATE_ACTION_SET}" == false ]]; then
  echo "Please specify --dry-run or --apply when using --update." >&2
  exit 1
fi

print_header() {
  if [[ "${MODE}" == "update" ]]; then
    echo "Safely updating AI engineering rules for the current project..."
  else
    echo "Initializing AI engineering rules for the current project..."
  fi

  echo "Template source: ${SOURCE_DIR}"
  echo "Target project: ${TARGET_DIR}"

  if [[ "${DRY_RUN}" == true ]]; then
    echo "Mode: dry-run. Preview only; no files will be written."
  fi
}

same_file() {
  local source_file="$1"
  local target_file="$2"

  [[ -f "${target_file}" ]] && cmp -s "${source_file}" "${target_file}"
}

report_file() {
  local source_file="$1"
  local target_file="$2"
  local label="$3"
  local action="UPDATE"

  if [[ ! -e "${target_file}" ]]; then
    action="ADD"
  elif same_file "${source_file}" "${target_file}"; then
    action="SKIP"
  fi

  printf '%-8s %s\n' "${action}" "${label}"
}

copy_managed_file() {
  local source_file="$1"
  local target_file="$2"
  local label="${target_file#${TARGET_DIR}/}"

  report_file "${source_file}" "${target_file}" "${label}"

  if [[ "${DRY_RUN}" == true ]] || same_file "${source_file}" "${target_file}"; then
    return
  fi

  mkdir -p "$(dirname "${target_file}")"
  cp -f "${source_file}" "${target_file}"
}

copy_if_missing() {
  local source_file="$1"
  local target_file="$2"
  local label="${target_file#${TARGET_DIR}/}"

  if [[ -e "${target_file}" ]]; then
    printf '%-8s %s\n' "PRESERVE" "${label}"
    return
  fi

  printf '%-8s %s\n' "ADD" "${label}"

  if [[ "${DRY_RUN}" == true ]]; then
    return
  fi

  mkdir -p "$(dirname "${target_file}")"
  cp -f "${source_file}" "${target_file}"
}

copy_managed_tree() {
  local source_root="$1"
  local target_root="$2"
  local source_file
  local relative_path

  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#${source_root}/}"
    copy_managed_file "${source_file}" "${target_root}/${relative_path}"
  done < <(find "${source_root}" -type f -print0 | sort -z)
}

install_private_directory() {
  local source_readme="$1"
  local target_dir="$2"

  if [[ ! -d "${target_dir}" ]]; then
    printf '%-8s %s/\n' "ADD" "${target_dir#${TARGET_DIR}/}"
    if [[ "${DRY_RUN}" == false ]]; then
      mkdir -p "${target_dir}"
    fi
  else
    printf '%-8s %s/\n' "PRESERVE" "${target_dir#${TARGET_DIR}/}"
  fi

  copy_if_missing "${source_readme}" "${target_dir}/README.md"
}

install_dev_tools() {
  if [[ "${DRY_RUN}" == true ]]; then
    printf '%-8s %s\n' "SKIP" "uv add --dev ruff pyright pre-commit (dry-run)"
    printf '%-8s %s\n' "SKIP" "uv run pre-commit install (dry-run)"
    return
  fi

  if [[ -f "${TARGET_DIR}/pyproject.toml" ]]; then
    echo "Detected pyproject.toml. Installing dev dependencies: ruff pyright pre-commit..."
    uv add --dev ruff pyright pre-commit

    if [[ -d "${TARGET_DIR}/.git" ]]; then
      echo "Detected a Git repository. Installing the pre-commit hook..."
      uv run pre-commit install
    else
      echo "No .git directory found. Skipping Git hook installation."
    fi
  else
    echo "No pyproject.toml found. Skipping dev dependency installation."
    echo "pre-commit was not installed as a dev dependency. Skipping Git hook installation."
  fi
}

print_header

echo
echo "Syncing Cursor / Claude AI rules..."
copy_managed_tree "${SOURCE_DIR}/.cursor/rules" "${TARGET_DIR}/.cursor/rules"
copy_managed_file "${SOURCE_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md"
copy_managed_file "${SOURCE_DIR}/.cursorrules" "${TARGET_DIR}/.cursorrules"

echo
echo "Initializing project-private context directories..."
install_private_directory "${SOURCE_DIR}/.cursor/project-context/README.md" "${TARGET_DIR}/.cursor/project-context"
install_private_directory "${SOURCE_DIR}/.cursor/lessons-learned/README.md" "${TARGET_DIR}/.cursor/lessons-learned"
copy_if_missing "${SOURCE_DIR}/MEMORY-TEMPLATE.md" "${TARGET_DIR}/MEMORY.md"

echo
echo "Syncing GitHub and GitLab CI templates..."
copy_managed_tree "${SOURCE_DIR}/.github" "${TARGET_DIR}/.github"
copy_managed_tree "${SOURCE_DIR}/.gitlab" "${TARGET_DIR}/.gitlab"
copy_managed_file "${SOURCE_DIR}/.gitlab-ci.yml" "${TARGET_DIR}/.gitlab-ci.yml"

echo
echo "Syncing Docker / MLOps template files..."
copy_managed_file "${SOURCE_DIR}/Dockerfile" "${TARGET_DIR}/Dockerfile"
copy_managed_tree "${SOURCE_DIR}/.devcontainer" "${TARGET_DIR}/.devcontainer"
copy_managed_tree "${SOURCE_DIR}/docs" "${TARGET_DIR}/docs"
copy_if_missing "${SOURCE_DIR}/train.py" "${TARGET_DIR}/train.py"

echo
echo "Syncing Ruff / Pyright / pre-commit configuration..."
copy_managed_file "${SOURCE_DIR}/ruff.toml" "${TARGET_DIR}/ruff.toml"
copy_managed_file "${SOURCE_DIR}/pyrightconfig.json" "${TARGET_DIR}/pyrightconfig.json"
copy_managed_file "${SOURCE_DIR}/.pre-commit-config.yaml" "${TARGET_DIR}/.pre-commit-config.yaml"
copy_managed_file "${SOURCE_DIR}/.gitignore" "${TARGET_DIR}/.gitignore"

echo
install_dev_tools

if [[ "${DRY_RUN}" == true ]]; then
  echo
  echo "Dry-run complete. Use init-ai --update --apply to apply the changes above."
else
  echo
  echo "AI engineering rules completed."
fi
