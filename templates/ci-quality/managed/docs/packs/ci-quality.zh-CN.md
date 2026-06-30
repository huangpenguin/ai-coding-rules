# CI Quality Pack

`ci-quality` 添加 GitHub Actions 与 GitLab CI 的 **quality** 检查模板，不包含 GPU 训练（train 在 `mlops-gpu` pack）。

**自动依赖**：会同时应用 `python-quality`（Ruff / Pyright 配置，以及 `pyproject.toml` dev 组里的 `ruff`、`pyright`）。

**不含** pre-commit Git hook；本地 hook 需单独 `init-ai add pre-commit-hooks`。

**独立 pack**：不含 Docker Compose / GPU train job。

若目标项目还没有 `pyproject.toml`，会先脚手架生成最小 `pyproject.toml`（`requirements.txt` / `setup.py` 不会被删除或改写）。

包含：

- `.github/workflows/ci.yml`
- `.gitlab-ci.yml`（**仅** include `quality.yml`）
- `.gitlab/ci/quality.yml`

命令：

```bash
init-ai add ci-quality --dry-run
init-ai add ci-quality --apply
```

CI 直接执行 `uv run ruff` / `uv run pyright`，不依赖 pre-commit。

## GitLab quality 严格度

根 `.gitlab-ci.yml` 默认：

```yaml
QUALITY_CI_BLOCKING: "false"
```

| 值 | 行为 |
|----|------|
| `false`（默认） | MR/main 上 quality job **手动** Play，且 **allow_failure** |
| `true` | MR/main 上自动跑且阻塞 pipeline |

在 GitLab **Settings → CI/CD → Variables** 可覆盖，或直接改 `.gitlab-ci.yml`。

## 与其他 pack 组合

- 已有 `mlops-gpu` 且也要 quality CI：两个 pack 都 inject 后，**手动合并**根 `.gitlab-ci.yml`（见仓库 README「Combine GitLab CI」）。
- 要本地 Git hook：另加 `init-ai add pre-commit-hooks --apply`。
- Legacy 仓库：可不加本 pack；或加但保持 `QUALITY_CI_BLOCKING=false`。

GitHub Actions 使用 `astral-sh/setup-uv`。GitLab CI 使用 `workflow: rules`、`include` 分层和基于文件的 cache key。
