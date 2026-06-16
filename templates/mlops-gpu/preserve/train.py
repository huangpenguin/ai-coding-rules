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


def torch_runtime(torch_module: ModuleType) -> tuple[str, str | None, int | None]:
    torch_any: Any = cast(Any, torch_module)
    version = str(torch_any.__version__)
    cuda_value = torch_any.version.cuda
    cuda_version = str(cuda_value) if cuda_value is not None else None
    cudnn: Any = torch_any.backends.cudnn
    cudnn_version = cudnn.version()
    return version, cuda_version, int(cudnn_version) if cudnn_version is not None else None


def cuda_status(torch_module: ModuleType) -> tuple[bool, str | None, tuple[int, int] | None]:
    cuda: Any = cast(Any, torch_module).cuda
    is_available = bool(cuda.is_available())
    device_name = str(cuda.get_device_name(0)) if is_available else None
    device_capability: tuple[int, int] | None = None
    if is_available:
        raw_capability = cuda.get_device_capability(0)
        device_capability = (int(raw_capability[0]), int(raw_capability[1]))
    return is_available, device_name, device_capability


def describe_mount(path: Path) -> str:
    if path.exists():
        return f"available at {path}"
    return f"not found at {path}"


def main() -> None:
    torch_module = load_torch()
    torch_version, cuda_version, cudnn_version = torch_runtime(torch_module)
    cuda_available, device_name, device_capability = cuda_status(torch_module)
    data_dir = Path(os.environ.get("DATA_DIR", "/data"))

    print("=== AI MLOps GPU smoke test ===", flush=True)
    print(f"Torch version: {torch_version}", flush=True)
    print(f"Torch CUDA build: {cuda_version}", flush=True)
    print(f"cuDNN version: {cudnn_version}", flush=True)
    print(f"CUDA available: {cuda_available}", flush=True)
    if device_name is not None:
        print(f"GPU device: {device_name}", flush=True)
    if device_capability is not None:
        print(f"GPU capability: sm_{device_capability[0]}{device_capability[1]}", flush=True)
    print(f"Data mount: {describe_mount(data_dir)}", flush=True)

    for epoch in range(1, 6):
        loss = 0.5 / epoch
        print(f"Epoch [{epoch}/5] - smoke training step, loss={loss:.4f}", flush=True)
        time.sleep(3)

    print("Smoke test finished.", flush=True)


if __name__ == "__main__":
    main()
