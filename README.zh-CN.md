# AI Coding Rules

**Language / 语言:** [English](README.md) | 简体中文

这是一个给 Python / AI 项目使用的工程化模板仓库。现在模板按 **pack** 拆分：默认 `init-ai` 只注入核心 Cursor / Claude 规则和项目记忆；Python 质量检查、GitHub/GitLab CI、Docker、GPU Runner 训练和未来的 MLOps 功能都需要显式启用。

## 快速开始

新机器上安装一次：

```bash
curl -fsSL https://raw.githubusercontent.com/huangpenguin/ai-coding-rules/main/install.sh | bash
source ~/.zshrc   # 或 source ~/.bashrc
```

在任意项目中使用：

```bash
cd your-project
init-ai
```

默认只应用 `core` pack：`.cursor/rules/`、`CLAUDE.md`、`.cursorrules`、`MEMORY.md` 和项目上下文目录。

## 可选 Pack

```bash
init-ai add python-quality       # Ruff、Pyright、pre-commit、.gitignore
init-ai add ci-quality           # GitHub/GitLab 质量 CI（自动带上 python-quality）
init-ai add mlops-gpu            # Docker、devcontainer、GPU Runner（自动带上 ci-quality）
init-ai add hf-space             # HF Space 部署：git archive 干净快照 + force push
init-ai profile research-gpu     # core + mlops-gpu（自动带上 python-quality 与 ci-quality）
```

Pack 依赖会自动展开：`ci-quality` → `python-quality`；`mlops-gpu` → `ci-quality` → `python-quality`。若目标项目没有 `pyproject.toml`，会先 `uv init` 脚手架再安装 dev 工具；已有的 `requirements.txt` / `setup.py` 不会被修改。

建议先预览：

```bash
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

## 常见场景

- **BasicSR 第一阶段微调 / legacy 研究仓库**：只运行 `init-ai`，先不要引入 Docker/CI。
- **现代 Python 项目**：先 `init-ai`，再 `init-ai add python-quality`。
- **需要 GitHub/GitLab 质量检查**：添加 `ci-quality`（会自动带上 python-quality 与 CI 所需的 dev 依赖）。
- **需要实验室 GPU 服务器训练**：添加 `mlops-gpu`，或直接使用 `profile research-gpu`。
- **Hugging Face Space 部署（本地可留大文件）**：添加 `hf-space`，用 `DEPLOY_EXCLUDE_PATHS` 剔除不上线的目录。

## Docker Executor GPU 快速落地

`mlops-gpu` 默认面向 GitLab self-hosted **Docker executor** GPU Runner。GitLab job 本身运行在 GPU 容器里，不再在 CI 脚本中嵌套执行 `docker build` / `docker run`。

默认 GPU 镜像：

```text
pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

这个镜像作为新仓库的基线 smoke 环境：PyTorch 2.6.x、CUDA 12.4、cuDNN 9，适合先验证 V100 / CUDA / torch 组合。因为该镜像不保证内置 `uv`，模板的 GitLab YAML 会在 job 内安装 `uv`，再根据 `pyproject.toml` / `uv.lock` / `requirements.txt` 同步项目依赖。

### 1. GPU 服务器端准备

在真正有 GPU 的服务器上确认：

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

安装并注册 GitLab Runner。先在 GitLab Web 创建 project runner，复制 `glrt-...` token，然后在 GPU 服务器上执行：

```bash
sudo gitlab-runner register \
  --url https://gitlab.com \
  --token glrt-xxxx \
  --executor docker \
  --docker-image pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
```

注册后(sudo权限)检查 `/etc/gitlab-runner/config.toml`，关键配置应类似：

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

- `gpus = "all"` 让 Docker executor 创建的 job 容器能看到 GPU。
- `shm_size` 给 PyTorch DataLoader 足够 shared memory。
- `/mnt/data:/data:ro` 是 GPU 服务器本机路径到容器内 `/data` 的只读挂载；没有统一数据盘时可先去掉该挂载。
- `concurrent = 1` 让单台 GPU 服务器一次只跑一个 GPU job，避免多人抢同一块卡。

### 2. GitLab Web 设置

进入项目：

```text
Settings → CI/CD → Runners → New project runner
```

推荐设置：

- tags: `linux,docker,gpu`，需要指定服务器时再加 `main_gpu` 或其他机器名。
- 关闭 `Run untagged jobs`，避免普通 CI 误跑到 GPU Runner。
- 只有需要限制 protected branch 时才开启 protected runner。
- CI/CD Variables 可按项目覆盖：
  - `MLOPS_GPU_IMAGE=pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel`
  - `DATA_DIR=/data`
  - `SMOKE_COMMAND=python train.py`
  - `TRAIN_COMMAND=python train.py`

### 3. 新仓库启用模板

```bash
cd your-project
init-ai add mlops-gpu --dry-run
init-ai add mlops-gpu --apply
```

推送后在 GitLab Pipeline 页面先手动运行：

```text
gpu_smoke
```

确认 GPU、torch、CUDA、依赖同步和最小训练入口正常后，再运行：

```text
run_training
```

### 4. GitHub Actions 边界

`ci-quality` 里的 GitHub Actions 默认继续使用 `ubuntu-latest` 做 Ruff / Pyright 等 CPU 质量检查，不默认接 GPU Runner。

如果未来确实要用 GitHub self-hosted GPU runner，应单独配置 GitHub Actions 的：

```yaml
runs-on: [self-hosted, linux, gpu]
```

不要把 GitHub self-hosted runner 与 GitLab Runner 的注册、tag 和 `config.toml` 混用。

## 文档入口

- [文档索引](docs/README.md) — 指向 `templates/` 下的 canonical pack 文档
- [BasicSR 第一阶段微调](docs/use-cases/basicsr-finetune.zh-CN.md) — 仅本模板仓库说明，不会 inject

## 仓库结构

本仓库是 **模板分发器**，不是普通应用项目。


| 路径                                                       | 作用                             |
| -------------------------------------------------------- | ------------------------------ |
| `inject-ai.sh`、`install.sh`                              | 安装与 inject 入口                  |
| `templates/<pack>/`                                      | **inject 唯一来源** — 改 pack 内容在这里 |
| `docs/`                                                  | 索引 + 仅留在本仓库的指南                 |
| `.cursorrules`、`CLAUDE.md`、`.cursor/`                    | 维护者在本仓库的 dogfooding            |
| `pyproject.toml`、`ruff.toml`、`.gitlab-ci.yml`、`.github/` | **本仓库自身 CI**，不会 inject         |


Docker、devcontainer、GPU 训练与 pack 文档应放在 `templates/mlops-gpu/`，不要放在仓库根目录。

## 维护本模板仓库

本仓库在 **GitHub** 与 **GitLab** 双端镜像。一次性配置 remotes：

```bash
git remote add origin git@github.com:huangpenguin/ai-coding-rules.git   # 若已有 origin 则跳过
git remote add gitlab git@gitlab.com:jil_atr/ai-coding-rules.git        # GitLab 当前 canonical 路径
git fetch --all
```

`main` 提交后推送到两边：

```bash
git push origin main && git push gitlab main
```

本维护者 checkout 上 `main` 默认跟踪 `gitlab/main`；`git fetch --all` 后可从任一侧 pull。