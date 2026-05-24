# MLOps 验收 Checklist

在目标项目执行 `init-ai` 后，或更新本模板仓库后，按此清单逐项验收。

## 1. 模板注入

- [ ] 在测试项目中运行 `init-ai`（或先 `init-ai --update --dry-run`，再 `--apply`）。
- [ ] 确认以下文件存在：
  - `.gitlab-ci.yml`
  - `.gitlab/ci/quality.yml`
  - `.gitlab/ci/train.yml`
  - `Dockerfile`
  - `.devcontainer/devcontainer.json`
  - `train.py`
- [ ] 更新模式下，目标项目已有的 `train.py` 不会被覆盖。

## 2. 本地质量检查

```bash
uv run ruff check .
uv run ruff format --check .
uv run pyright
```

- [ ] 模板仓库或注入后的项目检查全部通过。

## 3. GPU 服务器前置条件

在每台 GPU 服务器上执行：

```bash
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
groups
ls /mnt/nfs_data
```

- [ ] NVIDIA Container Toolkit 正常。
- [ ] Runner 用户能执行 Docker。
- [ ] 数据挂载目录存在；若不存在，先改 `.devcontainer/devcontainer.json` 和 GitLab CI 变量。

如果还没有 `/mnt/nfs_data`：

```bash
sudo mkdir -p /mnt/nfs_data
sudo chown "$USER":"$USER" /mnt/nfs_data
```

## 4. Docker 冒烟测试

```bash
docker build -t mlops-test .
docker run --rm --gpus all --shm-size 16g \
  -v "$(pwd):/workspace" \
  -v /mnt/nfs_data:/data \
  mlops-test bash -lc "python train.py"
```

- [ ] 容器能正常启动。
- [ ] 有 GPU 时输出 `CUDA available: True`。
- [ ] 会打印 `/data` 挂载状态。
- [ ] smoke training 循环能跑完。

## 5. GitLab Runner 训练调度

注册带 `gpu-server` 标签的 self-hosted shell executor Runner，然后 push 到 GitLab。

- [ ] Pipeline 中出现 `quality:*` job 和 `run_training`。
- [ ] 手动点击 `run_training` 的 Play 能成功，或 commit message 含 `[run train]` 能自动触发。
- [ ] 在 Runner 主机上，`docker ps | grep train-` 能看到后台容器。
- [ ] `docker logs -f train-<project>-<branch>` 能看到训练日志。

注意：CI job 成功只代表容器已派发，不代表训练成功。训练结果要看容器日志或实验追踪系统。

## 6. Cursor devcontainer

需要安装以下 Cursor / VS Code 扩展：

- Remote - SSH
- Dev Containers

推荐流程：

1. 在 Cursor 里通过 SSH 连接 GPU 服务器。
2. 打开服务器上的项目目录。
3. 执行 **Dev Containers: Reopen in Container**。
4. 进入容器后运行：

```bash
python -c "import torch; print(torch.cuda.is_available())"
ls /data
uv sync --dev
python train.py
```

- [ ] 容器能基于项目 `Dockerfile` 构建。
- [ ] 容器内能看到 GPU。
- [ ] `/data` 已挂载。
- [ ] Python 工具和项目依赖可用。

## 7. GitLab CI 目录说明

完整 pipeline 放在 `.gitlab/ci/` 下：

- `.gitlab/ci/quality.yml`：并行质量检查
- `.gitlab/ci/train.yml`：GPU 训练调度

根目录 `.gitlab-ci.yml` 负责编排，并 include 具体 job 文件：

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

GitLab 默认只认仓库根目录的 CI 入口文件，所以根目录仍需保留这个 include。只有在你明确修改项目设置 **Settings → CI/CD → CI/CD configuration file** 时，才可以完全去掉根目录文件。

## 8. 常用变量覆盖

可在 GitLab CI/CD Variables 中设置：

```bash
TRAIN_COMMAND="uv run python -m src.train"
BUILD_MLOPS_IMAGE="true"
MLOPS_DOCKER_IMAGE=""
DATA_MOUNT_SOURCE="/mnt/nfs_data"
DATA_MOUNT_TARGET="/data"
```

`WANDB_API_KEY`、`MLFLOW_TRACKING_URI` 等密钥只放在 GitLab CI/CD Variables 中，不要写进仓库。
