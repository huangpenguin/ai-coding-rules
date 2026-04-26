#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

echo "🚀 正在为当前项目注入企业级 AI 工程化规范..."
echo "📍 模板源: ${SOURCE_DIR}"
echo "🎯 目标项目: ${TARGET_DIR}"

echo "🧠 正在注入 Cursor / Claude AI 规则..."
cp -R -f "${SOURCE_DIR}/.cursor" "${TARGET_DIR}/"
cp -f "${SOURCE_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md"
cp -f "${SOURCE_DIR}/.cursorrules" "${TARGET_DIR}/.cursorrules"

echo "📦 正在注入 GitHub PR 模板与 CI 工作流..."
cp -R -f "${SOURCE_DIR}/.github" "${TARGET_DIR}/"

echo "🛡️ 正在注入 Ruff / Pyright / pre-commit 配置..."
cp -f "${SOURCE_DIR}/ruff.toml" "${TARGET_DIR}/ruff.toml"
cp -f "${SOURCE_DIR}/pyrightconfig.json" "${TARGET_DIR}/pyrightconfig.json"
cp -f "${SOURCE_DIR}/.pre-commit-config.yaml" "${TARGET_DIR}/.pre-commit-config.yaml"
cp -f "${SOURCE_DIR}/.gitignore" "${TARGET_DIR}/.gitignore"

if [[ -f "${TARGET_DIR}/pyproject.toml" ]]; then
  echo "⚡ 检测到 pyproject.toml，正在安装开发依赖: ruff pyright pre-commit..."
  uv add --dev ruff pyright pre-commit
else
  echo "⏭️ 未检测到 pyproject.toml，跳过开发依赖安装。"
fi

if [[ -d "${TARGET_DIR}/.git" ]]; then
  echo "🪝 检测到 Git 仓库，正在安装 pre-commit hook..."
  uv run pre-commit install
else
  echo "⏭️ 未检测到 .git 目录，跳过 Git hook 安装。"
fi

echo "✅ 企业级 AI 工程化规范注入成功。"
