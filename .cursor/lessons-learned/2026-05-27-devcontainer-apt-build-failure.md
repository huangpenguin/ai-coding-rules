# Devcontainer build fails on apt-get update

- **Symptom**: `docker buildx build` / devcontainer image build exits 100; log shows `E: Problem executing scripts APT::Update::Post-Invoke` from `/etc/apt/apt.conf.d/docker-clean`.
- **Root cause**: `pytorch/pytorch` base image ships a `docker-clean` apt hook that fails during `apt-get update` in BuildKit/buildx layers.
- **Fix**: In `Dockerfile`, remove the hook before apt: `rm -f /etc/apt/apt.conf.d/docker-clean`, then run `apt-get update && apt-get install ... && apt-get clean && rm -rf /var/lib/apt/lists/*`.
- **Prevention**: For devcontainer templates on PyTorch/CUDA bases, always strip `docker-clean` before first `apt-get`; create `vscode` user + `updateRemoteUserUID: true` to avoid bind-mount permission conflicts.
