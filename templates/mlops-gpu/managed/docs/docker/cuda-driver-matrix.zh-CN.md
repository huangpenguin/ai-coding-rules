# CUDA / Driver 关系

目标宿主环境：Ubuntu 24.04 + NVIDIA `570-server` 或更高。

关键规则：**宿主机 driver 必须支持容器内 CUDA runtime**。driver 新可以跑旧 CUDA 容器；容器 CUDA 写得越高，对最低 driver 要求越高。

## 模板默认验证组合

| 层 | 默认 |
|----|------|
| 镜像基底 | `pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel` |
| `nvcc` | CUDA 12.4 |
| PyTorch | `torch 2.6.x + cu124` |
| cuDNN | 9.x |
| 已验证 GPU | NVIDIA V100, `sm_70`, 32GB |

这是当前模板的保守默认。V100 是 Volta 架构，`sm_70` 需要 wheel / 容器运行时保留对应架构支持。不要让项目依赖把容器内 torch 升到一个未验证的大版本。

建议：

| 用途 | 推荐 |
|------|------|
| 通用模板默认 | PyTorch CUDA 12.4 |
| V100 / BasicSR / 旧项目 | PyTorch 2.6.x + CUDA 12.4 |
| 新项目尝鲜 | 先单独验证 CUDA 12.6 |
| 最新 CUDA 特性 | 再考虑 CUDA 12.8 |

当前模板默认：

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

宿主机验证：

```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## Python 依赖约束

如果目标项目的 `requirements.txt` / `pyproject.toml` 声明了 `torch`，不要写过宽的下限，例如：

```text
torch>=1.7
```

`uv pip install` 或 resolver 可能会选择最新 torch，导致 `.venv` 中的 torch 与 Docker 模板验证组合不一致。对于当前模板，建议：

```text
torch>=2.6.0,<2.7.0
```

如果还需要 `torchvision`、`torchaudio` 等包，也应跟随同一个 torch minor 系列约束。更新 torch / CUDA 组合时，先用 `uv run python train.py` 查看实际 `Torch version`、`Torch CUDA build`、`cuDNN version` 和 `GPU capability`，确认没有被项目依赖意外升级。
