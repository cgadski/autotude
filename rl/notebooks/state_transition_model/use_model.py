from datetime import time
import torch.utils.data as D
import altitude_rl as arl
import torch as t
from tqdm import tqdm
import wandb
import argparse
import numpy as np
from pprint import pprint
import matplotlib.pyplot as plt

window = 10


def make_model():
    if not True:
        d = 128
        return t.nn.Sequential(
            arl.networks.MultiObsEncoder(d=d, window=window),
            t.nn.Linear(d, d),
            t.nn.ReLU(),
            t.nn.Linear(d, 2),
        ).to(t.float32)
    else:
        return t.nn.Sequential(
            MyUnfold(args.window),  # (b, window * 2)
            t.nn.Linear(window * 2, 2),
        )


model = make_model()
model.load_state_dict(t.load("data/model.pt", weights_only=True))

print("loaded model")


def to_torch(x):
    return t.tensor(x).float()


def show(obs):
    plt.scatter(obs[:, 0], obs[:, 1], s=1)
    plt.xlim(0, 1)
    plt.ylim(0, 1)
    plt.savefig("data/model_use.png", dpi=300)


n_obs = 1000
obs = t.zeros((n_obs, 3))
policy = arl.TurningPolicy()
with arl.SoloChannelparkEnv() as env:
    for i in tqdm(range(50)):
        action = policy.act()
        ob, reward = env.step(action)
        obs[i] = to_torch(ob)
angles = 10 * obs[:, 2] * t.pi / 180
cosi = t.stack([t.cos(angles), t.sin(angles)], dim=1)
obs = t.cat((obs[:, :2], cosi, obs[:, 3:]), dim=1)
out = obs[window - 1][None, :]
input = t.zeros(window, 5)
for i in tqdm(range(n_obs - window)):
    obs[i + window - 1] = out[:]
    input[:, :2] = obs[i : i + window, :2]
    input[:, 2] = t.atan2(obs[i : i + window, 3], obs[i : i + window, 2]) * 18 / t.pi
    input[:, 3:] = t.zeros((window, 2))
    out = model(input)

show(obs[:, :2].detach().numpy())
