from datetime import time
import torch.utils.data as D
import altitude_rl as arl
import torch as t
from tqdm import tqdm
import wandb
import argparse
import numpy as np
from pprint import pprint

d = 128
model = t.nn.Sequential(
    arl.networks.ObsEncoder(d=d),
    t.nn.Linear(d, d, dtype=t.float16),
    t.nn.ReLU(),
    t.nn.Linear(d, 1, dtype=t.float16),
    t.nn.Flatten(start_dim=0),
)
model.load_state_dict(t.load("data/model.pt", weights_only=True))

print("loaded model")


def to_torch(x):
    return t.tensor(x, dtype=t.float16)


SAMPLES = 30 * 60 * 5
with arl.SoloChannelparkEnv() as env:
    ob, reward = env.step(np.zeros((7,)))  # (3, )
    ob = to_torch(ob)

    for i in tqdm(range(SAMPLES)):
        possible_actions = t.tensor(
            [
                [0, 1],
                [1, 0],
                [0, 0],
            ]
        )
        inputs = t.concat(
            [
                ob[None, :].repeat([3, 1]),
                possible_actions,
            ],
            dim=-1,
        )
        estimates = model(inputs)

        i = t.argmax(estimates).item()
        act = t.zeros((7,))
        act[:2] = possible_actions[i, :]

        ob, reward = env.step(act.numpy())
        ob = to_torch(ob)
