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
# # 

# %%
# %load_ext autoreload
# %autoreload 2

# %%
import gymnasium as gym
import altitude_rl as arl
from tqdm import tqdm
import numpy as np
import matplotlib.pyplot as plt

# %%
import os
os.environ['PATH'] += ':/Users/christopher.gadzinsk/autotude/bin/'
os.environ['ALTI_HOME'] = '/Users/christopher.gadzinsk/autotude/alti_home/'

# %%
SAMPLES = 30 * 60 * 20
history = np.zeros((SAMPLES, 2, 3))
rewards = np.zeros((SAMPLES,))
turn_right = True
with arl.FreeForAllEnv(with_opponent=False) as env:
    for i in tqdm(range(SAMPLES)):
        action = np.zeros((7,))
        switch_dir = np.random.rand() < 3/30
        if switch_dir:
            turn_right = not turn_right
        if turn_right:
            action[1] = 1
        else:
            action[0] = 1
        obs, reward, terminated, truncated, info = env.step(action)
        rewards[i] = reward
        history[i] = obs

# %%
plt.scatter(history[:, 0, 0], history[:, 0, 1], alpha=0.1, s=1)
where_killed = rewards != 0
plt.scatter(history[where_killed, 0, 0], history[where_killed, 0, 1])
plt.show()

# %%
