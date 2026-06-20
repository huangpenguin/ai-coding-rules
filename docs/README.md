# Documentation Index

Pack and operational docs live under **`templates/<pack>/managed/docs/`**. That is the canonical source: `init-ai add <pack> --apply` copies them into target projects.

This folder keeps only **template-repository** guides that are not injected.

## Packs (canonical paths in this repo)

| Pack | Doc |
|------|-----|
| core | [templates/core/managed/docs/packs/core.zh-CN.md](../templates/core/managed/docs/packs/core.zh-CN.md) |
| python-quality | [templates/python-quality/managed/docs/packs/python-quality.zh-CN.md](../templates/python-quality/managed/docs/packs/python-quality.zh-CN.md) |
| ci-quality | [templates/ci-quality/managed/docs/packs/ci-quality.zh-CN.md](../templates/ci-quality/managed/docs/packs/ci-quality.zh-CN.md) |
| mlops-gpu | [templates/mlops-gpu/managed/docs/packs/mlops-gpu.zh-CN.md](../templates/mlops-gpu/managed/docs/packs/mlops-gpu.zh-CN.md) |
| hf-space | [templates/hf-space/managed/docs/packs/hf-space.zh-CN.md](../templates/hf-space/managed/docs/packs/hf-space.zh-CN.md) |
| mlflow-experimental | [templates/mlflow-experimental/managed/docs/packs/mlflow-experimental.zh-CN.md](../templates/mlflow-experimental/managed/docs/packs/mlflow-experimental.zh-CN.md) |

## Docker / MLOps (mlops-gpu pack)

| Topic | Doc |
|-------|-----|
| Dev Container runbook | [templates/mlops-gpu/managed/.devcontainer/README.md](../templates/mlops-gpu/managed/.devcontainer/README.md) |
| Docker quickstart | [templates/mlops-gpu/managed/docs/docker/quickstart.zh-CN.md](../templates/mlops-gpu/managed/docs/docker/quickstart.zh-CN.md) |
| CUDA / driver matrix | [templates/mlops-gpu/managed/docs/docker/cuda-driver-matrix.zh-CN.md](../templates/mlops-gpu/managed/docs/docker/cuda-driver-matrix.zh-CN.md) |
| Customize Dockerfile | [templates/mlops-gpu/managed/docs/docker/customize-dockerfile.zh-CN.md](../templates/mlops-gpu/managed/docs/docker/customize-dockerfile.zh-CN.md) |

## Use cases (injected with mlops-gpu)

| Topic | Doc |
|-------|-----|
| Data mount env isolation | [templates/mlops-gpu/managed/docs/use-cases/data-mount-env-isolation.md](../templates/mlops-gpu/managed/docs/use-cases/data-mount-env-isolation.md) |
| GPU Runner workflow | [templates/mlops-gpu/managed/docs/use-cases/gpu-runner.zh-CN.md](../templates/mlops-gpu/managed/docs/use-cases/gpu-runner.zh-CN.md) |

## Template repository only (not injected)

- [BasicSR first-stage finetune](use-cases/basicsr-finetune.zh-CN.md)
