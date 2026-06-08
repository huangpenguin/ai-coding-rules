# Customize Dockerfile

模板 Dockerfile 只提供通用 GPU 开发环境，不应该塞入某个项目的全部业务依赖。

常见修改：

## 1. 改 PyTorch / CUDA 版本

```dockerfile
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

旧项目（例如 BasicSR）如果遇到依赖不兼容，可以退回 CUDA 12.1 对应镜像。

## 2. 加系统依赖

```dockerfile
RUN apt-get update     && apt-get install -y --no-install-recommends libgl1     && rm -rf /var/lib/apt/lists/*
```

## 3. 项目依赖放哪里

优先放在项目自己的 `pyproject.toml` / `requirements.txt`。不要把所有实验依赖都写死进通用模板。

## 4. 训练命令放哪里

GitLab Runner 中通过变量覆盖：

```bash
TRAIN_COMMAND="python basicsr/train.py -opt options/train/xxx.yml"
```
