# MLOps GPU Pack

`mlops-gpu` 添加 Docker、devcontainer、GitLab GPU Runner 训练调度和 smoke test。

包含：

- `Dockerfile`
- `.devcontainer/devcontainer.json`
- `.devcontainer/devcontainer.local.json.example`（本地数据挂载示例，需要手动参考，不会自动生效）
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

数据挂载默认是可选的：

- devcontainer 默认不绑定宿主机数据目录，镜像内会创建空的 `/data`。
- 如果需要挂载数据，参考 `.devcontainer/devcontainer.local.json.example`，把适合你机器的字段复制到 `.devcontainer/devcontainer.json`。
- GitLab CI 默认 `DATA_MOUNT_SOURCE=""`，真实训练时在 GitLab CI/CD Variables 中设置 GPU 宿主机路径，例如 `/mnt/data` 或 `/mnt/nfs_data`。

更多步骤见 [Docker quickstart](../docker/quickstart.zh-CN.md)。
