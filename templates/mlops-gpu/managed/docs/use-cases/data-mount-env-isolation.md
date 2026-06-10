# 数据路径环境变量隔离

> mlops-gpu devcontainer 与目标项目的标准做法：宿主机 bind 路径、容器路径、应用代码三层分离。

## 问题

devcontainer 默认只把项目挂到 `/workspace`。仓库外的宿主机数据（例如 sibling `../input/`）在容器内**不可见**。把宿主机路径写进 Git 会破坏多人协作。

常见失败：

- smoke test 引用 `/input`、`../input`，或把数据拷进 `datasets/` 凑合用。
- 配置了 `containerEnv.DATA_DIR=/data`，但**没有 bind mount** 填充 `/data`。
- 在 `/workspace` 里 symlink 到 workspace 外的路径，运行时失效。

## 标准（配置 vs 代码分离）

| 层 | 提交 Git | 每人 / 每环境 |
|----|----------|---------------|
| 容器挂载目标 | `/data` | — |
| 容器环境变量 | `DATA_DIR=/data` | — |
| 宿主机 bind 源 | `${localEnv:DATA_MOUNT_SOURCE}` | Rebuild 前 export |
| 应用代码 | 读 `DATA_DIR` + 相对路径 | 可选 per-dataset override |

**不要**在已提交的 JSON / Python 里写 `/home/...` 等宿主机路径。

## Devcontainer 契约

已提交的 `.devcontainer/devcontainer.json` 包含：

- `workspaceMount` + `workspaceFolder=/workspace`
- `remoteUser` + `updateRemoteUserUID`
- `initializeCommand` — 校验 `DATA_MOUNT_SOURCE`，`ls` 触发 autofs
- `mounts` — `source=${localEnv:DATA_MOUNT_SOURCE},target=/data,type=bind`
- `containerEnv.DATA_DIR=/data`

数据 bind mount 是 **devcontainer 运行时配置**，不要写进 Dockerfile。

## Rebuild 流程

### 宿主机一次性检查

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### 每次 Rebuild 前（需要真实数据）

```bash
export DATA_MOUNT_SOURCE=/path/on/docker-host
test -n "$DATA_MOUNT_SOURCE" && ls "$DATA_MOUNT_SOURCE" >/dev/null && test -d "$DATA_MOUNT_SOURCE"
```

然后在 IDE 中 **Rebuild Container**。

### 仅 GPU smoke（无数据集）

```bash
export DATA_MOUNT_SOURCE="${HOME}/.local/share/mlops-empty-data"
mkdir -p "$DATA_MOUNT_SOURCE"
```

### Rebuild 后验证

```bash
echo "DATA_DIR=$DATA_DIR"
ls "$DATA_DIR"
uv run python train.py
```

完整操作手册见 [`.devcontainer/README.md`](../../.devcontainer/README.md)。

## 应用代码

只读 `DATA_DIR`，在其下用相对路径：

```python
from pathlib import Path
import os

data_dir = Path(os.environ["DATA_DIR"])
dataset = data_dir / "data_0607" / "my_subset"
```

可选 helper（`preserve/scripts/data_paths.py`，inject 时仅缺失则添加）：

```python
from scripts.data_paths import data_root, resolve_dataset_dir

root = data_root()
subset = resolve_dataset_dir("data_0607", "my_subset")
# Per-dataset override 示例（文档说明，在 shell 或 CI 中设置）：
# export MY_DATASET_DIR=/data/custom/path
custom = resolve_dataset_dir("data_0607", "my_subset", env_override="MY_DATASET_DIR")
```

解析顺序：env override → `DATA_DIR`/相对路径 → `datasets/` legacy fallback。

## CI / Kubernetes 对齐

生产环境同一契约：

- Volume mount → `/data`
- Env `DATA_DIR=/data`
- 应用代码不变

GitLab CI：在 **Settings → CI/CD → Variables** 设置 `DATA_MOUNT_SOURCE`（GPU Runner 宿主机路径）。见 [GPU Runner workflow](gpu-runner.zh-CN.md)。

## 禁止事项

- 不要用 Dockerfile 做数据 bind mount。
- 不要把个人宿主机路径 commit 进 `devcontainer.json`。
- 不要依赖 workspace 外路径的 symlink 而不挂载目标目录。
- 不要假设项目 `.env` 会自动填充 `${localEnv:DATA_MOUNT_SOURCE}` — 在宿主机 export 或使用 gitignore 的 `devcontainer.local.json`。

## 验证清单

- [ ] `devcontainer.json` 含 mounts、initializeCommand、`DATA_DIR`
- [ ] `.devcontainer/README.md` 含 Rebuild 前/后步骤
- [ ] `data-mount.env.example` 说明 shell profile 用法
- [ ] 应用代码只用 `DATA_DIR`（无硬编码宿主机路径）
- [ ] 改挂载后 Rebuild Container（数据挂载不需要改 Dockerfile）
