# GPU Runner Workflow

GitLab 网页负责派发 job，真正执行发生在带 `gpu-server` tag 的 self-hosted Runner 上。

要求：

- Runner 注册到项目或 group
- tag 与 `.gitlab/ci/train.yml` 一致：`gpu-server`
- executor 使用 `shell`，不是 `docker`
- 宿主机有 Docker 和 NVIDIA Container Toolkit
- 如果训练需要数据集，GPU 宿主机上要能访问对应目录，例如 `/mnt/data` 或 `/mnt/nfs_data`

触发方式：

- GitLab Pipeline 页面手动 Play `run_training`
- commit message 含 `[run train]`

CI job 成功只表示训练容器已启动。训练结果请看：

```bash
docker ps | grep train-
docker logs -f <container-name>
```

## 配置数据挂载

模板默认：

```yaml
DATA_MOUNT_SOURCE: ""
DATA_MOUNT_TARGET: "/data"
```

`DATA_MOUNT_SOURCE` 为空时，CI 会跳过数据盘挂载，训练容器仍会启动。这样模板可以在没有 NFS 的机器上先做 smoke test。

真实训练时，在 GitLab 项目的 **Settings → CI/CD → Variables** 中设置：

```text
DATA_MOUNT_SOURCE=/path/on/gpu-host
```

这里的路径是 **GPU Runner 所在宿主机** 上的路径，也就是执行 `docker run` 的那台机器能看到的路径。

常见例子：

- autofs：`DATA_MOUNT_SOURCE=/mnt/data`
- 手动 NFS 挂载：`DATA_MOUNT_SOURCE=/mnt/nfs_data`
- 本机数据盘：`DATA_MOUNT_SOURCE=/data/datasets`

不要把 NFS 服务器 export 字符串写进去，例如 `192.168.3.14:/mnt/storage/data`。Docker bind mount 的左侧必须是宿主机本地路径。
