# MLOps GPU Pack

`mlops-gpu` 添加 Docker、devcontainer、GitLab GPU Runner 训练调度和 smoke test。

**独立 pack**：不含 Ruff/pre-commit 配置（需 `ci-quality` 时自动带上 `python-quality`）；不含 GPU quality CI。需要 MR lint 时请单独 `init-ai add ci-quality --apply`。

包含：

- `Dockerfile`
- `.devcontainer/devcontainer.json`
- `.devcontainer/README.md`（Rebuild 前/后操作手册）
- `.devcontainer/data-mount.env.example`（shell profile 片段，不会自动加载）
- `.devcontainer/devcontainer.local.json.example`（gitignore 本地挂载备选）
- `.gitlab-ci.yml`（**仅** include `train.yml`）
- `.gitlab/ci/train.yml`
- `train.py`（仅目标项目不存在时创建）
- `scripts/uv-bootstrap.sh`（devcontainer 与 GitLab GPU job 共用依赖安装逻辑）
- `pyproject-uv-pytorch.snippet.toml`（从 requirements.txt 迁到 pyproject.toml + uv.lock 时的 cu124 片段）
- Docker / GPU 相关文档

命令：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 三环境分工（宿主机 vs 容器）

| 环境 | 职责 |
|------|------|
| **宿主机** | 可选 `git` + 编辑；**不要** `uv sync --dev` 装 torch。本地 Git hook 为可选：`init-ai add pre-commit-hooks` |
| **Dev Container** | 全量 runtime + dev：`postCreateCommand` → `scripts/uv-bootstrap.sh` |
| **GitLab train job** | 同上 bootstrap，跑 `gpu_smoke` / `run_training` |

Legacy GPU 项目（如 BasicSR）推荐：`init-ai` → `add mlops-gpu`；宿主机直接 commit，Rebuild devcontainer 后在容器内训练。

## 与其他 pack 组合

- **只要 GPU**：本 pack 即可（不含 quality CI、不含 ruff hook）
- **要 CI lint**：另加 `init-ai add ci-quality --apply`，并手动合并根 `.gitlab-ci.yml`（见仓库 README「Combine GitLab CI」）
- **要本地 Git hook**：`init-ai add pre-commit-hooks --apply`，再 `bash scripts/setup-local-hooks.sh`

训练 Runner 要求：

- self-hosted Runner
- tags: `linux`, `docker`, `gpu`
- executor: `docker`
- GPU 宿主机已安装 Docker + NVIDIA driver + NVIDIA Container Toolkit
- Runner `config.toml` 中设置 `[runners.docker] gpus = "all"`
- 数据集通过 runner volumes 挂载，例如 `/mnt/data:/data:ro`

## 项目 Python 环境（镜像 vs `.venv`）

GPU 基础镜像（conda）里已有 PyTorch，但模板工作流统一走 **`uv run` + `/workspace/.venv`**。镜像 conda 与项目 venv **不是同一套环境**。

devcontainer `postCreateCommand` 与 GitLab GPU `before_script` 都执行：

```bash
bash scripts/uv-bootstrap.sh
```

| 项目状态 | bootstrap 行为 |
|----------|----------------|
| `pyproject.toml` + `uv.lock` | `uv sync --frozen --dev` |
| 半迁移（`dependencies = []` + `requirements.txt`） | 从 requirements 装运行时依赖（cu124 index）+ dev 工具 |
| 仅 `requirements.txt` | `uv venv` + requirements（含 torch 时用 cu124）+ 可选 `uv pip install -e .` |
| 仅 `pyproject.toml` | `uv sync --dev` |
| 无依赖文件 | 仅用基础镜像 |

**半迁移陷阱**：inject `python-quality` 后常有空 `pyproject.toml` 和完整 `requirements.txt`。只跑 `uv sync --dev` 会误以为环境就绪，实际 torch 等运行时依赖全缺。

VS Code interpreter 指向 `/workspace/.venv/bin/python`，与 `uv run` 一致。

迁移到 lock 工作流：合并 `pyproject-uv-pytorch.snippet.toml`，写入 `[project].dependencies`，`uv lock && uv sync --frozen --dev`，提交 `uv.lock`。

## GPU 镜像与依赖管理

本 pack 默认先使用 `MLOPS_GPU_IMAGE` 指定的 GPU 基础镜像运行 GitLab job：

```text
pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

项目依赖由 GitLab job 内的 `uv` 步骤同步；需要更快或更稳定时，再把依赖固化进项目 Dockerfile，构建并推送到 registry，然后把 `MLOPS_GPU_IMAGE` 改为项目镜像。

推荐工作流：

1. 新仓库没有环境文件时，先直接使用默认 PyTorch/CUDA 镜像跑 `gpu_smoke`。
2. 用 `gpu_smoke` 或本地 `docker run --gpus all` 验证 GPU、torch、CUDA、cuDNN。
3. 需要加 Python 包时，优先提交 `pyproject.toml` + `uv.lock`；`uv-bootstrap.sh` 会执行 `uv sync --frozen --dev`。
4. 旧项目只有 `requirements.txt`（或半迁移状态）时，由 `uv-bootstrap.sh` 自动从 requirements 安装，并对 torch 使用 cu124 index。
5. 不要把项目依赖安装到 GPU Runner 宿主机；宿主机只负责 Docker、NVIDIA runtime 和 GitLab Runner。

详细方法见 [Customize Dockerfile](../docker/customize-dockerfile.zh-CN.md)。

## 默认 GPU / PyTorch 组合

模板默认使用 `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`，对应 `torch 2.6.x + cu124`、CUDA 12.4、cuDNN 9.x。该组合已按 V100（`sm_70`）保守验证。

如果目标项目需要在 `requirements.txt` 或 `pyproject.toml` 里声明 `torch`，建议 pin 到：

```text
torch>=2.6.0,<2.7.0
```

不要使用 `torch>=1.7` 这类过宽约束。仅写 minor pin 不够时，legacy `requirements.txt` 路径由 `uv-bootstrap.sh` 自动加 `--extra-index-url https://download.pytorch.org/whl/cu124`；迁移到 `pyproject.toml` 后请用 `pyproject-uv-pytorch.snippet.toml` 里的 `[tool.uv.index]` / `[tool.uv.sources]`。

## Dev Container 基线（inject 后不要删）

- `workspaceMount` + `workspaceFolder=/workspace`：只 bind **项目仓库**，与 Dockerfile `WORKDIR` 一致；IDE 中打开 repo 根目录，不要以 `$HOME` 为工作区。
- `remoteUser` + `updateRemoteUserUID`：避免 bind mount 后文件属主不匹配。
- `mounts`：仅 `${localEnv:DATA_MOUNT_SOURCE}` → `/data`（数据集目录）；**禁止**把整个 `$HOME` bind 到 `/home/vscode`（会导致 `.cursor-server` / 缓存冲突，服务器重启后常见）。
- `initializeCommand`：校验 `DATA_MOUNT_SOURCE` 存在，并用 `ls` 触发 autofs。
- `containerEnv.DATA_DIR=/data`：应用代码只读此变量 + 相对路径。
- 可选：Named Volume 只挂 uv 缓存目录（见 `devcontainer.local.json.example` Option F），不要挂整个家目录。

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
