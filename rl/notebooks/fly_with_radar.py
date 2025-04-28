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

# %%
np.arange(0, 360, 2)

# %%
from altitude_rl.proto.game_object_pb2 import GameObject

def make_config():
    config = arl.ServerConfig()
    config.set(map="ffa_channelpark")
    config.set(clearDistances=True)
    config.add_bot(nick="controlled", team="3")
    return config

def wrap_180(angle):
    return (angle + 180) % 360 - 180

class PDRadarController:
    def __init__(self):
        self.last_angle = None
        self.cmd = arl.Cmd()

    def get_target(self, o:GameObject):
        current = o.angle / 10
        options = current + np.arange(0, 360, 2)
        clears = np.array(o.clear_distances)
        costs = 1 / (clears ** 2 + 0.1) + 1e-8 * np.abs(wrap_180(options - current))
        return options[np.argmin(costs)]
    
    def control(self, o:GameObject):
        if o is None:
            self.last_angle = None
            return self.cmd

        if self.last_angle is None:
            self.last_angle = o.angle / 10
            return self.cmd

        angle = o.angle / 10
        target_angle = self.get_target(o)
        prop = wrap_180(angle - target_angle)
        diff = angle - self.last_angle
        self.last_angle = angle

        pd_response = prop + 3 * diff
        TOL = 3
        controls = 0
        if pd_response > TOL:
            controls = 2
        elif pd_response < -TOL:
            controls = 1
        self.cmd.inputs[0].controls = controls + 4
            
        return self.cmd
        
N_STEPS = 60 * 60
pos = np.zeros((N_STEPS, 2))

with arl.BotServer(make_config()) as server:
    controller = PDRadarController()
    my_plane = None
    
    for i in range(N_STEPS):
        up = server.update(controller.control(my_plane))
        angle = 0
        for o in up.objects:
            if o.type < 5:
                my_plane = o
                pos[i, 0] = o.position_x
                pos[i, 1] = o.position_y

# %%
plt.scatter(pos[:, 0], pos[:, 1], s=1)
plt.show()
