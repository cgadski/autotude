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
SAMPLES = 30 * 60 * 120 # 2 hours of gameplay
history = np.zeros((SAMPLES, 2, 3))
with arl.FreeForAllEnv() as env:
    action = np.array([0, 1, 0, 0, 0, 0, 0])
    for i in tqdm(range(SAMPLES)):
        obs, reward, terminated, truncated, info = env.step(action)
        history[i] = obs

# %%
plt.scatter(history[:, 1, 0], history[:, 1, 1], alpha=0.1, s=1)
plt.scatter(history[:, 0, 0], history[:, 0, 1], alpha=0.1, s=1)
plt.show()
