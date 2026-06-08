# Docker Daemon Permission

- **Symptom**: `nvidia-smi` works and Docker CLI is installed, but `docker run --gpus all ...` fails with `permission denied while trying to connect to the Docker daemon socket`.
- **Root cause**: The current user is not in the `docker` group and cannot access `/var/run/docker.sock`.
- **Fix**: Add the user to the `docker` group or run Docker through an approved privileged path, then start a new login session.
- **Prevention**: Before GPU Docker tests, check `id`, `groups`, `ls -l /var/run/docker.sock`, and `docker info`.
