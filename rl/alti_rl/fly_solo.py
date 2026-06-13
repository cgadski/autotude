import argparse

import torch
from loguru import logger
from tqdm import tqdm

import alti_rl
import alti_rl.networks as nets
from alti_rl.policies import NetPolicy, Policy, TurningPolicy

RESULTS = ["alive", "x", "y", "angle", "stalled", "throttle", "ammo", "damage"]


def init_data(steps: int) -> dict[str, torch.Tensor]:
    data = {}

    data["stalled"] = torch.zeros(steps, dtype=torch.bool)
    data["alive"] = torch.zeros(steps, dtype=torch.bool)
    data["damage"] = torch.zeros(steps, dtype=torch.bool)
    data["action"] = torch.zeros((steps, 7), dtype=torch.bool)

    for r in RESULTS:
        if data.get(r) is not None:
            continue
        data[r] = torch.zeros(steps, dtype=torch.int16)

    total_bytes = sum(
        tensor.element_size() * tensor.numel() for tensor in data.values()
    )
    logger.info(f"Initialized {round(total_bytes / (1024 * 1024), 2)} mb")

    return data


def get_trajectories(policy: Policy, steps: int):
    data = init_data(steps)

    with alti_rl.SoloEnv(map="ffa_cave") as env:
        ob = {}
        for i in tqdm(range(steps)):
            act = policy.act(ob)
            ob = env.step(act)

            data["action"][i] = torch.tensor(act)

            for r in RESULTS:
                if ob.get(r):
                    data[r][i] = ob[r]

    return data


def build_policy(args: argparse.Namespace) -> Policy:
    if args.value_net:
        return NetPolicy(args.value_net)
    else:
        return TurningPolicy()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--value_net", type=str)
    parser.add_argument("--hours", type=float, default=1)
    parser.add_argument("--out", type=str, required=False)
    args = parser.parse_args()
    policy = build_policy(args)

    logger.info(f"Running {args.hours} hours...")
    data = get_trajectories(policy, int(30 * 60 * 60 * args.hours))

    if args.out:
        logger.info(f"Saving to {args.out}")
        torch.save(data, args.out)
