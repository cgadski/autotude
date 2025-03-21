# ---
# jupyter:
#   jupytext:
#     formats: py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.16.7
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# Let's generate a dataset of observations, actions, and rewards to go for a solo bot flying on ffa_channelpark.
#
# We'll generate 24 hours of gameplay, which takes about a minute and takes up about 30 megabytes when using half-precision (16 bit) floats. During that time, the bot crashes just over 9000 times. (Coincidentally, both the full replay file and our (obs, act, reward_to_go) dataset are about 30 M.)

# %%
# %load_ext autoreload
# %autoreload 2

# %%
import altitude_rl as arl
from tqdm import tqdm
import numpy as np
import matplotlib.pyplot as plt

# %%
SAMPLES = 30 * 60 * 60 * 24 # 24 hours
obs = np.zeros((SAMPLES, 3))
acts = np.zeros((SAMPLES, 7), dtype=np.int8)
rewards = np.zeros((SAMPLES,))
policy = arl.TurningPolicy()

with arl.SoloChannelparkEnv() as env:
    for i in tqdm(range(SAMPLES)):
        action = policy.act()
        ob, reward = env.step(action)
        rewards[i] = reward
        obs[i] = ob
        acts[i] = action


# %%
def get_to_go(rewards: np.ndarray, gamma: float = 0.9):
    res = rewards.copy()
    for i in range(100):
        res[:-1] = rewards[:-1] + gamma * res[1:]
    return res 

def show_to_go(obs, rewards, to_go, lim=1000, offset=0):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
    
    obs = obs[offset:offset + lim]
    rewards = rewards[offset:offset + lim]
    to_go = to_go[offset:offset + lim]
    
    scatter = ax1.scatter(obs[:, 0], obs[:, 1], s=1, c=to_go)
    plt.colorbar(scatter, ax=ax1)

    ax2.scatter(np.arange(lim)[rewards < 0], rewards[rewards < 0])
    ax2.plot(np.arange(lim), to_go)
    
    
    plt.tight_layout()
    plt.savefig("data/plot.png", dpi=300, bbox_inches="tight")

# %%
to_go = get_to_go(rewards, gamma=0.95)
show_to_go(obs, rewards, to_go, lim=30 * 60)

# %%
import torch as t
from torch.utils.data import TensorDataset, DataLoader, random_split

print(obs.shape, acts.shape, to_go.shape)

def to_torch(x):
    return t.tensor(x, dtype=t.float16)

dataset = TensorDataset(
    t.concat([
        to_torch(obs),
        to_torch(acts[:, :2])
    ], dim=-1),
    to_torch(to_go)
)

print([x.shape for x in next(iter(dataset))])

t.save(dataset, "data/ffa_channelpark.pt")
