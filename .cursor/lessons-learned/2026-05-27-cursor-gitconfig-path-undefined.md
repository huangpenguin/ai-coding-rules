# Cursor server install fails reading .gitconfig

- **Symptom**: Container starts, then `Failed to read .gitconfig: path must be of type string. Received undefined` during Cursor server install.
- **Root cause**: Cursor Dev Containers extension bug: host home path resolution fails when copying `.gitconfig` (VS Code works; Cursor fork does not).
- **Fix**: Set `remote.containers.copyGitConfig: false` in devcontainer settings; pre-create `/home/vscode/.gitconfig` in image; bind-mount host `${localEnv:HOME}/.gitconfig` read-only; use explicit `workspaceMount` + `workspaceFolder: /workspace`.
- **Prevention**: Avoid `${localWorkspaceFolderBasename}` in `workspaceFolder` for dot-prefixed repos; keep container `.gitconfig` present before server install.
