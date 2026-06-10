# Docker Quickstart

这份文档面向不熟 Docker 的使用者。

## 五个概念

- **宿主机**：真正有 GPU 的服务器，例如 gpu01。
- **镜像**：环境快照，例如 PyTorch + CUDA + uv。
- **容器**：从镜像启动出来的一次运行环境。
- **挂载**：把 Docker 宿主机目录映射进容器，例如 `/mnt/data` → `/data`。
- **GPU 透传**：通过 `--gpus all` 让容器看到宿主机 GPU。

## 先只测试 GPU Docker

不需要完整项目：

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## 已经 init-ai 后，后置启用 MLOps

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## Rebuild 前检查清单（Dev Container）

在 IDE 中 Rebuild Container **之前**，于 Docker 宿主机执行：

```bash
export DATA_MOUNT_SOURCE=/path/on/docker-host
test -n "$DATA_MOUNT_SOURCE" && ls "$DATA_MOUNT_SOURCE" >/dev/null && test -d "$DATA_MOUNT_SOURCE"
```

- 路径必须是 **Docker 宿主机本地路径**，不是 NFS export 字符串。
- autofs 场景：`ls` 会触发 `/mnt/data` 等路径挂载。
- 将 export 写入 `~/.zshrc` 可免每次手动设置。

仅 GPU smoke、不需要真实数据：

```bash
export DATA_MOUNT_SOURCE="${HOME}/.local/share/mlops-empty-data"
mkdir -p "$DATA_MOUNT_SOURCE"
```

Rebuild 后在容器内验证：

```bash
echo "DATA_DIR=$DATA_DIR"
nvidia-smi
ls "$DATA_DIR"
uv run python train.py
```

完整流程见 [`.devcontainer/README.md`](../../.devcontainer/README.md) 与 [数据路径环境变量隔离](../use-cases/data-mount-env-isolation.md)。

## 命令行测试（不用 Dev Container）

```bash
docker build -t my-project-gpu .
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /path/on/gpu-host:/data \
  -e DATA_DIR=/data \
  my-project-gpu bash -lc "python train.py"
```

注意：

- `/path/on/gpu-host` 是运行 Docker 的 GPU 服务器上的路径。
- autofs 且数据在 `/mnt/data`：`-v /mnt/data:/data`。
- 不确定路径时，先在 GPU 服务器上 `ls /mnt/data`。

## 团队开发：DATA_MOUNT_SOURCE

每人 Rebuild 前设置自己的宿主机路径，不写入 Git：

```bash
export DATA_MOUNT_SOURCE=/home/alice/data
export DATA_MOUNT_SOURCE=/mnt/data
export DATA_MOUNT_SOURCE=/D/data
```

容器内统一读 `DATA_DIR=/data` 与相对路径，例如 `/data/data_0607/...`。

如果只是 BasicSR 第一阶段试训，可以先不用 Docker，直接按 BasicSR 的 Python 命令跑。
