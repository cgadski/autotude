# %%
import matplotlib.pyplot as plt
import torch as t
from tqdm import tqdm

import alti_rl as arl


# %%
def get_trajectories(steps=1000):
    acts = t.zeros(steps, 7, dtype=t.int8)
    obs = t.zeros(steps, 3, dtype=t.int16)
    rewards = t.zeros(steps, dtype=t.int8)
    policy = arl.TurningPolicy()
    with arl.SoloEnv(map="ffa_cave") as env:
        for i in tqdm(range(steps)):
            act = policy.act()
            ob, reward = env.step(act)
            acts[i] = t.tensor(act)
            obs[i] = t.tensor(ob)
            rewards[i] = reward
    return acts, obs, rewards


# %%
acts, obs, rewards = get_trajectories(100)
obs.shape
# t.save({"acts": acts, "obs": obs, "rewards": rewards}, "data/channelpark.pt")

# %%
period = t.arange(0, 200)
plt.scatter(obs[period, 0], obs[period, 1], c=rewards[period])
