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

`mlops-gpu` 会自动带上 `ci-quality`（进而带上 `python-quality`），因为 GitLab 的训练 job 需要根 `.gitlab-ci.yml` include 入口，且 quality CI 需要 dev 组里的 `ruff` / `pyright`。

训练 Runner 要求：

- self-hosted Runner
- tags: `linux`, `docker`, `gpu`
- executor: `docker`
- GPU 宿主机已安装 Docker + NVIDIA driver + NVIDIA Container Toolkit
- Runner `config.toml` 中设置 `[runners.docker] gpus = "all"`
- 数据集通过 runner volumes 挂载，例如 `/mnt/data:/data:ro`

## GPU 镜像与依赖管理

本 pack 默认先使用 `MLOPS_GPU_IMAGE` 指定的 GPU 基础镜像运行 GitLab job：

```text
pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

项目依赖由 GitLab job 内的 `uv` 步骤同步；需要更快或更稳定时，再把依赖固化进项目 Dockerfile，构建并推送到 registry，然后把 `MLOPS_GPU_IMAGE` 改为项目镜像。

推荐工作流：

1. 新仓库没有环境文件时，先直接使用默认 PyTorch/CUDA 镜像跑 `gpu_smoke`。
2. 用 `gpu_smoke` 或本地 `docker run --gpus all` 验证 GPU、torch、CUDA、cuDNN。
3. 需要加 Python 包时，优先提交 `pyproject.toml` + `uv.lock`，由 GitLab job 执行 `uv sync --frozen --dev`。
4. 旧项目只有 `requirements.txt` 时，可先由 GitLab job 执行 `uv venv && uv pip install -r requirements.txt` 过渡。
5. 不要把项目依赖安装到 GPU Runner 宿主机；宿主机只负责 Docker、NVIDIA runtime 和 GitLab Runner。

详细方法见 [Customize Dockerfile](../docker/customize-dockerfile.zh-CN.md)。

## 默认 GPU / PyTorch 组合

模板默认使用 `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`，对应 `torch 2.6.x + cu124`、CUDA 12.4、cuDNN 9.x。该组合已按 V100（`sm_70`）保守验证。

如果目标项目需要在 `requirements.txt` 或 `pyproject.toml` 里声明 `torch`，建议 pin 到：

```text
torch>=2.6.0,<2.7.0
```

不要使用 `torch>=1.7` 这类过宽约束，避免 resolver 把 `.venv` 升到未验证的大版本。

## Dev Container 基线（inject 后不要删）

- `workspaceMount` + `workspaceFolder=/workspace`：与 Dockerfile `WORKDIR` 一致。
- `remoteUser` + `updateRemoteUserUID`：避免 bind mount 后文件属主不匹配。
- `mounts`：`${localEnv:DATA_MOUNT_SOURCE}` → `/data`（Rebuild 前在宿主机 export）。
- `initializeCommand`：校验 `DATA_MOUNT_SOURCE` 存在，并用 `ls` 触发 autofs。
- `containerEnv.DATA_DIR=/data`：应用代码只读此变量 + 相对路径。

## 数据挂载工作流

1. Dev Container 宿主机 Rebuild 前：`export DATA_MOUNT_SOURCE=/mnt/data`（或项目真实数据目录）
2. IDE：**Rebuild Container**（不是 Reload Window）
3. 容器内验证：`echo $DATA_DIR && ls /data`

仅 GPU smoke、无真实数据时：

```bash
export DATA_MOUNT_SOURCE="${HOME}/.local/share/mlops-empty-data"
mkdir -p "$DATA_MOUNT_SOURCE"
```

防遗忘：写入 `~/.zshrc`，或使用 gitignore 的 `.devcontainer/devcontainer.local.json`。

详细步骤见 [`.devcontainer/README.md`](../../.devcontainer/README.md) 与 [数据路径环境变量隔离](../use-cases/data-mount-env-isolation.md)。

GitLab Docker executor 使用同一个容器内路径：`DATA_DIR=/data`。宿主机数据路径由 GPU Runner 的 `config.toml` volumes 挂载，例如 `/mnt/data:/data:ro`，不在 `.gitlab-ci.yml` 中动态设置。

更多步骤见 [Docker quickstart](../docker/quickstart.zh-CN.md)。

## GitHub Actions 边界

`ci-quality` 的 GitHub Actions 默认继续用 `ubuntu-latest` 做 Ruff / Pyright 等 CPU 质量检查，不默认接 GPU runner。

如果未来需要 GitHub self-hosted GPU runner，应单独配置 GitHub Actions 的 `runs-on: [self-hosted, linux, gpu]`；不要和 GitLab Runner 的 `config.toml`、tags 或注册 token 混用。
