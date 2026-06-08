from __future__ import annotations

import importlib
import os
import time
from pathlib import Path
from types import ModuleType
from typing import Any, cast


def load_torch() -> ModuleType:
    try:
        return importlib.import_module("torch")
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "PyTorch is not installed in this environment. "
            "Run this smoke test inside the provided Docker image or install torch in the project environment."
        ) from exc


def cuda_status(torch_module: ModuleType) -> tuple[bool, str | None]:
    cuda: Any = cast(Any, torch_module).cuda
    is_available = bool(cuda.is_available())
    device_name = str(cuda.get_device_name(0)) if is_available else None
    return is_available, device_name


def describe_mount(path: Path) -> str:
    if path.exists():
        return f"available at {path}"
    return f"not found at {path}"


def main() -> None:
    torch_module = load_torch()
    cuda_available, device_name = cuda_status(torch_module)
    data_dir = Path(os.environ.get("DATA_DIR", "/data"))

    print("=== AI MLOps GPU smoke test ===", flush=True)
    print(f"CUDA available: {cuda_available}", flush=True)
    if device_name is not None:
        print(f"GPU device: {device_name}", flush=True)
    print(f"Data mount: {describe_mount(data_dir)}", flush=True)

    for epoch in range(1, 6):
        loss = 0.5 / epoch
        print(f"Epoch [{epoch}/5] - smoke training step, loss={loss:.4f}", flush=True)
        time.sleep(3)

    print("Smoke test finished.", flush=True)


if __name__ == "__main__":
    main()
