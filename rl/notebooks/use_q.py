from datetime import time
import torch.utils.data as D
import altitude_rl as arl
import torch as t
from tqdm import tqdm
import wandb
import argparse
import numpy as np
from pprint import pprint

velocity_frame_window = 1
with_memory = True
d = 128
model = t.nn.Sequential(
    arl.networks.ObsEncoder(velocity_frame_window=velocity_frame_window, d=d),
    t.nn.Linear(d, d),
    t.nn.ReLU(),
    t.nn.Linear(d, 1),
    t.nn.Flatten(start_dim=0),
)
model.load_state_dict(t.load("data/model.pt", weights_only=True))

print("loaded model")


def to_torch(x):
    return t.tensor(x).float()


def add_possible_actions(ob, possible_actions, with_memory=False):
    n_actions = len(possible_actions)
    memory_size = ob.shape[0]
    if with_memory:
        return t.concat(
            [
                ob.repeat(n_actions, 1).reshape(n_actions, memory_size, 3),
                possible_actions.reshape((n_actions, 1, 2)).repeat(1, memory_size, 1),
            ],
            dim=2,
        )

    else:
        return t.concat(
            [
                ob[None,:].repeat([n_actions, 1]),
                possible_actions,
            ],
            dim=-1,
        ).reshape(n_actions,1,5)


SAMPLES = 30 * 60 * 24
memory = None
memory_size = velocity_frame_window + 1
with arl.SoloChannelparkEnv() as env:
    ob, reward = env.step(np.zeros((7,)))  # (3, )
    if with_memory:
        ob = np.stack([ob] * memory_size)
        memory = ob
    ob = to_torch(ob)

    for i in tqdm(range(SAMPLES)):
        possible_actions = t.tensor(
            [
                [0, 1],
                [1, 0],
                [0, 0],
            ]
        )
        inputs = add_possible_actions(ob, possible_actions, with_memory)
        estimates=t.zeros(inputs.shape[0])
        for j,input in enumerate(inputs):
            estimates[j] = model(input)[-1]
        i = t.argmax(estimates).item()
        act = t.zeros((7,))
        act[:2] = possible_actions[i, :]

        ob, reward = env.step(act.numpy())
        if with_memory:
            memory = np.concatenate((memory[1:], [ob]))
            ob = memory
        ob = to_torch(ob)
