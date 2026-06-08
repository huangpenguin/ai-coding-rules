# CUDA / Driver 关系

目标宿主环境：Ubuntu 24.04 + NVIDIA `570-server` 或更高。

关键规则：**宿主机 driver 必须支持容器内 CUDA runtime**。driver 新可以跑旧 CUDA 容器；容器 CUDA 写得越高，对最低 driver 要求越高。

建议：

| 用途 | 推荐 |
|------|------|
| 通用模板默认 | PyTorch CUDA 12.4 |
| 新项目尝鲜 | CUDA 12.6 |
| BasicSR / 旧项目 | CUDA 12.1 或 12.4 |
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
