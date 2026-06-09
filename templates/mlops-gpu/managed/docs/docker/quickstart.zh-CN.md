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
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  my-project-gpu bash -lc "python train.py"
```

上面的命令不挂载数据盘，适合先确认镜像和 GPU 能正常工作。镜像里默认有空的 `/data` 目录，所以 smoke test 不需要真实数据也能启动。

## 挂载数据目录

如果训练需要数据，把 **Docker 宿主机** 上的数据目录挂到容器 `/data`：

```bash
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /path/on/gpu-host:/data \
  my-project-gpu bash -lc "python train.py"
```

注意：

- `/path/on/gpu-host` 是运行 Docker 的 GPU 服务器上的路径，不是 NFS 服务器 export 字符串。
- 如果你的 GPU 服务器用 autofs，并且数据在 `/mnt/data`，就写 `-v /mnt/data:/data`。
- 如果是手动挂载到 `/mnt/nfs_data`，就写 `-v /mnt/nfs_data:/data`。
- 如果不确定路径，先在 GPU 服务器上执行 `ls /mnt/data` 或 `ls /mnt/nfs_data`。

如果只是 BasicSR 第一阶段试训，可以先不用 Docker，直接按 BasicSR 的 Python 命令跑。
