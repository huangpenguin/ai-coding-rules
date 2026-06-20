#!/usr/bin/env bash
set -euo pipefail

SOURCE_REPO=""
DRY_RUN=false
DEPLOY_BRANCH="${DEPLOY_BRANCH:-main}"
DEPLOY_COMMIT_PREFIX="${DEPLOY_COMMIT_PREFIX:-Deploy}"
DEPLOY_REMOTE_NAME="${DEPLOY_REMOTE_NAME:-space}"

usage() {
  cat <<'EOF'
Deploy a clean, history-free Git snapshot to a Hugging Face Space.

Usage:
  deploy-hf-space.sh [--dry-run]

Environment:
  HF_SPACE_GIT_URL     Required. HTTPS git URL for the Space repo.
  HF_TOKEN             Optional. Injected when the URL has no embedded credentials.
  HF_USERNAME          Optional. Defaults to "oauth2" when HF_TOKEN is used.
  DEPLOY_EXCLUDE_PATHS Optional. Whitespace-separated repo-relative paths to delete
                       from the export before push (e.g. sample_docs/public/legacy).
  DEPLOY_BRANCH        Target branch (default: main).
  DEPLOY_COMMIT_PREFIX Commit message prefix (default: Deploy).
  GITHUB_SHA           Optional. Used in the deploy commit message; defaults to HEAD.

Local config (optional, not committed):
  deploy-hf-space.env  Sourced from the repository root if present.

Examples:
  export HF_SPACE_GIT_URL="https://huggingface.co/spaces/you/your-space"
  export HF_TOKEN="hf_..."
  export DEPLOY_EXCLUDE_PATHS="sample_docs/public/legacy data/cache"
  bash scripts/deploy-hf-space.sh --dry-run
  bash scripts/deploy-hf-space.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
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

SOURCE_REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${SOURCE_REPO}" ]]; then
  echo "deploy-hf-space.sh must run inside a Git repository." >&2
  exit 1
fi

if [[ -f "${SOURCE_REPO}/deploy-hf-space.env" ]]; then
  # shellcheck disable=SC1091
  source "${SOURCE_REPO}/deploy-hf-space.env"
fi

if [[ -z "${HF_SPACE_GIT_URL:-}" ]]; then
  echo "HF_SPACE_GIT_URL is required." >&2
  usage >&2
  exit 1
fi

SOURCE_SHA="${GITHUB_SHA:-$(git -C "${SOURCE_REPO}" rev-parse HEAD)}"
deploy_dir="$(mktemp -d)"

cleanup() {
  rm -rf "${deploy_dir}"
}
trap cleanup EXIT

echo "Exporting ${SOURCE_SHA} from ${SOURCE_REPO}..."
git -C "${SOURCE_REPO}" archive HEAD | tar -x -C "${deploy_dir}"

if [[ -n "${DEPLOY_EXCLUDE_PATHS:-}" ]]; then
  for local_path in ${DEPLOY_EXCLUDE_PATHS}; do
    target_path="${deploy_dir}/${local_path}"
    if [[ -e "${target_path}" ]]; then
      echo "Excluding ${local_path}"
      rm -rf "${target_path}"
    else
      echo "Exclude path not present in export (skipped): ${local_path}"
    fi
  done
fi

space_url="${HF_SPACE_GIT_URL}"
if [[ -n "${HF_TOKEN:-}" && "${space_url}" != *"@"* ]]; then
  space_url="${HF_SPACE_GIT_URL/https:\/\//https://${HF_USERNAME:-oauth2}:${HF_TOKEN}@}"
fi

if [[ "${DRY_RUN}" == true ]]; then
  echo
  echo "Dry-run complete."
  echo "  Source SHA:     ${SOURCE_SHA}"
  echo "  Deploy branch:  ${DEPLOY_BRANCH}"
  echo "  Remote URL:     ${HF_SPACE_GIT_URL}"
  echo "  Excludes:       ${DEPLOY_EXCLUDE_PATHS:-<none>}"
  echo "  Export dir:     ${deploy_dir}"
  echo "Would run: git init, commit, git push --force ${DEPLOY_REMOTE_NAME} ${DEPLOY_BRANCH}"
  exit 0
fi

echo "Creating orphan deploy repository..."
cd "${deploy_dir}"
git init -b "${DEPLOY_BRANCH}"
git add -A
git commit -m "${DEPLOY_COMMIT_PREFIX} ${SOURCE_SHA}"
git remote add "${DEPLOY_REMOTE_NAME}" "${space_url}"
git push --force "${DEPLOY_REMOTE_NAME}" "${DEPLOY_BRANCH}"

echo "Deployed ${SOURCE_SHA} to Hugging Face Space (${DEPLOY_BRANCH})."
