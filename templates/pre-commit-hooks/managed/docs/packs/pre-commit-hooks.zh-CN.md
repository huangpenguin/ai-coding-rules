# Pre-commit Hooks Pack

`pre-commit-hooks` 添加 **可选** 的本地 Git hook（commit 时 Ruff、push 时 Pyright basic）。

**自动依赖**：会同时应用 `python-quality`（需要 Ruff / Pyright 配置）。

**不会**自动 `pre-commit install`；需要时手动运行 `bash scripts/setup-local-hooks.sh`。

**不含** CI：GitLab / GitHub quality job 直接跑 `uv run ruff` / `uv run pyright`，不经过 pre-commit。

包含：

- `.pre-commit-config.yaml`
- `pyrightconfig.pre-push.json`（pre-push 用 `basic`；CI 仍用 `pyrightconfig.json` 的 strict）
- `scripts/setup-local-hooks.sh`

命令：

```bash
init-ai add pre-commit-hooks --dry-run
init-ai add pre-commit-hooks --apply
bash scripts/setup-local-hooks.sh   # 可选，显式安装 hook
```

## 与 python-quality / ci-quality 的关系

| Pack | 作用 |
|------|------|
| `python-quality` | Ruff、Pyright 配置与规则；`uv add --dev ruff pyright` |
| `pre-commit-hooks` | 本地 Git hook 配置；`uv add --dev pre-commit` |
| `ci-quality` | 远程 CI lint；自动带上 `python-quality`，**不带**本 pack |

不需要本地 hook 时：**不要** add 本 pack。CI lint 仍可通过 `ci-quality` 单独使用。

## 宿主机（GPU 项目）

```bash
bash scripts/setup-local-hooks.sh
.venv/bin/pre-commit run --all-files   # 手动跑一次
```

禁止：

- `uv run pre-commit ...`（会隐式 sync 全量依赖含 torch）
- 在未 add 本 pack 时期望存在 `.pre-commit-config.yaml`

卸载 hook：`pre-commit uninstall` 与 `pre-commit uninstall --hook-type pre-push`。
