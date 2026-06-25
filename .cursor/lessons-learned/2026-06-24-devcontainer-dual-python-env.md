# Devcontainer dual Python environment (conda vs uv .venv)

## Symptom

- Rebuild devcontainer后，agent 跑 `uv run` / smoke test 时重新下载巨大的 torch wheel。
- `uv pip install -r requirements.txt` 从 PyPI 装到 torch 2.12 等版本，V100 (`sm_70`) 上 `torch.cuda.is_available()` 为 false。
- `.venv` 因 workspace bind mount 损坏，agent 反复重建环境。
- devcontainer 指向 `/opt/conda/bin/python`，但工作流强制 `uv run` → 实际用 `.venv`，两套环境混淆。

## Root cause

GPU 基础镜像（`pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`）的 **conda torch** 与 **项目 `.venv`** 是两套环境。

inject `python-quality` + `mlops-gpu` 到旧项目（`requirements.txt` + `setup.py`，`pyproject.toml` 仅脚手架且 `dependencies = []`）后：

- `postCreateCommand` 只跑 `uv sync --dev` → 只有 ruff/pyright，**无运行时依赖**。
- GitLab `train.yml` 对旧项目跑 `uv pip install -r requirements.txt`，但 devcontainer 没有等价步骤 → **本地/CI 分裂**。
- `uv pip install -r requirements.txt` 未指定 cu124 index → resolver 可能从 PyPI 装到未验证的 torch build。

## Fix

1. 使用统一脚本 `scripts/uv-bootstrap.sh`（devcontainer `postCreateCommand` 与 GitLab GPU `before_script` 共用）。
2. 半迁移状态（空 `dependencies` + 有 `requirements.txt`）走 requirements 安装 + `--extra-index-url` cu124 + `uv pip install -e .`（若有 `setup.py`）。
3. `python.defaultInterpreterPath` 指向 `/workspace/.venv/bin/python`，与 `uv run` 一致。
4. 迁移完成后：把依赖写入 `pyproject.toml` + `uv.lock`（可参考 `pyproject-uv-pytorch.snippet.toml`），走 `uv sync --frozen --dev`。

## Prevention

- **镜像里有 torch ≠ 项目能直接跑**：工作流若统一 `uv run`，必须在 postCreate/CI bootstrap 项目 `.venv`。
- **半迁移最危险**：有 `pyproject.toml` 但 `dependencies = []`，`uv sync --dev` 看起来像「环境好了」，运行时依赖其实全缺。
- **GPU 项目 torch 必须 pin CUDA build**：`torch>=2.6.0,<2.7.0` 不够，legacy 安装需 cu124 index。
- **devcontainer 与 CI 必须 parity**：同一 `uv-bootstrap.sh`。
- **`.venv` 在 workspace bind mount 内**：每次 Rebuild 由 postCreate 重建；勿提交 `.venv`。

## Verify

```bash
# Rebuild devcontainer 后
uv run python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
# 期望: 2.6.x+cu124, True (有 GPU 时)
```
