# Docker Quickstart

这份文档面向不熟 Docker 的使用者。

## 五个概念

- **宿主机**：真正有 GPU 的服务器，例如 gpu01。
- **镜像**：环境快照，例如 PyTorch + CUDA + uv。
- **容器**：从镜像启动出来的一次运行环境。
- **挂载**：把宿主机目录映射进容器，例如 `/mnt/nfs_data` → `/data`。
- **GPU 透传**：通过 `--gpus all` 让容器看到宿主机 GPU。

## 先只测试 GPU Docker

不需要完整项目：

```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## 已经 init-ai 后，后置启用 MLOps

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

然后测试：

```bash
docker build -t my-project-gpu .
docker run --rm --gpus all --shm-size 16g   -v "$(pwd):/workspace"   -v /mnt/nfs_data:/data   my-project-gpu bash -lc "python train.py"
```

如果只是 BasicSR 第一阶段试训，可以先不用 Docker，直接按 BasicSR 的 Python 命令跑。
