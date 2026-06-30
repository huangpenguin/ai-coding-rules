# 数据路径环境变量隔离

> mlops-gpu 标准做法：宿主机 bind 路径、容器路径、应用代码三层分离（Docker Compose + GitLab CI）。

## 问题

Docker Compose 默认只把项目挂到 `/workspace`。仓库外的宿主机数据在容器内**不可见**。把宿主机路径写进 Git 会破坏多人协作。

常见失败：

- smoke test 引用 `/input`、`../input`，或把数据拷进 `datasets/` 凑合用。
- 配置了 `DATA_DIR=/data`，但 compose **没有** 对应 volume。
- 在 `/workspace` 里 symlink 到 workspace 外的路径，运行时失效。

## 标准（配置 vs 代码分离）

| 层 | 提交 Git | 每人 / 每环境 |
|----|----------|---------------|
| 容器数据路径 | compose 中 mount 目标（如 `/workspace/data`） | — |
| 容器环境变量 | `DATA_DIR=/workspace/data`（可选） | — |
| 宿主机 bind 源 | 不提交 | 每人改 `docker-compose.override.yml` 或本地 compose volumes |
| 应用代码 | 读 `DATA_DIR` + 相对路径 | 可选 per-dataset override |

**不要**在已提交的 Python 里写 `/home/...` 等宿主机路径。

## Docker Compose 契约

已提交的 `docker-compose.yml` 包含：

- `.:/workspace` — 代码同步
- `working_dir: /workspace`
- GPU：`deploy.resources.reservations.devices`（NVIDIA）
- 数据 mount 占位注释 — 各环境在 override 或本地编辑中添加

### 本地数据 mount 示例

创建 **gitignore** 的 `docker-compose.override.yml`（不提交）：

```yaml
services:
  train:
    volumes:
      - .:/workspace
      - /mnt/data:/workspace/data:ro
    environment:
      DATA_DIR: /workspace/data
```

或直接在 `docker-compose.yml` 的 TODO 处取消注释并改成真实路径（仅单机开发时）。

### 验证

```bash
docker compose run --rm train bash -lc 'echo "DATA_DIR=$DATA_DIR"; ls -la "${DATA_DIR:-/workspace}"'
docker compose run --rm train python train.py
```

## GitLab CI 契约

GitLab Docker executor 使用容器内 `DATA_DIR=/data`。宿主机数据路径由 GPU Runner 的 `config.toml` volumes 挂载，例如 `/mnt/data:/data:ro`，不在 `.gitlab-ci.yml` 中写死宿主机路径。

## 应用代码

只读 `DATA_DIR`，在其下用相对路径：

```python
from pathlib import Path
import os

data_root = Path(os.environ.get("DATA_DIR", "/workspace/data"))
dataset_path = data_root / "my_dataset"
```

preserve 片段 `scripts/data_paths.py` 提供可选 helper。

## 团队开发

| 开发者 | 宿主机数据 | compose override |
|--------|-----------|------------------|
| Alice | `/home/alice/data` | `- /home/alice/data:/workspace/data:ro` |
| Bob | `/mnt/data` | `- /mnt/data:/workspace/data:ro` |

容器内统一读 `DATA_DIR` + 相对路径。

## 相关文档

- [Docker quickstart](../docker/quickstart.zh-CN.md)
- [mlops-gpu pack 说明](../packs/mlops-gpu.zh-CN.md)
