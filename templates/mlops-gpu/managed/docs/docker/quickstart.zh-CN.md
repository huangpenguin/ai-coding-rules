# Docker Quickstart

这份文档面向不熟 Docker 的使用者。

## 五个概念

- **宿主机**：真正有 GPU 的服务器，例如 main_gpu。
- **镜像**：环境快照，例如 NGC PyTorch + CUDA。
- **容器**：从镜像启动出来的一次运行环境。
- **挂载**：把 Docker 宿主机目录映射进容器，例如 `/mnt/data` → `/workspace/data`。
- **GPU 透传**：通过 Compose `deploy.resources` 或 `docker run --gpus all` 让容器看到 GPU。

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

## 本地开发：Docker Compose（推荐）

inject 后仓库根目录有 `docker-compose.yml`：

```bash
# 跑 smoke / 训练
docker compose run --rm train python train.py

# 交互调试
docker compose run --rm train bash

# 可选：后台常驻容器
docker compose up -d train
docker compose exec train bash
```

**禁止**在宿主机直接 `python train.py` 或 `pip install`（Agent 规则见 `.cursor/rules/mlops-docker-compose.mdc`）。

### 加数据盘

编辑 volumes（或本地 `docker-compose.override.yml`）：

```yaml
volumes:
  - .:/workspace
  - /mnt/data:/workspace/data:ro
```

详见 [数据路径环境变量隔离](../use-cases/data-mount-env-isolation.md)。

## 新仓库没有环境文件时

compose 默认使用 NGC 预装 PyTorch 镜像：

```text
nvcr.io/nvidia/pytorch:24.01-py3
```

可直接：

```bash
docker compose run --rm train python train.py
```

跑通后再：

1. 添加 `requirements.txt` 或 `pyproject.toml` + `uv.lock`
2. 永久依赖：改 `Dockerfile`，compose 改为 `build: .`
3. GitLab：配置 `SMOKE_COMMAND` / `TRAIN_COMMAND`，跑 `gpu_smoke`

## GitLab CI（与本地 compose 并行）

本地用 compose + NGC 镜像；CI train job 默认 `MLOPS_GPU_IMAGE`：

```text
pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

job 内执行 `bash scripts/uv-bootstrap.sh` 再跑训练命令。

手动验证同一 CI 镜像：

```bash
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -w /workspace \
  pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel \
  bash -lc "bash scripts/uv-bootstrap.sh && python train.py"
```

## PyTorch 版本约束

本地 compose 与 CI 可使用不同基底镜像。若 `requirements.txt` / `pyproject.toml` 声明 torch，请 pin 到已验证 minor 系列，例如：

```text
torch>=2.6.0,<2.7.0
```

## 包管理原则

| 场景 | 做法 |
|------|------|
| 本地快速试跑 | compose 预装镜像 + 容器内临时 `pip install` |
| 项目化 | `Dockerfile` + `build: .` |
| GitLab CI | `pyproject.toml` + `uv.lock`，`uv-bootstrap.sh` |
| 生产训练 | 构建项目镜像推 registry，设 `MLOPS_GPU_IMAGE` |

不要把项目依赖安装到 GPU Runner **宿主机**。

## 命令行测试（不用 Compose 文件）

```bash
docker build -t my-project-gpu .
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /path/on/gpu-host:/data \
  -e DATA_DIR=/data \
  my-project-gpu bash -lc "python train.py"
```

## GitLab 上快速验证

```text
gpu_smoke   → 通过后 → run_training
```

## TensorBoard

compose 已映射 `6006:6006`。容器内启动 TensorBoard 后，宿主机浏览器访问 `http://localhost:6006`。

如果只是 BasicSR 第一阶段试训，可用 compose 跑最小命令，不必先配完整 CI。
