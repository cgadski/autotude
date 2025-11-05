# %%
import alti_rl as arl
import matplotlib.pyplot as plt
from tqdm import tqdm
import torch as t


# %%
def get_trajectories(steps=1000):
    acts = t.zeros(steps, 7, dtype=t.int8)
    obs = t.zeros(steps, 3, dtype=t.int16)
    rewards = t.zeros(steps, dtype=t.int8)
    policy = arl.TurningPolicy()
    with arl.SoloChannelparkEnv() as env:
        for i in tqdm(range(steps)):
            act = policy.act()
            ob, reward = env.step(act)
            acts[i] = t.tensor(act)
            obs[i] = t.tensor(ob)
            rewards[i] = reward
    return acts, obs, rewards


# %%
acts, obs, rewards = get_trajectories(10 * 60 * 60 * 30)
t.save({"acts": acts, "obs": obs, "rewards": rewards}, "data/channelpark.pt")
