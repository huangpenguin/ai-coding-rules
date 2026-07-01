from __future__ import annotations

import importlib
import json
import os
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from types import ModuleType
from typing import Any, cast


@dataclass(frozen=True)
class TrainPaths:
    experiments_root: Path
    tb_logger_root: Path
    dataset_dir: Path


def load_torch() -> ModuleType:
    try:
        return importlib.import_module("torch")
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "PyTorch is not installed in this environment. Run inside the GPU container after scripts/uv-bootstrap.sh."
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


def resolve_paths() -> TrainPaths:
    experiments_root = Path(os.environ.get("TRAIN_EXPERIMENTS_ROOT", "experiments")).expanduser()
    tb_logger_root = Path(os.environ.get("TRAIN_TB_LOGGER_ROOT", "tb_logger")).expanduser()
    dataset_dir = Path(os.environ.get("TRAIN_DATASET_DIR", os.environ.get("DATA_DIR", "/data")))
    return TrainPaths(
        experiments_root=experiments_root,
        tb_logger_root=tb_logger_root,
        dataset_dir=dataset_dir,
    )


def run_training_loop(
    torch_module: ModuleType,
    paths: TrainPaths,
    *,
    epochs: int = 5,
    sleep_seconds: float = 1.0,
) -> dict[str, Any]:
    torch_any: Any = cast(Any, torch_module)
    device = torch_any.device("cuda" if torch_any.cuda.is_available() else "cpu")

    run_name = os.environ.get("TRAIN_RUN_NAME", "smoke_linear")
    run_dir = paths.experiments_root / run_name
    checkpoints_dir = run_dir / "checkpoints"
    logs_dir = run_dir / "logs"
    checkpoints_dir.mkdir(parents=True, exist_ok=True)
    logs_dir.mkdir(parents=True, exist_ok=True)
    paths.tb_logger_root.mkdir(parents=True, exist_ok=True)

    model = torch_any.nn.Linear(32, 16, device=device)
    optimizer = torch_any.optim.SGD(model.parameters(), lr=0.01)
    loss_fn = torch_any.nn.MSELoss()

    metrics: list[dict[str, float | int]] = []
    start = time.time()

    for epoch in range(1, epochs + 1):
        inputs = torch_any.randn(64, 32, device=device)
        targets = torch_any.randn(64, 16, device=device)
        optimizer.zero_grad(set_to_none=True)
        loss_tensor = loss_fn(model(inputs), targets)
        loss_value = float(loss_tensor.item())
        loss_tensor.backward()
        optimizer.step()

        step: dict[str, float | int] = {"epoch": epoch, "loss": loss_value}
        metrics.append(step)
        print(
            f"Epoch [{epoch}/{epochs}] device={device} loss={loss_value:.4f}",
            flush=True,
        )
        time.sleep(sleep_seconds)

    checkpoint_path = checkpoints_dir / "latest.pt"
    torch_any.save(
        {
            "epoch": epochs,
            "model_state_dict": model.state_dict(),
            "optimizer_state_dict": optimizer.state_dict(),
            "metrics": metrics,
        },
        checkpoint_path,
    )

    summary: dict[str, Any] = {
        "run_name": run_name,
        "device": str(device),
        "epochs": epochs,
        "final_loss": metrics[-1]["loss"] if metrics else None,
        "checkpoint": str(checkpoint_path),
        "experiments_root": str(paths.experiments_root),
        "tb_logger_root": str(paths.tb_logger_root),
        "dataset_dir": str(paths.dataset_dir),
        "elapsed_seconds": round(time.time() - start, 2),
        "metrics": metrics,
    }
    summary_path = logs_dir / "train_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Wrote checkpoint: {checkpoint_path}", flush=True)
    print(f"Wrote summary: {summary_path}", flush=True)
    return summary


def main() -> None:
    torch_module = load_torch()
    paths = resolve_paths()
    torch_version, cuda_version, cudnn_version = torch_runtime(torch_module)
    cuda_available, device_name, device_capability = cuda_status(torch_module)

    print("=== MLOps GPU training smoke ===", flush=True)
    print(f"Torch version: {torch_version}", flush=True)
    print(f"Torch CUDA build: {cuda_version}", flush=True)
    print(f"cuDNN version: {cudnn_version}", flush=True)
    print(f"CUDA available: {cuda_available}", flush=True)
    if device_name is not None:
        print(f"GPU device: {device_name}", flush=True)
    if device_capability is not None:
        print(f"GPU capability: sm_{device_capability[0]}{device_capability[1]}", flush=True)
    print(f"Data mount: {describe_mount(paths.dataset_dir)}", flush=True)
    print(f"Experiments root: {paths.experiments_root}", flush=True)
    print(f"TensorBoard root: {paths.tb_logger_root}", flush=True)

    if not cuda_available:
        raise RuntimeError("CUDA is required for this training smoke job")

    summary = run_training_loop(torch_module, paths)
    print(json.dumps({"paths": asdict(paths), "summary": summary}, indent=2), flush=True)
    print("Training smoke finished.", flush=True)


if __name__ == "__main__":
    main()
