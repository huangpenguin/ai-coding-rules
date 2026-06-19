# CI Quality Pack

`ci-quality` 添加 GitHub Actions 与 GitLab CI 的质量检查模板，不包含 GPU 训练调度。

**自动依赖**：会同时应用 `python-quality`（注入 Ruff / Pyright / pre-commit 配置，并把 `ruff`、`pyright`、`pre-commit` 写入 `pyproject.toml` dev 组）。这样 CI 里的 `uv sync --dev` + `uv run pyright` 才能在容器内正常工作。

若目标项目还没有 `pyproject.toml`，会先脚手架生成一个最小的 `pyproject.toml`（`requirements.txt` / `setup.py` 不会被删除或改写）。

包含：

- `.github/workflows/ci.yml`
- `.gitlab-ci.yml`
- `.gitlab/ci/quality.yml`

命令：

```bash
init-ai add ci-quality --dry-run
init-ai add ci-quality --apply
```

GitHub Actions 使用 `astral-sh/setup-uv` 和固定 Python 版本。GitLab CI 使用 `workflow: rules`、`include` 分层和基于文件的 cache key。

如果项目是 BasicSR 这类旧仓库，建议先只用 `core`，等代码结构稳定后再启用本 pack。
