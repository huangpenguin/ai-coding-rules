# MLOps GPU Pack

`mlops-gpu` 添加 **Docker Compose + 薄 Dev Container** 本地 GPU 环境、GitLab GPU Runner 训练调度与 smoke test。

**独立 pack**：不含 Ruff / pre-commit；不含 GPU quality CI。需要 MR lint 时 `init-ai add ci-quality --apply`。

## 包含文件

| 文件 | 作用 |
|------|------|
| `docker-compose.yml` | 环境真源：GPU、挂载、端口、shm |
| `Dockerfile` | `build: .` 基底（与 CI 同一镜像 tag） |
| `.devcontainer/devcontainer.json` | IDE 接入 compose `train`（不重复 GPU/mount） |
| `.cursor/rules/mlops-docker-compose.mdc` | Agent：禁止宿主机跑 ML |
| `scripts/uv-bootstrap.sh` | postCreate + GitLab job 依赖安装 |
| `scripts/ci_storage.py` | CI job 训练产出落盘路径规划（NFS / fallback） |
| `.gitlab-ci.yml` + `.gitlab/ci/train.yml` | GPU 训练 CI |
| `train.py` | GPU 训练 smoke：真 backward + checkpoint（目标无则创建） |

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 固定环境栈（本地 = CI 同一基底）

| 层 | 默认 |
|----|------|
| 镜像 | `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel` |
| 本地 | `docker-compose.yml` → `build: .` → 上述 Dockerfile |
| CI | `MLOPS_GPU_IMAGE` = 同一 tag |
| PyTorch | `torch 2.6.x + cu124`（项目 `.venv` 内由 `uv-bootstrap.sh` 安装） |
| cuDNN | 9.x |
| 已验证 GPU | NVIDIA V100，`sm_70`，32GB |

本地 `build: .` 与 CI 直接拉镜像是**同一基底**的两种启动方式；项目依赖统一装进 `/workspace/.venv`（`uv-bootstrap.sh`），不是第三套环境。镜像内 conda PyTorch 仅作参考，**命令走 `.venv`**（`uv run`）。

目标宿主：Ubuntu 24.04 + NVIDIA driver `570-server` 或更高。**宿主机 driver 必须支持容器内 CUDA runtime**。

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

torch 约束（`requirements.txt` / `pyproject.toml`）：

```text
torch>=2.6.0,<2.7.0
```

不要写 `torch>=1.7` 等过宽约束。cu124 index 由 `uv-bootstrap.sh` 处理 legacy requirements；迁 lock 后可在 `pyproject.toml` 加：

```toml
[[tool.uv.index]]
name = "pytorch-cu124"
url = "https://download.pytorch.org/whl/cu124"
explicit = true

[tool.uv.sources]
torch = { index = "pytorch-cu124" }
```

## 三环境分工

| 环境 | 职责 |
|------|------|
| **宿主机** | Git、编辑、Cursor；**禁止** `python` / `pip` / `uv run` 跑 ML |
| **Compose / Dev Container** | 本地 GPU 训练；IDE 用 Reopen in Container |
| **GitLab train job** | `uv-bootstrap.sh` + `ci_storage.py` + `gpu_smoke` / `run_training` |

## 本地开发

### 构建与运行

```bash
docker compose build

# 跑 smoke / 训练（推荐）
docker compose run --rm train uv run python train.py

# 交互 shell
docker compose run --rm train bash

# 可选：后台常驻
docker compose up -d train
docker compose exec train bash
```

CLI 首次若无 `.venv`（未 Reopen in Container）：

```bash
docker compose run --rm train bash scripts/uv-bootstrap.sh
```

### IDE：Reopen in Container

1. `docker compose build`
2. Cursor：**Reopen in Container**（attach `train` service）
3. `postCreateCommand` 自动执行 `bash scripts/uv-bootstrap.sh`
4. 解释器：`/workspace/.venv/bin/python`

验证：

```bash
nvidia-smi
uv run python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
uv run python train.py
```

TensorBoard：compose 已映射 `6006:6006`，浏览器访问 `http://localhost:6006`。

### 不用 Compose 文件时（调试用）

