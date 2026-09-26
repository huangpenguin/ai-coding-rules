# Core Pack

`core` 是默认 pack。直接运行 `init-ai` 时只注入这一组文件。

**语言无关**：不含 Python / uv / Ruff / Pyright 约束；适用于 Vue、前端、文档仓库、混合项目或任意只想加 Cursor 规则的场景。

包含：

- 通用说明：`AGENTS.md`；`CLAUDE.md` 引用同一文件，避免两份规则漂移
- Cursor 专项规则：`.cursor/rules/`（仅相关任务或文件触发）
- 项目记忆入口: `MEMORY.md`、`.cursor/project-context/`、`.cursor/lessons-learned/`
- 可选 skills 安装脚本：`scripts/install-matt-pocock-skills.sh`（手动运行时才需要 Node.js/`npx` + 网络）

适合：

- Vue / 前端 / 文档 / 配置类仓库（**只用 `init-ai`，不要加 `python-quality`**）
- 刚 clone 下来的 legacy 项目，例如 BasicSR 第一阶段试训
- 只想让 Cursor / Claude Code 读到项目规则，不想引入 Docker / CI / 语言专用工具链

命令：

```bash
init-ai
init-ai --update --apply   # 更新已注入的 managed 文件
```

## Matt Pocock AI skills

需要 [mattpocock/skills](https://github.com/mattpocock/skills) 的工作流时，在当前项目手动安装；`init-ai` 不会自动安装或更新 skills。

在远程服务器或其他电脑上同样适用：在该项目目录跑 `init-ai` 或：

```bash
bash scripts/install-matt-pocock-skills.sh code-review
# 只有需要整套时才用：bash scripts/install-matt-pocock-skills.sh --all
```

复杂需求可以按需选用：

1. `/setup-matt-pocock-skills` — 每仓库一次
2. `/grill-with-docs`（有代码库时优先）或 `/grill-me` — 逐项澄清需求
3. `/to-spec` — 写成规格（禁止写实现代码）
4. `/to-tickets` — 拆成可测的垂直切片票据
5. `/implement` — 按票 TDD；收尾带 code-review

普通改动不要求走完整流程。明确要审视架构时可用 `/improve-codebase-architecture`。

`init-ai --update --apply` 会清理内容与旧模板完全一致的 `.cursorrules` 和重复 Cursor 规则；改过的文件会保留，需自行检查是否还需要。

## 项目上下文（推荐）

在 `.cursor/project-context/overview.md` 写明技术栈与常用命令，例如：

```markdown
- Stack: Vue 3, Vite, TypeScript
- Package manager: pnpm
- Commands: pnpm dev / pnpm build / pnpm lint
```

该文件在 `preserve` 目录，inject 不会覆盖。

## 误加了 python-quality 的非 Python 项目

若曾运行 `init-ai add python-quality` 或 `pre-commit-hooks`，可能多出 `pyproject.toml`、`.venv`、Ruff/Pyright 或 pre-commit 配置。清理后重新拉 core：

```bash
rm -rf .venv pyproject.toml uv.lock ruff.toml pyrightconfig.json pyrightconfig.pre-push.json .pre-commit-config.yaml scripts/setup-local-hooks.sh
init-ai --update --apply
# 勿再运行 python-quality / pre-commit-hooks / ci-quality / mlops-gpu
```

若 `.gitignore` 被 python-quality 改过，用 `git checkout -- .gitignore` 或手动合并。

## Python 项目

Python 专用规则与工具链在 `python-quality` pack，不在 core：

```bash
init-ai
init-ai add python-quality --apply
```

若之前只跑过 `init-ai` 且依赖 core 里的 `python-uv.mdc`，core 去 Python 化后需补跑 `init-ai add python-quality --update --apply`。
