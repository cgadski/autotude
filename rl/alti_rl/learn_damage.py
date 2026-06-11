"""Train NavNet to predict damage value from plane observations."""

import argparse
import os

import torch
import torch.nn as nn
import vandc

from alti_rl.networks import NavNet, Options, action_index, encode_plane, exp_discount


def prepare(
    data: dict, opts: Options
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    mask, x = encode_plane(data["mask"], data["plane"])
    dv = exp_discount(data["damage"], gamma=opts.gamma)[mask]
    dmg_value = (dv - dv.mean()) / dv.std()
    act_index = action_index(data["acts"][mask])
    return x[mask], dmg_value, act_index


def run(
    opts: Options,
    plane: torch.Tensor,
    dmg_value: torch.Tensor,
    act_index: torch.Tensor,
) -> float:
    torch.manual_seed(opts.seed)
    model = NavNet(opts)
    optimizer = torch.optim.Adam(
        model.parameters(),
        lr=opts.lr,
        betas=(opts.beta1, opts.beta2),
    )
    mse = nn.MSELoss()
    N = len(plane)
    total_steps = opts.epochs * (N // opts.batch_size)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=total_steps, eta_min=opts.lr_min
    )

    vandc.init(opts)

    for _ in range(opts.epochs):
        perm = torch.randperm(N)
        for i in vandc.progress(range(0, N, opts.batch_size)):
            idx = perm[i : i + opts.batch_size]
            out = model(plane[idx])  # batch n_actions
            pred = out[torch.arange(len(idx)), act_index[idx].long()]
            loss = mse(pred, dmg_value[idx])
            loss.backward()
            optimizer.step()
            optimizer.zero_grad()
            scheduler.step()
            vandc.log({"loss": loss})

    path = f"./models/{vandc.run_name()}.pt"
    print(f"savin to to {path}")
    os.makedirs("./models", exist_ok=True)
    torch.save(model.state_dict(), path)

    vandc.close()

    sample = torch.randperm(N)[: N // 10]
    with torch.no_grad():
        out = model(plane[sample])
        pred = out[torch.arange(len(sample)), act_index[sample].long()]
        result = mse(pred, dmg_value[sample]).item()

    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("data_path")
    parser.add_argument("--epochs", type=int, default=10)
    args = parser.parse_args()

    opts = Options(
        epochs=args.epochs,
    )

    data = torch.load(args.data_path, weights_only=False)
    plane, dmg_value, act_index = prepare(data, opts)
    val = run(opts, plane, dmg_value, act_index)

    print(f"Value: {val}")
