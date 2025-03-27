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

d = 128
model = t.nn.Sequential(
    arl.networks.ObsEncoderWithEnemy(d=d),
    t.nn.Linear(d, d),
    t.nn.ReLU(),
    t.nn.Linear(d, 1),
    t.nn.Flatten(start_dim=0),
)
model.load_state_dict(t.load("data/model.pt", weights_only=True))

print("loaded model")


def to_torch(x):
    return t.tensor(x).float()

def show(obs):    
    
    plt.scatter(obs[:, 0], obs[:, 1], s=1,alpha=0.1)  
    plt.xlim(0, 1)  
    plt.ylim(0, 1) 
    plt.savefig("data/use.png", dpi=300)

    

SAMPLES = 30 * 60 * 5
obs = np.zeros((SAMPLES, 5))
with arl.SoloChannelparkEnv() as env:
    ob, reward = env.step(np.zeros((7,)))  # (3, )
    ob = to_torch(ob)

    for i in tqdm(range(SAMPLES)):
        obs[i] = ob
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
show(obs)