```bash
docker build -t my-project-gpu .
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /mnt/data:/data:ro \
  -e DATA_DIR=/data \
  -w /workspace \
  my-project-gpu bash -lc "bash scripts/uv-bootstrap.sh && uv run python train.py"
```

## 改数据盘路径

编辑 `docker-compose.yml` 中 `train.volumes` 的第二行：

```yaml
    volumes:
      - .:/workspace
      - /你的宿主机路径:/data:ro
```

容器内统一 `DATA_DIR=/data`。应用代码只读 `DATA_DIR` + 相对路径，**不要**在 Python 里写 `/home/...` 等宿主机路径。

```python
from pathlib import Path
import os

data_root = Path(os.environ.get("DATA_DIR", "/data"))
dataset_path = data_root / "my_dataset"
```

验证：

```bash
docker compose run --rm train bash -lc 'echo "DATA_DIR=$DATA_DIR"; ls -la "$DATA_DIR"'
docker compose run --rm train uv run python train.py
```

**GitLab CI**：容器内同样 `DATA_DIR=/data`；宿主机路径在 Runner `config.toml` 的 `volumes` 配置（见下文），不在 `.gitlab-ci.yml` 写死。

常见错误：配置了 `DATA_DIR` 但 compose 无对应 volume；在 `/workspace` 下 symlink 到仓库外路径。

## 依赖与 uv-bootstrap

`scripts/uv-bootstrap.sh` 用于 **Dev Container postCreate** 与 **GitLab GPU before_script**。

| 项目状态 | 行为 |
|----------|------|
| `pyproject.toml` + `uv.lock` | `uv sync --frozen --dev` |
| 半迁移（空 `dependencies` + `requirements.txt`） | requirements（cu124）+ dev 工具 |
| 仅 `requirements.txt` | `uv venv` + requirements + 可选 `uv pip install -e .` |
| 仅 `pyproject.toml` | `uv sync --dev` |
| 无依赖文件 | 使用镜像基底 |

**不要**在半迁移/legacy 项目上只跑 `uv sync --dev` 就认为 torch 等已装好。

迁移到 lock：`uv lock && uv sync --frozen --dev`，提交 `uv.lock`，再删 `requirements.txt`。

### 固化依赖进 Dockerfile（稳定后）

bind mount 会盖住 `/workspace/.venv`，镜像内依赖应放 `/opt/mlops-venv`：

```dockerfile
ENV UV_PROJECT_ENVIRONMENT=/opt/mlops-venv
ENV PATH="/opt/mlops-venv/bin:${PATH}"

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
```

系统包示例：`libgl1`、`libglib2.0-0`、`ffmpeg`、`git-lfs`（按项目需要）。

## 改训练命令

GitLab CI 变量（Settings → CI/CD → Variables 或 `.gitlab-ci.yml`）：

```bash
TRAIN_COMMAND="python train.py"
SMOKE_COMMAND="python train.py"
# 或项目入口，例如：
TRAIN_COMMAND="python basicsr/train.py -opt options/train/xxx.yml"
```

有 lock 后也可用：`TRAIN_COMMAND="uv run python train.py"`。

### BasicSR / 真实训练项目

将 `TRAIN_COMMAND` 换成项目入口，并通过 CLI 或环境变量把实验目录指到 CI 持久盘，例如：

```bash
TRAIN_COMMAND='python basicsr/train.py -opt options/train/xxx.yml --force_yml path:experiments_root=${TRAIN_EXPERIMENTS_ROOT}'
```

`before_script` 里 `ci_storage.py prepare` 会导出 `TRAIN_EXPERIMENTS_ROOT`、`TRAIN_TB_LOGGER_ROOT`。本地开发不设这些变量时，`train.py` 默认写 `./experiments`。

## CI 训练产出落盘

GitLab job 的 `CI_PROJECT_DIR` 是**临时 checkout**，容器销毁后默认不保留大 checkpoint。本 pack 采用**双轨**：

| 轨道 | 路径 | 用途 |
|------|------|------|
| **主存储** | NFS：`/home/{user}/mlops_storage/ci_outputs/{PipelineID}/` | checkpoint、TB log；SSH 直接查看 |
| **副存储** | workspace `results/mlops_train/` → GitLab Artifacts | 小文件摘要（`train_summary.json`、路径 hint），默认 14 天 |

