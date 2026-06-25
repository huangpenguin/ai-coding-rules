# Dev Container Operator Runbook

Code lives in **`/workspace`**. Datasets on the Docker host are bind-mounted to **`/data`**.

Application code reads **`DATA_DIR`** (fixed to `/data` inside the container) plus relative paths such as `data_0607/...`. Do not commit host-specific paths to Git.

## Architecture

| Layer | Committed to Git | Per-developer |
|-------|------------------|---------------|
| Container mount target | `/data` | — |
| Container env | `DATA_DIR=/data` | — |
| Host bind source | `${localEnv:DATA_MOUNT_SOURCE}` in devcontainer.json | Each dev exports before Rebuild |
| Application code | Reads `DATA_DIR` + relative paths | Optional per-dataset overrides |

## A. One-time host prerequisites (new GPU machine)

Run on the **Docker host** (e.g. main_gpu):

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

If `docker info` fails with permission denied, add your user to the `docker` group and start a new login session.

See also [CUDA driver matrix](../docs/docker/cuda-driver-matrix.zh-CN.md).

## B. First-time project setup (after inject)

```bash
init-ai add mlops-gpu --apply
```

Ensure `python-quality` pack is applied so `.gitignore` includes `.devcontainer/devcontainer.local.json`.

On **Rebuild Container**, `postCreateCommand` runs `scripts/uv-bootstrap.sh` — the same script GitLab GPU jobs use. This creates `/workspace/.venv` and installs runtime + dev dependencies.

| Project state | What bootstrap does |
|---------------|---------------------|
| `pyproject.toml` + `uv.lock` | `uv sync --frozen --dev` |
| Semi-migrated (`dependencies = []` + `requirements.txt`) | Install from `requirements.txt` (cu124 index for torch) + dev tools |
| `requirements.txt` only | `uv venv` + requirements + optional `uv pip install -e .` |
| `pyproject.toml` only | `uv sync --dev` |

**Do not** run only `uv sync --dev` on legacy projects and assume torch/opencv/etc. are installed.

VS Code interpreter is set to `/workspace/.venv/bin/python` (matches `uv run`).

The Docker base image still contains conda PyTorch for reference, but **project commands use `.venv`**, not `/opt/conda`.

## C. Before every Rebuild Container

**Required when you need real datasets** (default template behavior):

```bash
export DATA_MOUNT_SOURCE=/path/on/docker-host
test -n "$DATA_MOUNT_SOURCE" && ls "$DATA_MOUNT_SOURCE" >/dev/null && test -d "$DATA_MOUNT_SOURCE"
```

Notes:

- `DATA_MOUNT_SOURCE` must be a **local path on the Docker host**, not an NFS export string (`192.168.x.x:/mnt/...`).
- For **autofs**, `ls` triggers the mount before Docker bind.
- The IDE must see this variable: export in the same shell before launching Cursor, or add to `~/.zshrc` / `~/.bashrc`.
- Example snippet: [`data-mount.env.example`](data-mount.env.example) (copy to shell profile; not auto-loaded).

Then **Rebuild Container** (not Reload Window). No Dockerfile change is required for data mounts.

### GPU smoke only (no real data)

```bash
export DATA_MOUNT_SOURCE="${HOME}/.local/share/mlops-empty-data"
mkdir -p "$DATA_MOUNT_SOURCE"
```

Rebuild passes validation; `/data` is empty and `train.py` smoke still runs.

### Rebuild vs Reload

| Change | Action |
|--------|--------|
| `DATA_MOUNT_SOURCE` or mounts | **Rebuild Container** |
| Python / config in repo | No Rebuild |
| Dockerfile base image / apt packages | **Rebuild Container** |

## D. After Rebuild — verification

Inside the container:

```bash
echo "DATA_DIR=$DATA_DIR"
nvidia-smi
ls "$DATA_DIR"
uv run python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
uv run python train.py
```

Expected: `DATA_DIR=/data`; GPU visible; torch in `.venv` is `2.6.x+cu124` with CUDA available on V100 (`sm_70`).

## E. Team members with different host paths

Each developer sets their own path before Rebuild:

```bash
export DATA_MOUNT_SOURCE=/home/alice/data
export DATA_MOUNT_SOURCE=/mnt/data
export DATA_MOUNT_SOURCE=/D/data
```

Code uses only `$DATA_DIR/relative/path` — no host paths in Git.

## F. If you forget to export

1. **Persistent shell profile** — add `export DATA_MOUNT_SOURCE=...` to `~/.zshrc`.
2. **Gitignored override** — copy [`devcontainer.local.json.example`](devcontainer.local.json.example) to `devcontainer.local.json` and set a hardcoded mount (Option B–E).

Do **not** commit personal paths into `devcontainer.json`.

## G. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `ERROR: export DATA_MOUNT_SOURCE before Rebuild` | Host env unset | Export path, Rebuild |
| `bind source path does not exist` | Wrong host path or autofs not triggered | `ls /mnt/data`; fix `DATA_MOUNT_SOURCE` |
| `permission denied` connecting to Docker | User not in `docker` group | `docker info`; fix group membership |
| `/data` empty inside container | Mount skipped or wrong source | Rebuild after export; verify host path |
| Data outside repo invisible | Only `/workspace` mounted by default | Use `/data` bind mount, not symlinks to `../input` |
| Agent reinstalls huge torch from PyPI | Only `uv sync --dev` on semi-migrated project | Rebuild Container (runs `uv-bootstrap.sh`); migrate with `pyproject-uv-pytorch.snippet.toml` |
| `torch.cuda.is_available()` false on V100 | Wrong torch build (e.g. 2.12 from PyPI) | Ensure `uv-bootstrap.sh` ran; pin cu124 via snippet or `MLOPS_PYTORCH_INDEX` |

More: [Data mount env isolation](../docs/use-cases/data-mount-env-isolation.md), [GPU Runner workflow](../docs/use-cases/gpu-runner.zh-CN.md).

## H. CI parity

GitLab CI keeps the same in-container contract: `DATA_DIR=/data` in training code. With Docker executor, mount the GPU host path in the Runner `config.toml` volumes, for example `/mnt/data:/data:ro`.
