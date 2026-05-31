# %%
import matplotlib.pyplot as plt
import torch as t
import torch.nn as nn
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


acts, obs, rewards = get_trajectories(30 * 60 * 10)


# %%
VEL_STD = 10
POS_SCALE = 2000


def encode_obs(obs: t.Tensor):
    mask = t.ones(obs.shape[0]).to(t.bool)
    vel = t.zeros(obs.shape[0], 2)
    vel[1:] = (obs[1:, :2] - obs[:-1, :2]).to(t.float32)
    vel_norm = vel.norm(dim=1)
    vel = vel / VEL_STD

    theta = obs[:, 2] * 2 * t.pi / 3600
    heading = t.stack([t.cos(theta), t.sin(theta)], dim=1)
    position = obs[:, :2] / POS_SCALE

    mask[0] = 0  # don't have velocity
    mask[vel_norm > 50] = 0  # respawn jump
    mask[(obs[:, 0] <= 0) & (obs[:, 1] <= 0)] = 0  # off map

    return mask, t.concat(
        [vel, heading, position],
        dim=1,
    )


# %%
def q_errors(acts, obs, rewards, net, discount=0.99):
    mask, x = encode_obs(obs)
    x = x[mask]

    values = net(x)


mask, x = encode_obs(obs)
x = x[mask]
net = ValueNetwork()
pred = net(x[:k])


# %%
mask, x = encode_obs(obs)
k = 90
plt.scatter(x[:k, 4], x[:k, 5])
plt.colorbar()

# %%
t.where(rewards == -1)
