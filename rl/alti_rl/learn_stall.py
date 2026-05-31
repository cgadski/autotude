import argparse
from dataclasses import dataclass
from pathlib import Path

import torch
import torch.nn as nn
import vandc

from alti_rl.networks import Options, PlaneEncoder


@dataclass
class TrainConfig:
    data_path: str
    batch_size: int = 1024
    lr: float = 0.01
    epochs: int = 1


def info(data: dict[str, torch.Tensor]):
    mask_raw: torch.Tensor = data["mask"]  # (T,) bool
    stalled: torch.Tensor = data["stalled"].float()  # (T,) → 0.0 / 1.0

    T = mask_raw.shape[0]
    n_valid = int(mask_raw.sum().item())
    n_stalled = int(stalled[mask_raw].sum().item())
    stall_rate = n_stalled / n_valid if n_valid else 0.0
    print(f"Frames: {T} total, {n_valid} valid")
    print(f"Stalls: {n_stalled} / {n_valid} valid frames ({stall_rate:.1%})")
    print(f"Baseline (always not-stalled): {1 - stall_rate:.4f}")


def train(config: TrainConfig, data: dict[str, torch.Tensor]):
    opts = Options()

    encoder = PlaneEncoder(opts)
    head = nn.Linear(64, 1, dtype=torch.float32)
    optimizer = torch.optim.SGD(
        list(encoder.parameters()) + list(head.parameters()),
        lr=config.lr,
    )
    criterion = nn.BCEWithLogitsLoss()

    T = data["mask"].shape[0]
    batch_starts = range(0, T, config.batch_size)

    total_correct = 0
    total_valid = 0

    for start in vandc.progress(batch_starts):
        end = min(start + config.batch_size, T)

        mask, x = encoder(data["mask"][start:end], data["plane"][start:end])
        n = int(mask.sum().item())
        if n == 0:
            continue

        logits = head(x[mask]).squeeze(-1)
        stalled = data["stalled"][start:end][mask].float()
        loss = criterion(logits, stalled)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        with torch.no_grad():
            correct = int(((logits > 0).float() == stalled).sum().item())
        total_correct += correct
        total_valid += n

        vandc.log({"loss": loss.item(), "accuracy": correct / n})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data_path", type=str)
    args = parser.parse_args()
    config = TrainConfig(data_path=args.data_path)
    vandc.init(config)

    data = torch.load(config.data_path, weights_only=False)

    info(data)
    train(config, data)

    vandc.close()
