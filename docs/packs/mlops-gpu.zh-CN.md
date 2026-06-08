# MLOps GPU Pack

`mlops-gpu` 添加 Docker、devcontainer、GitLab GPU Runner 训练调度和 smoke test。

包含：

- `Dockerfile`
- `.devcontainer/devcontainer.json`
- `.gitlab/ci/train.yml`
- `train.py`（仅目标项目不存在时创建）
- Docker / GPU 相关文档

命令：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

`mlops-gpu` 会自动带上 `ci-quality`，因为 GitLab 的训练 job 需要根 `.gitlab-ci.yml` include 入口。

训练 Runner 要求：

- self-hosted Runner
- tag: `gpu-server`
- executor: `shell`
- GPU 宿主机已安装 Docker + NVIDIA Container Toolkit

更多步骤见 [Docker quickstart](../docker/quickstart.zh-CN.md)。
