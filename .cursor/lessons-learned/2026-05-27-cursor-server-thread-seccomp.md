# Cursor server fails: uv_thread_create / getaddrinfo thread

- **Symptom**: Container builds and starts; Cursor server install fails with `curl: (6) getaddrinfo() thread failed to start` and Node `uv_thread_create` assertion in `/root/.cursor-server/.../node`.
- **Root cause**: Host Docker ≤ 20.10.7 seccomp blocks thread/syscall needs of Ubuntu 22.04 glibc + modern Node inside container.
- **Fix**: Add `"--security-opt", "seccomp=unconfined"` to devcontainer `runArgs`. Long-term: upgrade Docker to ≥ 20.10.18 (or current CE).
- **Prevention**: Document Docker version requirement in GPU server checklist; treat `gpg_agent_socket undefined` as non-fatal noise.
