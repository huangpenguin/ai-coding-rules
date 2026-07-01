#!/usr/bin/env python3
"""Plan persistent CI training output paths on self-hosted GPU runners.

Selects a writable root (NFS /home, /cache, or repo-local fallback), creates
pipeline-scoped experiment and TensorBoard directories, and optionally emits
shell exports for GitLab CI before_script.

Local development does not need this script: train.py defaults to ./experiments.
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from pathlib import Path

MARKER_EXPERIMENTS = ".ci_experiments_root"
MARKER_TB_LOGGER = ".ci_tb_logger_root"
MARKER_HOST_HINT = ".ci_storage_host_hint"


@dataclass(frozen=True)
class StorageLayout:
    storage_root: Path
    pipeline_id: str
    experiments_root: Path
    tb_logger_root: Path
    latest_link: Path
    host_hint: str


def resolve_storage_user() -> str:
    for key in ("MLOPS_STORAGE_USER", "CST_STORAGE_USER", "GITLAB_USER_LOGIN", "USER"):
        value = os.environ.get(key, "").strip()
        if value:
            return value
    return "mlops"


def resolve_pipeline_id() -> str:
    return os.environ.get("CI_PIPELINE_ID", "local").strip() or "local"


def repo_root() -> Path:
    return Path(os.environ.get("CI_PROJECT_DIR", Path.cwd())).resolve()


def candidate_roots(user: str, repo: Path) -> list[Path]:
    return [
        Path(f"/home/{user}/mlops_storage"),
        Path(f"/mnt/home/{user}/mlops_storage"),
        Path(f"/cache/{user}/mlops_storage"),
        repo / ".ci_storage" / user / "mlops_storage",
    ]


def pick_writable_root(candidates: list[Path]) -> tuple[Path, list[str]]:
    notes: list[str] = []
    for candidate in candidates:
        try:
            candidate.mkdir(parents=True, exist_ok=True)
            probe = candidate / ".write_probe"
            probe.write_text("ok", encoding="utf-8")
            probe.unlink(missing_ok=True)
            notes.append(f"selected storage root: {candidate}")
            return candidate, notes
        except OSError as exc:
            notes.append(f"skip {candidate}: {exc}")
    raise RuntimeError(
        "No writable CI storage root found. Mount NFS at /home or /mnt/home on the runner, "
        "or ensure the repo workspace is writable for .ci_storage/ fallback."
    )


def build_layout() -> StorageLayout:
    user = resolve_storage_user()
    pipeline_id = resolve_pipeline_id()
    repo = repo_root()
    storage_root, notes = pick_writable_root(candidate_roots(user, repo))

    outputs_root = storage_root / "ci_outputs" / pipeline_id
    experiments_root = outputs_root / "experiments"
    tb_logger_root = outputs_root / "tb_logger"
    experiments_root.mkdir(parents=True, exist_ok=True)
    tb_logger_root.mkdir(parents=True, exist_ok=True)

    latest_link = storage_root / "ci_outputs" / "latest"
    host_hint = f"SSH hint: outputs under {outputs_root} (latest symlink: {latest_link} when enabled)"
    for line in notes:
        print(line, file=sys.stderr)

    return StorageLayout(
        storage_root=storage_root,
        pipeline_id=pipeline_id,
        experiments_root=experiments_root,
        tb_logger_root=tb_logger_root,
        latest_link=latest_link,
        host_hint=host_hint,
    )


def write_markers(layout: StorageLayout, repo: Path) -> None:
    (repo / MARKER_EXPERIMENTS).write_text(f"{layout.experiments_root}\n", encoding="utf-8")
    (repo / MARKER_TB_LOGGER).write_text(f"{layout.tb_logger_root}\n", encoding="utf-8")
    (repo / MARKER_HOST_HINT).write_text(f"{layout.host_hint}\n", encoding="utf-8")


def update_latest_symlink(layout: StorageLayout) -> None:
    latest_parent = layout.latest_link.parent
    latest_parent.mkdir(parents=True, exist_ok=True)
    pipeline_dir = latest_parent / layout.pipeline_id
    if layout.latest_link.is_symlink() or layout.latest_link.exists():
        layout.latest_link.unlink()
    layout.latest_link.symlink_to(pipeline_dir, target_is_directory=True)


def emit_shell_exports(layout: StorageLayout) -> None:
    dataset_dir = os.environ.get("DATA_DIR", "/data")
    exports = {
        "TRAIN_EXPERIMENTS_ROOT": layout.experiments_root,
        "TRAIN_TB_LOGGER_ROOT": layout.tb_logger_root,
        "TRAIN_DATASET_DIR": dataset_dir,
        "MLOPS_CI_OUTPUTS_ROOT": layout.experiments_root.parent,
    }
    for key, value in exports.items():
        print(f'export {key}="{value}"')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare", help="Create CI output directories")
    prepare.add_argument(
        "--write-markers",
        action="store_true",
        help="Write marker files into the CI workspace for after_script / artifacts",
    )
    prepare.add_argument(
        "--latest-symlink",
        action="store_true",
        help="Update ci_outputs/latest -> current pipeline directory",
    )
    prepare.add_argument(
        "--emit-shell",
        action="store_true",
        help="Print export statements for eval in bash",
    )
    return parser.parse_args()


def cmd_prepare(args: argparse.Namespace) -> int:
    layout = build_layout()
    repo = repo_root()

    print(f"pipeline_id={layout.pipeline_id}")
    print(f"experiments_root={layout.experiments_root}")
    print(f"tb_logger_root={layout.tb_logger_root}")
    print(layout.host_hint)

    if args.write_markers:
        write_markers(layout, repo)
    if args.latest_symlink:
        update_latest_symlink(layout)
    if args.emit_shell:
        emit_shell_exports(layout)
    return 0


def main() -> int:
    args = parse_args()
    if args.command == "prepare":
        return cmd_prepare(args)
    raise AssertionError(f"Unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
