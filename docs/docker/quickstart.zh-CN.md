# Docker Quickstart

这份文档面向不熟 Docker 的使用者。inject `mlops-gpu` 后，目标项目内会有更完整的副本（含 `.devcontainer/README.md`）。

## 五个概念

- **宿主机**：真正有 GPU 的服务器，例如 gpu01。
- **镜像**：环境快照，例如 PyTorch + CUDA + uv。
- **容器**：从镜像启动出来的一次运行环境。
- **挂载**：把 Docker 宿主机目录映射进容器，例如 `/mnt/data` → `/data`。
- **GPU 透传**：通过 `--gpus all` 让容器看到宿主机 GPU。

## 先只测试 GPU Docker

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## init-ai 启用 MLOps

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## Dev Container：Rebuild 前检查

```bash
export DATA_MOUNT_SOURCE=/path/on/docker-host
test -n "$DATA_MOUNT_SOURCE" && ls "$DATA_MOUNT_SOURCE" >/dev/null && test -d "$DATA_MOUNT_SOURCE"
```

然后 **Rebuild Container**。详见 inject 后的 [`.devcontainer/README.md`](../templates/mlops-gpu/managed/.devcontainer/README.md) 与 [数据路径环境变量隔离](use-cases/data-mount-env-isolation.md)。

## 命令行 smoke test

```bash
docker build -t my-project-gpu .
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /path/on/gpu-host:/data \
  -e DATA_DIR=/data \
  my-project-gpu bash -lc "python train.py"
```

如果只是 BasicSR 第一阶段试训，可以先不用 Docker，直接按 BasicSR 的 Python 命令跑。
