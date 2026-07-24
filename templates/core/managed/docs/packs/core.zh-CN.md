# Core Pack

`core` 是默认 pack。直接运行 `init-ai` 时只注入这一组文件。

**语言无关**：不含 Python / uv / Ruff / Pyright 约束；适用于 Vue、前端、文档仓库、混合项目或任意只想加 Cursor 规则的场景。

包含：

- Cursor rules: `.cursor/rules/`（通用 agent 行为、项目记忆、沟通风格、**Matt Pocock skills 指引**等）
- Claude / 兼容规则: `CLAUDE.md`、`AGENTS.md`、`.cursorrules`
- 项目记忆入口: `MEMORY.md`、`.cursor/project-context/`、`.cursor/lessons-learned/`
- Matt Pocock skills 安装脚本: `scripts/install-matt-pocock-skills.sh`（`init-ai` 结束时自动执行，需 Node.js/`npx` + 网络）

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

`init-ai`（core）把 [mattpocock/skills](https://github.com/mattpocock/skills) **安装进当前项目**（不是本机全局）：`.agents/skills/`（Cursor）与 `.claude/skills/`（Claude Code）。未使用 `-g`。

在远程服务器或其他电脑上同样适用：在该项目目录跑 `init-ai` 或：

```bash
bash scripts/install-matt-pocock-skills.sh
```

推荐功能流（非琐碎改动）：

1. `/setup-matt-pocock-skills` — 每仓库一次
2. `/grill-with-docs`（有代码库时优先）或 `/grill-me` — 逐项澄清需求
3. `/to-spec` — 写成规格（禁止写实现代码）
4. `/to-tickets` — 拆成可测的垂直切片票据
5. `/implement` — 按票 TDD；收尾带 code-review

定期：`/improve-codebase-architecture`。详见 `.cursor/rules/matt-pocock-skills.mdc`。

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
