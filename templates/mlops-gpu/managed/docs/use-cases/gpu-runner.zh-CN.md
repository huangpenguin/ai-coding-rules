# GPU Runner Workflow

GitLab 网页负责派发 job，真正执行发生在带 `linux,docker,gpu` tag 的 self-hosted GPU Docker executor Runner 上。Runner 会直接拉起 GPU job 容器，CI 脚本在这个容器内运行。

要求：

- Runner 注册到项目或 group
- tag 与 `.gitlab/ci/train.yml` 一致：`linux`, `docker`, `gpu`
- executor 使用 `docker`
- GPU 宿主机已安装 NVIDIA driver、Docker 和 NVIDIA Container Toolkit
- GitLab Runner 的 `config.toml` 中设置 `[runners.docker] gpus = "all"`
- 如果训练需要数据集，GPU 宿主机上要能访问对应目录，例如 `/mnt/data` 或 `/mnt/nfs_data`，并通过 runner volumes 挂载到 `/data`

## 服务器端注册

先在 GitLab Web 创建 project runner，复制 `glrt-...` token，再在 GPU 服务器执行：

```bash
sudo gitlab-runner register \
  --url https://gitlab.com \
  --token glrt-xxxx \
  --executor docker \
  --docker-image pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

注册后检查 `/etc/gitlab-runner/config.toml`：

```toml
concurrent = 1

[[runners]]
  executor = "docker"
  [runners.docker]
    image = "pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel"
    gpus = "all"
    shm_size = 17179869184
    volumes = ["/cache", "/mnt/data:/data:ro"]
```

说明：

- `concurrent = 1` 控制单台 GPU 服务器一次只跑一个 GPU job。
- `gpus = "all"` 是 Docker executor GPU 透传的关键。
- `shm_size` 避免 PyTorch DataLoader shared memory 不足。
- `/mnt/data:/data:ro` 是 GPU 服务器本机路径；如果没有统一数据盘，可先移除该 volume。

## GitLab Web 设置

在项目页面进入：

```text
Settings → CI/CD → Runners → New project runner
```

推荐设置：

- tags: `linux,docker,gpu`
- 如需固定某台服务器，再额外加 `main_gpu` 或其他机器名
- 关闭 `Run untagged jobs`
- 只有需要限制 protected branch 时才开启 protected runner
- CI/CD Variables 可覆盖 `MLOPS_GPU_IMAGE`、`DATA_DIR`、`SMOKE_COMMAND`、`TRAIN_COMMAND`

触发方式：

- GitLab Pipeline 页面先手动 Play `gpu_smoke`
- `gpu_smoke` 通过后，再手动 Play `run_training`
- commit message 含 `[run train]`

`gpu_smoke` 用于快速验证一个仓库是否具备最小 DL GPU job 环境：

```text
GitLab Runner docker executor
→ pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel job container
→ bash scripts/uv-bootstrap.sh
→ run ${SMOKE_COMMAND}
```

新仓库即使没有 `pyproject.toml`、`uv.lock` 或 `requirements.txt`，也可以先使用默认 PyTorch/CUDA 镜像 + 模板 `train.py` 完成 smoke test。后续需要加包时，应提交依赖文件，或切换为已经构建并推送到 registry 的项目镜像；不要安装到 GPU Runner 宿主机。

`run_training` 会以前台 GitLab job 形式运行训练命令；CI 日志就是训练日志，job 状态就是训练状态。

## 默认镜像与 uv

默认：

```yaml
MLOPS_GPU_IMAGE: "pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel"
```

该镜像不保证内置 `uv`，模板会在 job 内安装 `uv` 并执行 `scripts/uv-bootstrap.sh`：

1. `pyproject.toml` + `uv.lock`：`uv sync --frozen --dev`
2. 半迁移（空 `dependencies` + `requirements.txt`）：requirements + cu124 index + dev 工具
3. 只有 `requirements.txt`：`uv venv` + requirements（含 torch 时 cu124 index）+ 可选 editable install
4. 只有 `pyproject.toml`：`uv sync --dev`
5. 没有环境文件：直接使用基础 PyTorch 镜像

## 配置数据挂载

Docker executor 的数据挂载由 Runner 服务器上的 `config.toml` 控制，不由 `.gitlab-ci.yml` 动态设置。

模板默认在 job 内使用：

```yaml
DATA_DIR: "/data"
```

如果训练需要数据集，应在 GPU Runner 宿主机上配置：

```toml
volumes = ["/cache", "/mnt/data:/data:ro"]
```

这里的 `/mnt/data` 是 **GPU Runner 所在宿主机** 上的路径，也就是 Docker daemon 能看到的本地路径。

常见例子：

- autofs：`/mnt/data:/data:ro`
- 手动 NFS 挂载：`/mnt/nfs_data:/data:ro`
- 本机数据盘：`/data/datasets:/data:ro`

不要把 NFS 服务器 export 字符串写进去，例如 `192.168.3.14:/mnt/storage/data`。Docker bind mount 的左侧必须是宿主机本地路径。
