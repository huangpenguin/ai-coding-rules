"""Resolve dataset paths from DATA_DIR and optional env overrides."""

from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def data_root() -> Path:
    """Container-local data root (bind-mounted from the Docker host)."""
    return Path(os.environ.get("DATA_DIR", "/data"))


def resolve_dataset_dir(
    *relative_parts: str,
    env_override: str | None = None,
    workspace_fallback: str | None = None,
) -> Path:
    """Return the first existing directory among known candidates.

    Resolution order:
    1. ``env_override`` environment variable (absolute path)
    2. ``DATA_DIR`` / relative_parts
    3. ``datasets/<workspace_fallback>`` under the project root (legacy copy/symlink)
    """
    if env_override:
        if override := os.environ.get(env_override):
            return Path(override)

    rel = Path(*relative_parts)
    candidates: list[Path] = [data_root() / rel]
    if workspace_fallback:
        candidates.append(ROOT / "datasets" / workspace_fallback)

    for path in candidates:
        if path.is_dir():
            return path

    return candidates[0]
