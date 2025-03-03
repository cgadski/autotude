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

# %%
import os
os.environ['PATH'] += ':/Users/christopher.gadzinsk/autotude/bin/'
os.environ['ALTI_HOME'] = '/Users/christopher.gadzinsk/autotude/alti_home/'

# %%
config = arl.ServerConfig()
config.set(map='ball_grotto')
config.add_bot(nick='player 1', team='6')
env = arl.BotServer(config)


# %%
env.__exit__()
