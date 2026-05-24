# MLOps Acceptance Checklist

Use this checklist after running `init-ai` in a target project or after updating this template repository.

## 1. Template injection

- [ ] Run `init-ai` (or `init-ai --update --dry-run` then `--apply`) in a test project.
- [ ] Confirm these files exist:
  - `.gitlab-ci.yml`
  - `.gitlab/ci/quality.yml`
  - `.gitlab/ci/train.yml`
  - `Dockerfile`
  - `.devcontainer/devcontainer.json`
  - `train.py`
- [ ] Confirm an existing project `train.py` is preserved during update mode.

## 2. Local quality checks

```bash
uv run ruff check .
uv run ruff format --check .
uv run pyright
```

- [ ] All checks pass in the template repo or injected project.

## 3. GPU server prerequisites

On each GPU server:

```bash
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
groups
ls /mnt/nfs_data
```

- [ ] NVIDIA Container Toolkit works.
- [ ] Runner user can run Docker.
- [ ] Dataset mount path exists, or update `.devcontainer/devcontainer.json` and GitLab CI variables first.

If `/mnt/nfs_data` does not exist yet:

```bash
sudo mkdir -p /mnt/nfs_data
sudo chown "$USER":"$USER" /mnt/nfs_data
```

## 4. Docker smoke test

```bash
docker build -t mlops-test .
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /mnt/nfs_data:/data \
  mlops-test bash -lc "python train.py"
```

- [ ] Container starts successfully.
- [ ] `CUDA available: True` appears when GPU is present.
- [ ] Data mount status is printed.
- [ ] Smoke training loop completes.

## 5. GitLab Runner training dispatch

Register a self-hosted runner with tag `gpu-server`, then push to GitLab.

**Important: use the `shell` executor, not the `docker` executor.**

`run_training` runs `docker build` and `docker run --gpus all` directly on the GPU host. If the runner uses the `docker` executor, the job runs inside an `ubuntu:22.04` helper container with no Docker CLI and no GPU access. Typical failure:

```text
/usr/bin/bash: docker: command not found
```

On the GPU server, inspect the runner config:

```bash
sudo cat /etc/gitlab-runner/config.toml
# or for user-mode runners: cat ~/.gitlab-runner/config.toml
```

The runner block should contain:

```toml
[[runners]]
  executor = "shell"
```

If it currently says `executor = "docker"`, switch it to `shell` and restart the runner:

```bash
sudo gitlab-runner restart
```

- [ ] Pipeline shows `quality:*` jobs and `run_training`.
- [ ] Manual Play on `run_training` succeeds, or commit message `[run train]` triggers it.
- [ ] On the runner host, `docker ps | grep train-` shows the detached container.
- [ ] `docker logs -f train-<project>-<branch>` shows training output.

Important: a successful CI job only means the container was dispatched. Training success must be verified through container logs or experiment tracking.

## 6. Cursor devcontainer

Install these Cursor / VS Code extensions:

- Remote - SSH
- Dev Containers

Workflow:

1. SSH into the GPU server from Cursor.
2. Open the project folder on the remote host.
3. Run **Dev Containers: Reopen in Container**.
4. Inside the container, run:

```bash
python -c "import torch; print(torch.cuda.is_available())"
ls /data
uv sync --dev
python train.py
```

- [ ] Container builds from the project `Dockerfile`.
- [ ] GPU is visible inside the container.
- [ ] `/data` is mounted.
- [ ] Python tools and project dependencies work.

## 7. GitLab CI layout note

The full pipeline lives under `.gitlab/ci/`:

- `.gitlab/ci/quality.yml`: parallel quality checks
- `.gitlab/ci/train.yml`: GPU training dispatch

The root `.gitlab-ci.yml` owns orchestration and includes the job files:

```yaml
default:
  interruptible: true

stages:
  - quality
  - deploy

include:
  - local: .gitlab/ci/quality.yml
  - local: .gitlab/ci/train.yml
```

GitLab requires a root CI entry file by default. Keep this include at the repository root unless you explicitly change the project setting **Settings → CI/CD → CI/CD configuration file**.

## 8. Common overrides

Set these in GitLab CI/CD variables when needed:

```bash
TRAIN_COMMAND="uv run python -m src.train"
BUILD_MLOPS_IMAGE="true"
MLOPS_DOCKER_IMAGE=""
DATA_MOUNT_SOURCE="/mnt/nfs_data"
DATA_MOUNT_TARGET="/data"
```

Store secrets such as `WANDB_API_KEY` and `MLFLOW_TRACKING_URI` in GitLab CI/CD variables only.
