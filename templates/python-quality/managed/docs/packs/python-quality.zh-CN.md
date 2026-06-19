# Python Quality Pack

`python-quality` 添加本地质量检查配置。

包含：

- `ruff.toml`
- `pyrightconfig.json`
- `.pre-commit-config.yaml`
- `.gitignore`

命令：

```bash
init-ai add python-quality --dry-run
init-ai add python-quality --apply
```

## 依赖与环境文件

- 若目标项目**已有** `pyproject.toml`：执行 `uv add --dev ruff pyright pre-commit`，并在有 `.git` 时安装 pre-commit hook。
- 若目标项目**没有** `pyproject.toml`：先用 `uv init` 生成最小 `pyproject.toml`，再安装上述 dev 依赖。
- 若只有 `requirements.txt` / `setup.py`：这些文件**不会被修改**；你需要自行把运行时依赖迁移进 `pyproject.toml`。

`ci-quality` 与 `mlops-gpu` 会自动带上本 pack，无需单独再执行一次。
