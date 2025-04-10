import torch as t
import torch.functional as f
import numpy as np
from tqdm import tqdm


class PositionEncoder(t.nn.Module):
    def __init__(self, d=128, dtype=t.float):
        super().__init__()
        self.centers = t.nn.Parameter(t.rand((d, 2), dtype=dtype))
        self.radii = t.nn.Parameter(t.ones(d, dtype=dtype))

    def forward(self, x: t.Tensor):
        dist = ((self.centers[None, :, :] - x[:, None, :]) ** 2).sum(dim=-1)
        return t.exp(-10 * self.radii * dist)

class AngleEncoder(t.nn.Module):
    def __init__(self, d=128, dtype=t.float):
        super().__init__()
        self.angle_encoder = t.nn.Linear(2, d)

    def forward(self, orientation):

        angle = 2 * t.pi * orientation

        angle_vec = t.stack([t.cos(angle), t.sin(angle)], dim=-1)

        return self.angle_encoder(angle_vec)


class OrientationEncoder(t.nn.Module):
    """
    Learnable encoding of observations (x, y, angle, left, right).
    """

    def __init__(self, d=128):
        super().__init__()
        self.pos_encoder = PositionEncoder(d=d)
        self.angle_encoder = t.nn.Linear(2, d)

    def forward(self, orientation):

        pos = orientation[:, :2]
        angle = 2 * t.pi * orientation[:, 2]

        angle_vec = t.stack([t.cos(angle), t.sin(angle)], dim=-1)

        return self.pos_encoder(pos) + self.angle_encoder(angle_vec)


class VelocityEncoder(t.nn.Module):
    def __init__(self, window,d=128):
        super().__init__()
        self.velocity_encoder = t.nn.Linear(2, d)
        self.window = window

    def forward(self, obs):
        v = obs[self.window :, :2] - obs[: -self.window, :2]
        v = t.concat((t.zeros((self.window, 2)), v))
        return self.velocity_encoder(v)


class ObsEncoder(t.nn.Module):
    def __init__(self, window_size=None, d=128):
        super().__init__()
        self.orientation_encoder = OrientationEncoder(d=d)
        self.control_encoder = t.nn.Linear(2, d)
        if window_size is not None:
            self.velocity_encoder = VelocityEncoder(window_size, d=d)
        else:
            self.velocity_encoder = lambda obs: t.zeros(obs.size(0), d)

    def forward(self, obs):
        action = obs[:, 3:]
        return self.orientation_encoder(obs) + self.control_encoder(action) + self.velocity_encoder(obs)
    
class ObsEncoderWithEnemy(t.nn.Module):
    def __init__(self, d=128):
        super().__init__()
        self.obs_encoder = ObsEncoder(d=d)
        self.distToEnemy_encoder = t.nn.Linear(2, d)
    
    def forward(self, obs):
        agent_obs = t.concatenate((obs[:,:3],obs[:,5:]),axis=1)
        distToEnemy = obs[:,3:5]
        return (
            self.obs_encoder(agent_obs)
            + self.distToEnemy_encoder(distToEnemy)
        )
    
class MultiObsEncoder(t.nn.Module):
    """
    Learnable encoding of observations (x, y, angle, left, right).
    """

    def __init__(self, window_size, d=128):
        super().__init__()
        self.obs_encoder = ObsEncoder(d=int(d / window_size))
        self.n_obs = window_size

    def forward(self, obs):
        return t.cat(
            [
                self.orientation_encoder(obs[:, i * 3 : i * 3 + 3])
                for i in range(self.n_obs - 1)
            ],
            axis=1,
        )



class ValueNet(t.nn.Module):
    def __init__(self, d=128):
        super().__init__()
        self.pos_encoder = PositionEncoder(d=d)
        self.angle_encoder = t.nn.Linear(2, d)
        self.act_encoder = t.nn.Linear(7, d)
        self.net = t.nn.Sequential(
            t.nn.Linear(d, 2 * d),
            t.nn.ReLU(),
            t.nn.Linear(2 * d, d),
        )

    def forward(self, obs):
        # angle_encoded = self.angle_encoder(
        #     t.stack([
        #         t.cos(obs[:, -1]),
        #         t.sin(obs[:, -1])
        #     ], axis=-1)
        # )
        return self.net(
            # angle_encoded
            self.pos_encoder(obs[:, :2])
            # + self.act_encoder(acts)
        )

    def fit(self, obs, to_go, iters, lr=3e-3):
        optimizer = t.optim.Adam(self.parameters(), lr)
        self.ls = np.zeros(iters)

        for epoch in tqdm(range(iters)):
            pred = self(obs).flatten()
            loss = t.nn.functional.mse_loss(pred, to_go)
            self.ls[epoch] = loss

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