`scripts/ci_storage.py` 在 `before_script` 执行：

```bash
eval "$(python scripts/ci_storage.py prepare --write-markers --latest-symlink --emit-shell)"
```

行为摘要：

1. 按优先级选可写根：`/home/{user}/mlops_storage` → `/mnt/home/...` → `/cache/...` → 仓库内 `.ci_storage/`（fallback）
2. 创建 `ci_outputs/{CI_PIPELINE_ID}/experiments` 与 `tb_logger`
3. 导出 `TRAIN_EXPERIMENTS_ROOT` 等环境变量
4. 写 marker 文件（`.ci_experiments_root` 等）供 `after_script` 收集 artifacts
5. 更新 `ci_outputs/latest` 软链，便于 SSH `tail` / TensorBoard

默认 `train.py` 会：在 GPU 上跑短训练循环、写 `checkpoints/latest.pt` 与 `logs/train_summary.json`。

**Runner 推荐 volumes**（在只读数据盘之外加可写 home）：

```toml
volumes = ["/cache", "/mnt/data:/data:ro", "/mnt/home:/home:rw"]
```

设置 `MLOPS_STORAGE_USER`（或与 NFS 账号对齐的 `CST_STORAGE_USER`）为 Runner 上的 Unix 用户名。

`.gitignore` 建议追加（若已有 `python-quality` 的 `.gitignore`，手动合并）：

```gitignore
experiments/
tb_logger/
.ci_storage/
.ci_experiments_root
.ci_tb_logger_root
.ci_storage_host_hint
results/mlops_train/
```

## GitLab GPU Runner

要求：self-hosted；executor `docker`；tags `linux`, `docker`, `gpu`；`gpus = "all"`。

注册：

```bash
sudo gitlab-runner register \
  --url https://gitlab.com \
  --token glrt-xxxx \
  --executor docker \
  --docker-image pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

`/etc/gitlab-runner/config.toml` 示例：

```toml
concurrent = 1

[[runners]]
  executor = "docker"
  [runners.docker]
    image = "pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel"
    gpus = "all"
    shm_size = 17179869184
    volumes = ["/cache", "/mnt/data:/data:ro", "/mnt/home:/home:rw"]
```

- `concurrent = 1`：单台 GPU 服务器一次一个 GPU job。
- `/mnt/data:/data:ro` 左侧必须是 **Runner 宿主机本地路径**，不要写 NFS export 字符串（如 `192.168.x.x:/mnt/...`）。
- `/mnt/home:/home:rw` 用于 **checkpoint 持久化**（见上文 `ci_storage.py`）；无 NFS 时会 fallback 到 `.ci_storage/`。

触发：Pipeline 手动 Play `gpu_smoke` → `run_training`；或 commit message 含 `[run train]`。

手动验证与 CI 相同镜像：

```bash
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -w /workspace \
  pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel \
  bash -lc "bash scripts/uv-bootstrap.sh && python train.py"
```

默认变量：

```yaml
MLOPS_GPU_IMAGE: "pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel"
DATA_DIR: "/data"
MLOPS_STORAGE_USER: "<your-unix-user-on-gpu-host>"
TRAIN_RUN_NAME: "smoke_linear"
```

## 与其他 pack 组合

| 需求 | 命令 |
|------|------|
| 只要 GPU | 本 pack |
| CI lint | `init-ai add ci-quality --apply`；手动合并 `.gitlab-ci.yml`（见模板仓库 README） |
| 本地 Git hook | `init-ai add pre-commit-hooks --apply` |
| Ruff 规则 | `init-ai add python-quality --apply` |

Legacy GPU（如 BasicSR）：`init-ai` → `add mlops-gpu`；训练用 `docker compose run --rm train uv run python ...`。

## Agent 规则

见 `.cursor/rules/mlops-docker-compose.mdc`（`alwaysApply: true`）。

## GitHub Actions

GPU 训练走 GitLab `train.yml`；GitHub quality 属于 `ci-quality` pack。
