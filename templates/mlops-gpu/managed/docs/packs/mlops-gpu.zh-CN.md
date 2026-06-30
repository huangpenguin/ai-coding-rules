# MLOps GPU Pack

`mlops-gpu` 添加 Docker Compose 本地 GPU 环境、GitLab GPU Runner 训练调度和 smoke test。

**独立 pack**：不含 Ruff/pre-commit 配置；不含 GPU quality CI。需要 MR lint 时请单独 `init-ai add ci-quality --apply`。

包含：

- `docker-compose.yml`（本地训练/调试的声明式环境）
- `Dockerfile`（可选：固化依赖后 `build: .`）
- `.cursor/rules/mlops-docker-compose.mdc`（Agent 禁止在宿主机直接跑 ML 代码）
- `.gitlab-ci.yml`（**仅** include `train.yml`）
- `.gitlab/ci/train.yml`
- `train.py`（仅目标项目不存在时创建）
- `scripts/uv-bootstrap.sh`（GitLab GPU job 依赖安装）
- `pyproject-uv-pytorch.snippet.toml`
- Docker / GPU 相关文档

命令：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 本地 GPU 环境（Docker Compose）

**不再使用 Dev Container。** 本地开发与训练通过 `docker-compose.yml`：

```bash
# 一次性：启动可 attach 的环境（可选）
docker compose up -d train

# 跑脚本（推荐）
docker compose run --rm train python train.py

# 交互 shell
docker compose run --rm train bash
```

默认镜像：`nvcr.io/nvidia/pytorch:24.01-py3`。按项目需要改 `image:`，或改为 `build: .` 使用仓库 `Dockerfile`。

TensorBoard 等 UI：compose 已映射 `6006:6006`。

## 三环境分工

| 环境 | 职责 |
|------|------|
| **宿主机** | Git、编辑、Cursor；**禁止**直接 `python` / `pip install` 跑 ML |
| **Docker Compose (`train`)** | 本地 GPU 训练/评估/调试 |
| **GitLab train job** | CI 训练：`scripts/uv-bootstrap.sh` + `gpu_smoke` / `run_training` |

Legacy GPU 项目（如 BasicSR）推荐：`init-ai` → `add mlops-gpu`；宿主机只 commit，训练用 `docker compose run --rm train python ...`。

## 与其他 pack 组合

- **只要 GPU**：本 pack 即可
- **要 CI lint**：另加 `init-ai add ci-quality --apply`，手动合并根 `.gitlab-ci.yml`（见仓库 README）
- **要本地 Git hook**：`init-ai add pre-commit-hooks --apply`，再 `bash scripts/setup-local-hooks.sh`

## Agent 执行协议

inject 后会添加 `.cursor/rules/mlops-docker-compose.mdc`（`alwaysApply: true`）：

- 宿主机无全局 ML Python 环境
- 所有 ML 脚本通过 `docker compose run --rm train python <script.py>`
- 临时依赖在容器内 `pip install`；永久依赖改 `Dockerfile` + `build: .`

## 训练 Runner 要求

- self-hosted Runner，tags: `linux`, `docker`, `gpu`
- executor: `docker`，`gpus = "all"`
- 数据集通过 runner volumes，例如 `/mnt/data:/data:ro`

## 项目 Python 环境（CI）

GitLab GPU job 使用 **`uv run` + `/workspace/.venv`**，由 `scripts/uv-bootstrap.sh` 同步依赖（与本地 compose 的 pip/镜像路径可并存，CI 独立）。

| 项目状态 | bootstrap 行为 |
|----------|----------------|
| `pyproject.toml` + `uv.lock` | `uv sync --frozen --dev` |
| 半迁移 + `requirements.txt` | cu124 index + requirements |
| 仅 `requirements.txt` | `uv venv` + requirements |

本地 compose 默认用 NGC 预装 PyTorch 镜像；CI 仍可用 `MLOPS_GPU_IMAGE`（默认 `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`）。

## 数据挂载

在 `docker-compose.yml` 的 `volumes` 增加宿主机数据路径，例如：

```yaml
volumes:
  - .:/workspace
  - /mnt/data:/workspace/data:ro
```

应用代码读 `DATA_DIR` 或 `/workspace/data`（见 [数据路径环境变量隔离](../use-cases/data-mount-env-isolation.md)）。

GitLab 侧：`DATA_DIR=/data`，由 Runner `config.toml` volumes 挂载。

更多步骤见 [Docker quickstart](../docker/quickstart.zh-CN.md)。

## GitHub Actions 边界

GPU 训练走 GitLab `train.yml`；GitHub Actions quality 属于 `ci-quality` pack。
