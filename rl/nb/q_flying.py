# %%
import matplotlib.pyplot as plt
import torch as t
from tqdm import tqdm

import alti_rl as arl


# %%
class ValueNetwork(t.nn.Module):
    """
    Given an observation, returns Q-value estimate for three possible moves: do nothing, turn left, turn right.
    """

    def __init__(self):
        super().__init__()

    def forward(self, x):
        return x


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


obs = get_trajectories(30 * 60 * 10)[1]


# %%
VEL_STD = 10


def encode_obs(obs):
    mask = t.ones(obs.shape[0]).to(t.bool)
    mask[0] = 0
    vel = (obs[1:, :2] - obs[:-1, :2]).to(t.float32)
    vel_norm = vel.norm(dim=1)
    mask[1:][vel_norm > 50] = 0
    vel = vel[vel_norm <= 50]  # d' 2
    vel = vel / VEL_STD

    theta = obs[:, 2] * 2 * t.pi / 3600
    heading = t.stack([t.cos(theta), t.sin(theta)], dim=1)

    return mask, t.concat(
        [
            vel,
            heading[mask],
        ],
        dim=1,
    )


mask, x = encode_obs(obs)
x
# vel = vel[vel.norm(dim=1) < 50]
# plt.plot(vel.norm(dim=1))
# vel.to(t.float32).norm(dim=1).max()
# obs.max(axis=0)
# encoded = encode_obs(obs)
# encoded
