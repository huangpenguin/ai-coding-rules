# Docker Quickstart

这份文档面向不熟 Docker 的使用者。

## 五个概念

- **宿主机**：真正有 GPU 的服务器，例如 main_gpu。
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

## 新仓库没有环境文件时

如果仓库里还没有 `pyproject.toml`、`uv.lock`、`requirements.txt` 或成熟训练脚本，可以先直接使用默认 GPU 基础镜像：

```text
pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

GitLab 上手动运行 `gpu_smoke` 时，Docker executor 会直接拉起这个镜像作为 job 容器，并运行模板 `train.py`。

如果想在 GPU 服务器上手动验证同一镜像：

```bash
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -w /workspace \
  pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel \
  bash -lc "python train.py"
```

这一步只验证基础环境：

- Docker executor / Docker 手动运行能看到 GPU
- 容器能看到 GPU
- PyTorch / CUDA / cuDNN 版本正常
- 模板 `train.py` 能跑完 smoke

跑通后再做项目化改造：

1. 添加 `pyproject.toml` + `uv.lock`，或先接入旧项目的 `requirements.txt`
2. 让 GitLab YAML 中的 uv 同步步骤安装项目依赖
3. 把 `SMOKE_COMMAND` 改成项目最小验证命令
4. 把 `TRAIN_COMMAND` 改成长训练命令
5. 需要更快或更稳定时，再把依赖固化进项目镜像并通过 `MLOPS_GPU_IMAGE` 使用

详细片段见 [Customize Dockerfile](customize-dockerfile.zh-CN.md)。

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

`train.py` 会打印当前运行时的 `Torch version`、`Torch CUDA build`、`cuDNN version` 和 `GPU capability`。在 V100 机器上，推荐看到的是 `torch 2.6.x + cu124`，GPU capability 为 `sm_70`。

完整流程见 [`.devcontainer/README.md`](../../.devcontainer/README.md) 与 [数据路径环境变量隔离](../use-cases/data-mount-env-isolation.md)。

## PyTorch 版本约束

模板镜像基底固定为：

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

如果目标项目的 `requirements.txt` 或 `pyproject.toml` 声明了 torch，请跟模板保持同一 minor 系列：

```text
torch>=2.6.0,<2.7.0
```

不要只写 `torch>=1.7` 这类过宽约束；resolver 可能安装过新的 torch，导致 `.venv` 与 Docker 镜像内的 PyTorch / CUDA / V100 `sm_70` 验证组合不一致。需要升级 torch 或 CUDA 时，先单独验证 GPU 架构、driver、CUDA runtime 和项目依赖。

## 包管理原则

推荐优先级：

1. 新项目：`pyproject.toml` + `uv.lock`，`uv-bootstrap.sh` → `uv sync --frozen --dev`
2. 旧项目过渡：`requirements.txt`（或半迁移），`uv-bootstrap.sh` 自动处理 cu124 torch
3. 稳定生产训练：把依赖固化进项目镜像，推送到 registry 后设置 `MLOPS_GPU_IMAGE`

不要把项目依赖安装到 GPU Runner 宿主机。GPU Runner 宿主机只负责 Docker executor、NVIDIA runtime 和数据盘挂载。

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

## GitLab 上快速验证

启用 `mlops-gpu` 后，推荐先手动 Play：

```text
gpu_smoke
```

它会在 GPU Docker executor Runner 上直接运行：

```text
pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel job container
bash scripts/uv-bootstrap.sh
run ${SMOKE_COMMAND}
```

`gpu_smoke` 通过后，再手动 Play：

```text
run_training
```

`run_training` 会以前台 GitLab job 运行训练命令，CI 日志就是训练日志，job 成功/失败就是训练命令的成功/失败。

## 团队开发：DATA_MOUNT_SOURCE

每人 Rebuild 前设置自己的宿主机路径，不写入 Git：

```bash
export DATA_MOUNT_SOURCE=/home/alice/data
export DATA_MOUNT_SOURCE=/mnt/data
export DATA_MOUNT_SOURCE=/D/data
```

容器内统一读 `DATA_DIR=/data` 与相对路径，例如 `/data/data_0607/...`。

如果只是 BasicSR 第一阶段试训，可以先不用 Docker，直接按 BasicSR 的 Python 命令跑。
