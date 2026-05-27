# Devcontainer fails at container setup (bind mount)

- **Symptom**: Image builds, but `docker run` fails before Cursor server install; error: `bind source path does not exist: /mnt/nfs_data` (or similar missing host path).
- **Root cause**: Hardcoded bind source does not match host layout. This cluster uses autofs (`/etc/auto.nfs` → `/mnt/data`, `/mnt/home`), not `/mnt/nfs_data`. Autofs paths must be accessed before Docker bind mount.
- **Fix**: Mount `source=/mnt/data,target=/data`; set `initializeCommand` to `ls /mnt/data >/dev/null` to trigger autofs. Override via `.devcontainer/devcontainer.local.json` when offline or on other hosts.
- **Prevention**: Do not assume `/mnt/nfs_data`; detect autofs map or document host-specific mount in local override file.
