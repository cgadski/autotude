# %%
%load_ext autoreload
%autoreload 2


# %%
import altitude_rl as arl
import matplotlib.pyplot as plt
from tqdm import tqdm
import torch as t


# %%
def get_trajectories(steps=1000):
    acts = t.zeros(steps, 7)
    obs = t.zeros(steps, 3)
    policy = arl.TurningPolicy()
    with arl.SoloChannelparkEnv() as env:
        for i in tqdm(range(steps)):
            act = policy.act()
            ob, reward = env.step(act) # terminated, truncated, info
            acts[i] = t.tensor(act)
            obs[i] = t.tensor(ob)
    return acts, obs


# %%
acts, obs = get_trajectories(2000)

# %%
plt.scatter(obs[:, 0], obs[:, 1], s=1, c=acts[:, 0] != 0)


# %%
sieve = t.zeros(100)
sieve[0] = 1
sieve
