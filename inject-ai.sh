#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"
MODE="init"
DRY_RUN=false
APPLY=true
UPDATE_ACTION_SET=false
ACTION="init"
PACK_ARG=""
PACKS=()

usage() {
  cat <<'USAGE'
Usage:
  init-ai [--update] [--dry-run|--apply]
  init-ai add <pack> [--update] [--dry-run|--apply]

Packs:
  core              Cursor / Claude rules and project memory (default)
  python-quality    Ruff, Pyright, and python-uv rules
  pre-commit-hooks  Optional local Git hooks (auto-includes python-quality)
  ci-quality        GitHub Actions and GitLab quality CI (auto-includes python-quality)
  mlops-gpu         Docker, devcontainer, GitLab GPU train CI, and uv-bootstrap
  hf-space          Orphan-repo deploy to Hugging Face Space (git archive + force push)

Modes:
  init              Initialize selected packs in the current project.
  --update          Update selected managed template files.
  --dry-run         Preview changes without writing files.
  --apply           Apply changes. Required when --update is used.

Add packs manually in the order your project needs. See README for pack descriptions
and how to merge .gitlab-ci.yml when using both ci-quality and mlops-gpu.
USAGE
}

add_pack_once() {
  local pack="$1"
  local existing

  for existing in "${PACKS[@]:-}"; do
    if [[ "${existing}" == "${pack}" ]]; then
      return
    fi
  done

  PACKS+=("${pack}")
}

select_pack() {
  local pack="$1"

  case "${pack}" in
    core|python-quality|hf-space|mlops-gpu)
      add_pack_once "${pack}"
      ;;
    pre-commit-hooks)
      echo "Pack dependency: pre-commit-hooks also applies python-quality."
      add_pack_once "python-quality"
      add_pack_once "pre-commit-hooks"
      ;;
    ci-quality)
      echo "Pack dependency: ci-quality also applies python-quality."
      add_pack_once "python-quality"
      add_pack_once "ci-quality"
      ;;
    *)
      echo "Unknown pack: ${pack}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    add)
      ACTION="add"
      if [[ $# -lt 2 ]]; then
        echo "Please specify a pack after 'add'." >&2
        usage >&2
        exit 1
      fi
      PACK_ARG="$2"
      shift 2
      ;;
    --update)
      MODE="update"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      APPLY=false
      UPDATE_ACTION_SET=true
      shift
      ;;
    --apply)
      DRY_RUN=false
      APPLY=true
      UPDATE_ACTION_SET=true
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

if [[ "${MODE}" == "update" && "${UPDATE_ACTION_SET}" == false ]]; then
  echo "Please specify --dry-run or --apply when using --update." >&2
  exit 1
fi

case "${ACTION}" in
  init)
    select_pack core
    ;;
  add)
    select_pack "${PACK_ARG}"
    ;;
esac

