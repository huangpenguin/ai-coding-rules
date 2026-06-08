# CI Quality Pack

`ci-quality` 添加 GitHub Actions 与 GitLab CI 的质量检查模板，不包含 GPU 训练调度。

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
