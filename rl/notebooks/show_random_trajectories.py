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

# %%
# %load_ext autoreload
# %autoreload 2

# %%
import altitude_rl as arl
from tqdm import tqdm
import numpy as np
import matplotlib.pyplot as plt

# %% [markdown]
# # Random trajectories
#
# Let's just generate some trajectories from the `SoloChannelparkEnv` and display them.

# %%
SAMPLES = 30 * 60 * 30  # 30 minutes of gameplay
obs = np.zeros((SAMPLES, 3))
rewards = np.zeros((SAMPLES,))
policy = arl.TurningPolicy()

with arl.SoloChannelparkEnv() as env:
    for i in tqdm(range(SAMPLES)):
        action = policy.act()
        ob, reward, terminated, truncated, info = env.step(action)
        rewards[i] = reward
        obs[i] = ob

# %% [markdown]
# After 30 minutes of gameplay, we can see the outline of the map. Orange dots show where the plane received a penalty, meaning it took damage or crashed.

# %%
plt.scatter(obs[:, 0], obs[:, 1], s=1, alpha=0.2)
negative_reward = rewards < 0
plt.scatter(obs[negative_reward, 0], obs[negative_reward, 1], s=2)
plt.show()

# %%
