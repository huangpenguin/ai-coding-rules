# Devcontainer: never bind-mount entire $HOME

## Symptom

- After GPU server restart or reconnecting Dev Container, Cursor server fails to install or extensions hang.
- Errors around `.cursor-server`, `.cache`, `.gvfs`, or permission denied under `/home/vscode`.
- `.venv` corruption when combined with host home bind + `updateRemoteUserUID`.

## Root cause

`devcontainer.json` (or a local override) bind-mounts the **entire host `$HOME`** into the container, e.g. `source=${localEnv:HOME},target=/home/vscode`. That merges host IDE caches, GVFS, and dotfiles with the container user home. Cursor/VS Code Dev Containers expect an isolated container home for server binaries.

## Fix

Use **scoped mounts only**:

| Mount | Target | Purpose |
|-------|--------|---------|
| Project repo | `/workspace` | Code + project `.venv` |
| `DATA_MOUNT_SOURCE` | `/data` | Datasets |
| Named volume (optional) | e.g. `/home/vscode/.cache/uv` | Persist download cache only |

Set `remote.containers.copyGitConfig: false` if Cursor fails copying `.gitconfig` from an undefined host home path.

Remove any `source=${localEnv:HOME}` → `/home/vscode` or `/workspace` mount. Rebuild Container.

## Prevention

- Open the **git repo folder** in IDE, not `$HOME`.
- mlops-gpu template commits only `workspaceMount` + `DATA_MOUNT_SOURCE` → `/data`.
- For smoke tests, Option D mounts `${HOME}/.local/share/mlops-empty-data` → `/data` (a **subdirectory**, not full home).
