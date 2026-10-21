import argparse

import os

import torch
import torch.nn as nn
import vandc
from loguru import logger

from alti_rl.data import encode_plane_state
from alti_rl.networks import NavNet, Options


def prepare(data: dict[str, torch.Tensor], opts: Options) -> dict[str, torch.Tensor]:
    mask, plane_state = encode_plane_state(**data)
    pos = torch.stack([data["x"], data["y"]], 1).float()

    controls = data["controls"].long() & 0x7F
    act = controls[1:]
    damage = data["damage"][1:]

    ok = mask[:-1] & (act < 3) & (damage | mask[1:])
    frames = torch.where(ok)[0]  # frames to use for TD learning

    logger.info(
        f"{len(frames)} transitions of {len(mask)} steps, "
        f"crash rate {damage[frames].float().mean():.4f}"
    )

    return {
        "pos": pos,
        "plane_state": plane_state,
        "frames": frames,
        "act_index": act[frames],
        "crash": damage[frames],
        "extent": pos[mask].max(dim=0).values,
    }


def td_target(
    model: NavNet,
    opts: Options,
    pos: torch.Tensor,
    plane_state: torch.Tensor,
    frames: torch.Tensor,
    crash: torch.Tensor,
) -> torch.Tensor:
    """
    TD target for transitions starting at `frames` (indices into pos/plane_state).
    Computed with the current model under no_grad, so we don't differentiate through it.
    """
    with torch.no_grad():
        q_next = (
            torch.sigmoid(model(pos[frames + 1], plane_state[frames + 1]))
            .max(dim=1)
            .values
        )
    return torch.where(
        crash, torch.zeros_like(q_next), (1 - opts.gamma) + opts.gamma * q_next
    )


def run(
    opts: Options,
    pos: torch.Tensor,
    plane_state: torch.Tensor,
    frames: torch.Tensor,
    act_index: torch.Tensor,
    crash: torch.Tensor,
    extent: torch.Tensor,
) -> float:
    torch.manual_seed(opts.seed)
    model = NavNet(opts)
    model.set_extent(extent)

    optimizer = opts.optimizer(model.parameters())
    mse = nn.MSELoss()

    N = len(frames)  # number of transitions
    steps_per_epoch = (N + opts.batch_size - 1) // opts.batch_size
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=opts.epochs * steps_per_epoch, eta_min=opts.lr_min
    )

    vandc.init(opts)
    logger.info("Training...")

    for _ in range(opts.epochs):
        perm = torch.randperm(N)
        for i in vandc.progress(range(0, N, opts.batch_size)):
            batch = perm[i : i + opts.batch_size]  # indices into transitions
            batch_frames = frames[batch]
            y = td_target(model, opts, pos, plane_state, batch_frames, crash[batch])
            q = torch.sigmoid(model(pos[batch_frames], plane_state[batch_frames]))[
                torch.arange(len(batch)), act_index[batch]
            ]
            loss = mse(q, y)
            loss.backward()
            optimizer.step()
            optimizer.zero_grad()
            scheduler.step()
            vandc.log({"loss": loss})

    path = f"./models/{vandc.run_name()}.pt"
    logger.info(f"Saving model to {path}")
    os.makedirs("./models", exist_ok=True)
    torch.save(model.state_dict(), path)

    vandc.close()

    sample = torch.randperm(N)[: N // 10]
    sample_frames = frames[sample]
    with torch.no_grad():
        y = td_target(model, opts, pos, plane_state, sample_frames, crash[sample])
        q = torch.sigmoid(model(pos[sample_frames], plane_state[sample_frames]))[
            torch.arange(len(sample)), act_index[sample]
        ]
        result = mse(q, y).item()

    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("data_path")
    parser.add_argument("--epochs", type=int, default=1)
    parser.add_argument("--lr", type=float, default=1e-3)
    args = parser.parse_args()

    opts = Options(epochs=args.epochs, lr=args.lr)

    fly_data = torch.load(args.data_path, weights_only=False)
    train_data = prepare(fly_data, opts)
    val = run(opts, **train_data)

    logger.info(f"TD loss: {val}")
