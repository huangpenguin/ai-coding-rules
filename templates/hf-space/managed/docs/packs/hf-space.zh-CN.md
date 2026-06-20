# HF Space Deploy Pack

`hf-space` 提供 **「本地可留大文件 / 历史，Space 只收干净快照」** 的部署脚本与 GitHub Actions workflow。

## 适用场景

- 本地开发需要大文件或完整 Git 历史（例如 `sample_docs/public/legacy` 里的 PDF）。
- Hugging Face Space 不能接收这些文件，且对臃肿历史敏感。
- 希望 CI 推送的是 **无历史、单次 commit、已剔除大目录** 的仓库。

## 原理

1. `git archive` 导出指定提交（默认 `HEAD`，CI 用 `GITHUB_SHA`）的文件快照（不含 `.git` 历史）。
2. 在临时目录删除 `DEPLOY_EXCLUDE_PATHS` 中的路径。
3. `git init` 新建 orphan 仓库，单次 commit。
4. `git push --force` 到 Space 的 `main`。

本地工作区 **不会被修改**；exclude 只在临时目录生效。

## 包含

- `scripts/deploy-hf-space.sh`
- `.github/workflows/deploy-hf-space.yml`
- 本说明文档

## 命令

```bash
init-ai add hf-space --dry-run
init-ai add hf-space --apply
```

本地试跑（不推送）：

```bash
cp deploy-hf-space.env.example deploy-hf-space.env   # 填入 URL / token / excludes
bash scripts/deploy-hf-space.sh --dry-run
bash scripts/deploy-hf-space.sh
```

## GitHub Actions 配置

Repository **Secrets**:

| Name | Purpose |
|------|---------|
| `HF_SPACE_GIT_URL` | Space 的 HTTPS git URL |
| `HF_TOKEN` | Hugging Face token（若 URL 未嵌入凭证） |

Repository **Variables**（可选）:

| Name | Example |
|------|---------|
| `DEPLOY_EXCLUDE_PATHS` | `sample_docs/public/legacy` |
| `HF_USERNAME` | 你的 HF 用户名（配合 `HF_TOKEN` 使用） |

Workflow 在 `main` push 或手动 `workflow_dispatch` 时触发。若只想手动部署，可删掉 `push` trigger。

## 注意

- `git push --force` 会 **覆盖** Space 远端历史；这是预期行为。
- `HF_SPACE_GIT_URL` 必须是 **HTTPS** git URL；`http://` 与 `git@` SSH 会在部署前报错。
- `deploy-hf-space.env` 含 token，应加入 `.gitignore`，不要提交。
- 本 pack **不** 自动依赖 `ci-quality`；与 GPU / lint CI 正交，按需单独启用。
