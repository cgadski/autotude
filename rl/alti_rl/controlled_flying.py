import argparse

import torch
from tqdm import tqdm

import alti_rl as arl
from alti_rl.policies import NetPolicy


def get_trajectories(policy: NetPolicy, steps: int = 1000):
    mask = torch.zeros(steps, dtype=torch.bool)
    acts = torch.zeros(steps, 7, dtype=torch.int8)
    plane = torch.zeros(steps, 3, dtype=torch.int16)
    stalled = torch.zeros(steps, dtype=torch.bool)
    damage = torch.zeros(steps, dtype=torch.bool)

    with arl.SoloEnv(map="ffa_cave") as env:
        ob = {}
        for i in tqdm(range(steps)):
            act = policy.act(ob)
            acts[i] = torch.tensor(act)
            ob = env.step(act)

            if ob.get("damage"):
                damage[i] = 1
            if ob.get("x"):
                mask[i] = 1
                plane[i] = torch.tensor([ob["x"], ob["y"], ob["angle"]])
                if ob.get("stalled"):
                    stalled[i] = 1

    return {
        "mask": mask,
        "acts": acts,
        "plane": plane,
        "stalled": stalled,
        "damage": damage,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("model_path")
    parser.add_argument("--hours", type=float, default=1)
    parser.add_argument("--out", type=str, required=True)
    args = parser.parse_args()

    policy = NetPolicy(args.model_path)
    data = get_trajectories(policy, int(30 * 60 * 60 * args.hours))
    torch.save(data, args.out)