print_header() {
  if [[ "${MODE}" == "update" ]]; then
    echo "Safely updating selected AI template packs..."
  else
    echo "Initializing selected AI template packs..."
  fi

  echo "Template source: ${SOURCE_DIR}"
  echo "Target project: ${TARGET_DIR}"
  echo "Selected packs: ${PACKS[*]}"

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

copy_tree_files() {
  local source_root="$1"
  local target_root="$2"
  local copy_mode="$3"
  local source_file
  local relative_path

  if [[ ! -d "${source_root}" ]]; then
    return
  fi

  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#${source_root}/}"

    case "${relative_path}" in
      .ruff_cache/*|__pycache__/*|*.pyc|*.pyo)
        continue
        ;;
    esac

    if [[ "${copy_mode}" == "managed" ]]; then
      copy_managed_file "${source_file}" "${target_root}/${relative_path}"
    else
      copy_if_missing "${source_file}" "${target_root}/${relative_path}"
    fi
  done < <(find "${source_root}" -type f -print0 | sort -z)
}

apply_pack() {
  local pack="$1"
  local pack_dir="${SOURCE_DIR}/templates/${pack}"

  if [[ ! -d "${pack_dir}" ]]; then
    echo "Pack directory not found: ${pack_dir}" >&2
    exit 1
  fi

  echo
  echo "Applying pack: ${pack}"
  copy_tree_files "${pack_dir}/managed" "${TARGET_DIR}" managed
  copy_tree_files "${pack_dir}/preserve" "${TARGET_DIR}" preserve
}

python_quality_pack_selected() {
  local pack

  for pack in "${PACKS[@]}"; do
    if [[ "${pack}" == "python-quality" ]]; then
      return 0
    fi
  done

  return 1
}

pre_commit_hooks_pack_selected() {
  local pack

  for pack in "${PACKS[@]}"; do
    if [[ "${pack}" == "pre-commit-hooks" ]]; then
      return 0
    fi
  done

  return 1
}

derive_project_name() {
  local project_name
  project_name="$(basename "${TARGET_DIR}")"
  project_name="${project_name#.}"
  project_name="${project_name//[^a-zA-Z0-9._-]/-}"

  if [[ -z "${project_name}" ]]; then
    project_name="project"
  fi

  printf '%s' "${project_name}"
}

ensure_pyproject_for_quality() {
  local project_name

  if [[ -f "${TARGET_DIR}/pyproject.toml" ]]; then
    return 0
  fi

  project_name="$(derive_project_name)"

  echo
  echo "No pyproject.toml found. CI and uv-based quality checks require one."
  if [[ -f "${TARGET_DIR}/requirements.txt" || -f "${TARGET_DIR}/setup.py" ]]; then
    echo "Legacy dependency files detected (requirements.txt / setup.py). They will be left unchanged."
    echo "Migrate runtime dependencies into pyproject.toml separately when you are ready."
  fi
  echo "Scaffolding a minimal pyproject.toml (name: ${project_name})..."

  if [[ "${DRY_RUN}" == true ]]; then
    printf '%-8s %s\n' "ADD" "pyproject.toml (minimal uv scaffold)"
    return 0
  fi

  uv init --name "${project_name}" --no-readme
}

install_python_quality_tools() {
  if ! python_quality_pack_selected; then
    return
  fi

  ensure_pyproject_for_quality

  echo
  if [[ "${DRY_RUN}" == true ]]; then
    printf '%-8s %s\n' "SKIP" "uv add --dev ruff pyright (dry-run)"
    return
  fi

  if [[ ! -f "${TARGET_DIR}/pyproject.toml" ]]; then
    echo "pyproject.toml is still missing. Skipping dev dependency installation." >&2
    return
  fi

  echo "Adding dev dependencies to pyproject.toml: ruff pyright..."
  uv add --dev ruff pyright

  echo
  echo "Dev deps added (ruff, pyright). Git hooks are a separate pack: init-ai add pre-commit-hooks"
  echo "In Dev Container / CI: use scripts/uv-bootstrap.sh for full runtime sync."
}

install_pre_commit_hooks_tools() {
  if ! pre_commit_hooks_pack_selected; then
    return
  fi

  ensure_pyproject_for_quality

  echo
  if [[ "${DRY_RUN}" == true ]]; then
    printf '%-8s %s\n' "SKIP" "uv add --dev pre-commit (dry-run)"
    printf '%-8s %s\n' "SKIP" "local git hooks (run scripts/setup-local-hooks.sh after apply)"
    return
  fi

  if [[ ! -f "${TARGET_DIR}/pyproject.toml" ]]; then
    echo "pyproject.toml is still missing. Skipping pre-commit dev dependency." >&2
    return
  fi

  echo "Adding dev dependency to pyproject.toml: pre-commit..."
  uv add --dev pre-commit

  echo
  echo "pre-commit added. Hooks are not installed automatically."
  echo "On the host (optional, no torch): bash scripts/setup-local-hooks.sh"
}

print_header

for pack in "${PACKS[@]}"; do
  apply_pack "${pack}"
done

install_python_quality_tools
install_pre_commit_hooks_tools

if [[ "${DRY_RUN}" == true ]]; then
  echo
  echo "Dry-run complete. Use --apply to apply the changes above."
else
  echo
  echo "AI template packs completed."
fi
