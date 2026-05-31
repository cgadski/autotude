import argparse

import torch
from tqdm import tqdm

import alti_rl as arl


def get_trajectories(steps=1000):
    mask = torch.zeros(steps, dtype=torch.bool)
    acts = torch.zeros(steps, 7, dtype=torch.int8)
    plane = torch.zeros(steps, 3, dtype=torch.int16)
    stalled = torch.zeros(steps, dtype=torch.bool)

    policy = arl.TurningPolicy()
    with arl.SoloEnv(map="ffa_cave") as env:
        for i in tqdm(range(steps)):
            act = policy.act()
            acts[i] = torch.tensor(act)

            ob = env.step(act)

            if ob.get("x"):
                mask[i] = 1
                plane[i, 0] = ob["x"]
                plane[i, 1] = ob["y"]
                plane[i, 2] = ob["angle"]

                if ob.get("stalled"):
                    stalled[i] = 1

    return {
        "mask": mask,
        "acts": acts,
        "plane": plane,
        "stalled": stalled,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--hours", type=int, default=1)
    parser.add_argument("--out", type=str, required=True)
    args = parser.parse_args()

    data = get_trajectories(30 * 60 * 60 * args.hours)
    torch.save(data, args.out)
