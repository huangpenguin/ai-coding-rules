# MLOps GPU Pack

`mlops-gpu` 添加 Docker、devcontainer、GitLab GPU Runner 训练调度和 smoke test。

包含：

- `Dockerfile`
- `.devcontainer/devcontainer.json`
- `.devcontainer/README.md`（Rebuild 前/后操作手册）
- `.devcontainer/data-mount.env.example`（shell profile 片段，不会自动加载）
- `.devcontainer/devcontainer.local.json.example`（gitignore 本地挂载备选）
- `.gitlab/ci/train.yml`
- `train.py`（仅目标项目不存在时创建）
- `scripts/data_paths.py`（仅目标项目不存在时创建）
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

## Dev Container 基线（inject 后不要删）

- `workspaceMount` + `workspaceFolder=/workspace`：与 Dockerfile `WORKDIR` 一致。
- `remoteUser` + `updateRemoteUserUID`：避免 bind mount 后文件属主不匹配。
- `mounts`：`${localEnv:DATA_MOUNT_SOURCE}` → `/data`（Rebuild 前在宿主机 export）。
- `initializeCommand`：校验 `DATA_MOUNT_SOURCE` 存在，并用 `ls` 触发 autofs。
- `containerEnv.DATA_DIR=/data`：应用代码只读此变量 + 相对路径。

## 数据挂载工作流

1. 宿主机 Rebuild 前：`export DATA_MOUNT_SOURCE=/path/on/docker-host`
2. IDE：**Rebuild Container**（不是 Reload Window）
3. 容器内验证：`echo $DATA_DIR && ls /data`

仅 GPU smoke、无真实数据时：

```bash
export DATA_MOUNT_SOURCE="${HOME}/.local/share/mlops-empty-data"
mkdir -p "$DATA_MOUNT_SOURCE"
```

防遗忘：写入 `~/.zshrc`，或使用 gitignore 的 `.devcontainer/devcontainer.local.json`。

详细步骤见 [`.devcontainer/README.md`](../../.devcontainer/README.md) 与 [数据路径环境变量隔离](../use-cases/data-mount-env-isolation.md)。

GitLab CI 使用相同变量名：在 CI/CD Variables 设置 `DATA_MOUNT_SOURCE`（GPU Runner 宿主机路径）。

更多步骤见 [Docker quickstart](../docker/quickstart.zh-CN.md)。
