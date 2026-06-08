# GPU Runner Workflow

GitLab 网页负责派发 job，真正执行发生在带 `gpu-server` tag 的 self-hosted Runner 上。

要求：

- Runner 注册到项目或 group
- tag 与 `.gitlab/ci/train.yml` 一致：`gpu-server`
- executor 使用 `shell`，不是 `docker`
- 宿主机有 Docker 和 NVIDIA Container Toolkit

触发方式：

- GitLab Pipeline 页面手动 Play `run_training`
- commit message 含 `[run train]`

CI job 成功只表示训练容器已启动。训练结果请看：

```bash
docker ps | grep train-
docker logs -f <container-name>
```
