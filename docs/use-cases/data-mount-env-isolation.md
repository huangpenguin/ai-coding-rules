# Data mount env isolation

> Standard for mlops-gpu devcontainer and target projects: separate host bind paths from container paths and application code.

## Problem

The default devcontainer bind-mounts only the project to `/workspace`. Host data outside the repo (e.g. sibling `../input/`) is **invisible** inside the container. Hard-coding host paths in Git breaks multi-developer workflows.

Common failures:

- Smoke tests reference `/input`, `../input`, or copy data into `datasets/` as a workaround.
- `containerEnv.DATA_DIR=/data` exists but **no bind mount** populates `/data`.
- Symlinks from `/workspace` to paths outside the workspace bind mount break at runtime.

## Standard (config vs code separation)

| Layer | Committed to Git | Per-developer / per-environment |
|-------|------------------|----------------------------------|
| Container mount target | `/data` | — |
| Container env | `DATA_DIR=/data` | — |
| Host bind source | `${localEnv:DATA_MOUNT_SOURCE}` | Export before Rebuild |
| Application code | Reads `DATA_DIR` + relative paths | Optional dataset overrides |

**Do not** put `/home/...` or other host paths in committed JSON or Python.

## Devcontainer contract

Committed [`.devcontainer/devcontainer.json`](../../templates/mlops-gpu/managed/.devcontainer/devcontainer.json) includes:

- `workspaceMount` + `workspaceFolder=/workspace`
- `remoteUser` + `updateRemoteUserUID`
- `initializeCommand` — validates `DATA_MOUNT_SOURCE` and triggers autofs via `ls`
- `mounts` — `source=${localEnv:DATA_MOUNT_SOURCE},target=/data,type=bind`
- `containerEnv.DATA_DIR=/data`

Data bind mounts are **runtime devcontainer config**, not Dockerfile changes.

## Rebuild workflow

### One-time host checks

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### Before every Rebuild (datasets required)

```bash
export DATA_MOUNT_SOURCE=/path/on/docker-host
test -n "$DATA_MOUNT_SOURCE" && ls "$DATA_MOUNT_SOURCE" >/dev/null && test -d "$DATA_MOUNT_SOURCE"
```

Then **Rebuild Container** in the IDE.

### GPU smoke only (no datasets)

```bash
export DATA_MOUNT_SOURCE="${HOME}/.local/share/mlops-empty-data"
mkdir -p "$DATA_MOUNT_SOURCE"
```

### After Rebuild

```bash
echo "DATA_DIR=$DATA_DIR"
ls "$DATA_DIR"
uv run python train.py
```

Full operator runbook: [`.devcontainer/README.md`](../../templates/mlops-gpu/managed/.devcontainer/README.md).

## Application code

Read `DATA_DIR` only; use relative paths under the data root:

```python
from pathlib import Path
import os

data_dir = Path(os.environ["DATA_DIR"])
dataset = data_dir / "data_0607" / "my_subset"
```

Optional helper (injected via `preserve/scripts/data_paths.py`):

```python
from scripts.data_paths import data_root, resolve_dataset_dir

root = data_root()
subset = resolve_dataset_dir("data_0607", "my_subset")
# Per-dataset override example (document only — set in shell or CI):
# export MY_DATASET_DIR=/data/custom/path
custom = resolve_dataset_dir("data_0607", "my_subset", env_override="MY_DATASET_DIR")
```

Resolution order: env override → `DATA_DIR`/relative → `datasets/` legacy fallback.

## CI / Kubernetes parity

Same contract in production:

- Volume mount → `/data`
- Env `DATA_DIR=/data`
- Application code unchanged

GitLab CI: set `DATA_MOUNT_SOURCE` in **Settings → CI/CD → Variables** (host path on the GPU runner). See [GPU Runner workflow](gpu-runner.zh-CN.md).

## What NOT to do

- Do not mount data by editing Dockerfile.
- Do not commit personal host paths in `devcontainer.json`.
- Do not rely on symlinks to paths outside `/workspace` without mounting the target.
- Do not assume project `.env` auto-loads `${localEnv:DATA_MOUNT_SOURCE}` — export on the host or use gitignored `devcontainer.local.json`.

## Verification checklist

- [ ] `devcontainer.json` has mounts + initializeCommand + `DATA_DIR`
- [ ] `.devcontainer/README.md` documents Rebuild before/after steps
- [ ] `data-mount.env.example` documents shell profile snippet
- [ ] Application code uses `DATA_DIR` only (no hardcoded host paths)
- [ ] Rebuild Container after mount changes (not Dockerfile rebuild for data)
