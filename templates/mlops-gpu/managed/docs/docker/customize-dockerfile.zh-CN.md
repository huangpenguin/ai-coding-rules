# Customize Dockerfile

模板 Dockerfile 提供一个可直接构建的 GPU 开发环境：PyTorch + CUDA + cuDNN + uv。GitLab GPU job 默认先使用 `MLOPS_GPU_IMAGE` 指定的基础镜像运行；当项目依赖稳定后，可以再把依赖固化进项目 Dockerfile，构建并推送到 registry，然后把 `MLOPS_GPU_IMAGE` 指向项目镜像。

原则：

- **默认先用基础镜像跑通**：新仓库先用 `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel` 跑 `gpu_smoke`。
- **Dockerfile 是稳定项目镜像入口**：依赖稳定后，Dev Container、手动 `docker run` 和 `MLOPS_GPU_IMAGE` 可复用同一个项目镜像。
- **包声明进仓库**：Python 依赖放在 `pyproject.toml` + `uv.lock`，旧项目可暂用 `requirements.txt`。
- **不要改 Runner 宿主机环境**：GPU Runner 宿主机只安装 Docker、NVIDIA driver、NVIDIA Container Toolkit、GitLab Runner。
- **不要依赖 Dev Container 的 `postCreateCommand` 做 CI 环境**：`postCreateCommand` 只服务交互开发；GitLab job 会自己安装 `uv` 并同步依赖。

## 1. 新仓库没有环境文件时

什么都不用先加，GitLab `gpu_smoke` 会使用默认基础镜像运行模板 `train.py`。如果想在 GPU 服务器上手动验证同一镜像：

```bash
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -w /workspace \
  pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel \
  bash -lc "python train.py"
```

这适合先验证：

- Docker executor / 手动 Docker 能启动 GPU 容器
- 容器能看到 GPU
- 模板 `train.py` 能打印 torch / CUDA / cuDNN / GPU capability

确认跑通后，再开始添加 `pyproject.toml`、`uv.lock` 或项目自己的训练命令。需要固化环境时，再编辑 Dockerfile 并推送项目镜像。

## 2. 推荐：用 uv 管 Python 依赖

新 DL 项目推荐使用：

```text
pyproject.toml
uv.lock
Dockerfile
```

默认 GitLab job 会根据 `pyproject.toml` 和 `uv.lock` 执行：

```bash
uv sync --frozen --dev
```

如果要把依赖固化进项目镜像，再在 Dockerfile 中加入类似片段：

```dockerfile
ENV UV_PROJECT_ENVIRONMENT=/opt/mlops-venv
ENV PATH="/opt/mlops-venv/bin:${PATH}"

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
```

为什么固化项目镜像时不用默认的 `/workspace/.venv`：

- Dev Container 或手动 `docker run` 常把项目代码挂载到 `/workspace`
- 如果镜像构建时把 `.venv` 放在 `/workspace/.venv`，运行时 bind mount 会把它盖掉
- 所以镜像内依赖环境建议放到 `/opt/mlops-venv`

开发阶段还没生成 `uv.lock` 时，可以先临时用：

```dockerfile
COPY pyproject.toml ./
RUN uv sync --no-dev --no-install-project
```

但进入共享 CI 前应提交 `uv.lock`，并改回 `uv sync --frozen`。

如果项目训练命令依赖 `pyproject.toml` 中的 console script 或依赖包，CI 变量建议改为：

```bash
TRAIN_COMMAND="python train.py"
SMOKE_COMMAND="python train.py"
```

如果 Dockerfile 已经把依赖环境放进镜像的 `PATH`，可以直接用 `python ...`。如果使用模板默认的 job 内 `uv sync`，也可以显式用：

```bash
TRAIN_COMMAND="uv run python train.py"
SMOKE_COMMAND="uv run python train.py"
```

这会把依赖解析和下载放在 GitLab job 阶段，适合早期迭代；稳定后可改为项目镜像以提升速度和可复现性。

## 3. 旧项目：从 requirements.txt 迁移

旧仓库如果只有 `requirements.txt`，默认 GitLab job 会执行：

```bash
uv venv
uv pip install -r requirements.txt
```

如果要固化进项目镜像，可以写入 Dockerfile：

```dockerfile
RUN uv venv /opt/mlops-venv
ENV VIRTUAL_ENV=/opt/mlops-venv
ENV PATH="/opt/mlops-venv/bin:${PATH}"

COPY requirements.txt ./
RUN uv pip install -r requirements.txt
```

后续再迁移到 `pyproject.toml` + `uv.lock`。不要手动装到 GPU 服务器宿主机。

## 4. 改 PyTorch / CUDA 版本

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

旧项目（例如 BasicSR）如果遇到依赖不兼容，可以退回 CUDA 12.1 对应镜像。

如果目标项目在 `pyproject.toml` 或 `requirements.txt` 里声明 `torch`，建议与基础镜像保持同一 minor 系列：

```text
torch>=2.6.0,<2.7.0
```

不要写 `torch>=1.7` 这类过宽约束，避免 resolver 安装到未验证的大版本。

## 5. 加系统依赖

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgl1 \
    && rm -rf /var/lib/apt/lists/*
```

常见 DL / CV 项目可能需要：

- `libgl1`
- `libglib2.0-0`
- `ffmpeg`
- `git-lfs`

只安装项目真实需要的系统包，避免把通用模板变成不可维护的大镜像。

## 6. 训练命令放哪里

GitLab Runner 中通过变量覆盖：

```bash
TRAIN_COMMAND="python basicsr/train.py -opt options/train/xxx.yml"
SMOKE_COMMAND="python train.py"
```

建议流程：

1. 先跑 `gpu_smoke`：验证 Dockerfile、GPU、依赖安装和最小训练入口。
2. 再跑 `run_training`：以前台 GitLab job 运行训练命令，CI 日志就是训练日志。
3. 如果 smoke 失败，先改 Dockerfile 或依赖文件，不要去改 GPU Runner 宿主机。
